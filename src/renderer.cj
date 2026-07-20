package sdl

import std.collection.{ArrayList, HashMap}
import sdl.text.{NativeTextColor, NativeTextException, NativeTextMetrics, NativeTextRenderer}

/*
 * Default supersampling factor. The whole frame is drawn into an offscreen target this many times
 * larger than the window in each axis, then linearly downscaled on present. That single step
 * anti-aliases every primitive — rounded corners, diagonal strokes, circles — on the GPU, with no
 * per-widget cost. 2x (4 samples per pixel) is the sweet spot for desktop UI, but it also makes every
 * frame pay for 4x the pixels; an application (or a benchmark isolating that cost) can lower it.
 */
private let DEFAULT_SUPERSAMPLE: Int32 = 2

/*
 * Cap on distinct cached rotated-text rasterizations. Rotated text is axis titles — a handful of
 * static strings per figure — so the cache stays tiny and clears wholesale when it fills rather
 * than paying for recency tracking.
 */
private let TEXT_TEXTURE_CACHE_CAP: Int64 = 64

/*
 * The drawing facade the UI renders through: filled and stroked geometry (built as cached triangle
 * meshes and batched to the GPU), text via SDL_ttf with per-size/style/face metrics caches, textures,
 * and a rectangular clip stack. All coordinates are logical pixels. `beginScene` / `endScene` /
 * `present` bracket a frame; with supersampling on, the scene draws into an offscreen target
 * `supersampleFactor()`x the window size and is downscaled once on present, anti-aliasing every
 * primitive in a single step (text is rasterized at full scale and drawn 1:1, so it stays sharp).
 * `headless()` yields a renderer with no SDL device — drawing is a no-op and text measurement falls
 * back to an estimate — which lets widget tests exercise layout and events without a window.
 */
public class Renderer {
    internal let ptr: CPointer<Unit>
    private let contentScale: Float32
    private var ssTarget: CPointer<Unit> = CPointer<Unit>()
    private var ssWidth: Int32 = 0
    private var ssHeight: Int32 = 0
    // Supersample factor per axis (1 = off). Fixed for the renderer's life.
    private let ssFactor: Int32
    private var ssEnabled: Bool
    // The live drawing scale (render coordinates -> target pixels), mirrored from every
    // SDL_SetRenderScale call. Geometry draws through the GPU scale; TEXT rasterizes at
    // this scale and draws 1:1 on the pixel grid instead (see `text`), because stretching
    // small glyph bitmaps through the render scale is what blurs it.
    private var scaleX: Float32 = 1.0
    private var scaleY: Float32 = 1.0
    private let geometry = GeometryBatch()
    private let textBackend: ?NativeTextRenderer
    private let clipStack = ArrayList<Rect>()
    // Counts text measurements since the last reset — a per-frame cost probe. Text measurement is a
    // per-frame choke point (each measure shapes the string and, with a real backend, calls
    // SDL_ttf), so benchmarks reset this at a frame boundary to see how many a tree performs.
    // `measureCount` is total requests; `computeCount` is cache misses (the actual SDL_ttf calls).
    private var measureCount: UInt64 = 0
    private var computeCount: UInt64 = 0
    // Counts text draws (each re-shapes the string via TTF_SetTextString and rasterizes it) since the
    // last reset — the other per-frame text choke point, separate from measurement.
    private var drawTextCount: UInt64 = 0
    private let metricsCache = TextMetricsCache(TEXT_METRICS_CAP_PER_SIZE)
    // One metrics cache per application font face (keyed by file path), created on first use, so a
    // named font's measurements never collide with the default font's cache. The default face uses
    // `metricsCache` directly and stays on the untouched hot path.
    private let namedMetricsCaches = HashMap<String, TextMetricsCache>()
    // White rasterizations of rotated-text strings, keyed by face/style/effective-size/text.
    // Colour is applied per draw as a texture colour mod, so one entry serves every colour.
    private let textTextureCache = HashMap<String, Texture>()

    internal init(ptr: CPointer<Unit>, contentScale!: Float32 = 1.0, supersample!: Int32 = DEFAULT_SUPERSAMPLE) {
        this.ptr = ptr
        this.contentScale = contentScale
        this.ssFactor = if (supersample < Int32(1)) {
            Int32(1)
        } else {
            supersample
        }
        this.ssEnabled = ptr.isNotNull() && this.ssFactor > Int32(1)
        this.textBackend = createTextBackend(ptr)
    }

    /**
     * A renderer backed by no SDL device. Drawing becomes a no-op, which makes it useful
     * for headless widget tests that exercise layout and event handling without a window.
     */
    public static func headless(): Renderer {
        Renderer(CPointer<Unit>())
    }

    /**
     * The SDL render backend actually chosen (for example "direct3d11", "direct3d12", "opengl",
     * "vulkan", or "software"). A hardware/software tell: "software" means every pixel is drawn on
     * the CPU, which dominates a supersampled frame. "headless" when there is no device.
     */
    public func driverName(): String {
        if (ptr.isNull()) {
            return "headless"
        }
        let name = unsafe { SDL_GetRendererName(ptr) }
        if (name.isNull()) {
            "unknown"
        } else {
            name.toString()
        }
    }

    /** The active supersample factor per axis (1 = off). */
    public func supersampleFactor(): Int32 {
        ssFactor
    }

    /**
     * Begins a frame. When supersampling is available the scene is redirected into a
     * high-resolution offscreen target sized to `logicalWidth`/`logicalHeight`; otherwise
     * it draws straight to the window. Either way the target is cleared to `clearColor`.
     */
    public func beginScene(logicalWidth: Float32, logicalHeight: Float32, clearColor: Color): Unit {
        // Balanced pushClip/popClip pairs leave the stack empty between frames. Clearing the
        // logical stack is not enough on its own: SDL clip state is persistent per render
        // target, so a leaked push would keep clipping the device too. Each path below also
        // resets the device clip once its target is established (see drawDirect / the
        // supersample branch), so one leaked push cannot clip every later frame.
        clipStack.clear()
        if (ptr.isNull()) {
            return
        }
        if (!ssEnabled) {
            drawDirect(clearColor)
            return
        }
        var outW: Int32 = 0
        var outH: Int32 = 0
        if (!unsafe { SDL_GetRenderOutputSize(ptr, inout outW, inout outH) } || outW <= 0 || outH <= 0) {
            ssEnabled = false
            drawDirect(clearColor)
            return
        }
        let targetWidth = outW * ssFactor
        let targetHeight = outH * ssFactor
        if (ssTarget.isNull() || targetWidth != ssWidth || targetHeight != ssHeight) {
            allocateTarget(targetWidth, targetHeight)
        }
        if (!ssEnabled) {
            drawDirect(clearColor)
            return
        }
        ensureSdl(unsafe { SDL_SetRenderTarget(ptr, ssTarget) }, "SDL_SetRenderTarget")
        let sx = Float32(targetWidth) / max(1.0, logicalWidth)
        let sy = Float32(targetHeight) / max(1.0, logicalHeight)
        ensureSdl(unsafe { SDL_SetRenderScale(ptr, sx, sy) }, "SDL_SetRenderScale")
        scaleX = sx
        scaleY = sy
        // The supersample target holds its own persistent clip; drop any leak before clearing,
        // or the clear itself (and everything before the first push) would stay clipped.
        resetClip()
        clear(clearColor)
    }

    /**
     * Ends a frame. With supersampling active this resolves the offscreen target back onto
     * the window with linear filtering (the actual anti-aliasing step); otherwise a no-op.
     */
    public func endScene(): Unit {
        if (ptr.isNull() || !ssEnabled || ssTarget.isNull()) {
            return
        }
        ensureSdl(unsafe { SDL_SetRenderTarget(ptr, CPointer<Unit>()) }, "SDL_SetRenderTarget")
        let _ = unsafe { SDL_SetRenderScale(ptr, 1.0, 1.0) }
        scaleX = 1.0
        scaleY = 1.0
        var outW: Int32 = 0
        var outH: Int32 = 0
        let _ = unsafe { SDL_GetRenderOutputSize(ptr, inout outW, inout outH) }
        var dst = SdlFRect()
        dst.x = 0.0
        dst.y = 0.0
        dst.w = Float32(outW)
        dst.h = Float32(outH)
        let _ = unsafe { SDL_RenderTexture(ptr, ssTarget, CPointer<SdlFRect>(), inout dst) }
    }

    private func drawDirect(clearColor: Color): Unit {
        let _ = unsafe { SDL_SetRenderScale(ptr, contentScale, contentScale) }
        scaleX = contentScale
        scaleY = contentScale
        // Direct mode draws on the window target, whose clip persists across frames too.
        resetClip()
        clear(clearColor)
    }

    /**
     * Releases resources the renderer owns beyond the SDL renderer itself — the
     * supersampling target and the geometry buffers. The owning window calls this on
     * close, just before destroying the SDL renderer; safe to call more than once.
     */
    internal func releaseResources(): Unit {
        if (ssTarget.isNotNull()) {
            unsafe { SDL_DestroyTexture(ssTarget) }
            ssTarget = CPointer<Unit>()
        }
        clearTextTextureCache()
        match (textBackend) {
            case Some(value) => value.close()
            case None => ()
        }
        geometry.dispose()
    }

    private func allocateTarget(width: Int32, height: Int32): Unit {
        if (ssTarget.isNotNull()) {
            unsafe { SDL_DestroyTexture(ssTarget) }
            ssTarget = CPointer<Unit>()
        }
        let tex = unsafe { SDL_CreateTexture(ptr, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, width, height) }
        if (tex.isNull()) {
            ssEnabled = false
            return
        }
        let _ = unsafe { SDL_SetTextureScaleMode(tex, SDL_SCALEMODE_LINEAR) }
        let _ = unsafe { SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_NONE) }
        ssTarget = tex
        ssWidth = width
        ssHeight = height
    }

    /**
     * Throws `CuiException` when SDL rejects the renderer draw color update.
     */
    public func setColor(color: Color): Unit {
        // A headless renderer (null ptr, used by widget unit tests) draws nothing rather than
        // throwing, so draw() can be exercised off-screen. The geometry paths already no-op this way.
        if (ptr.isNull()) {
            return
        }
        if (!unsafe { SDL_SetRenderDrawColor(ptr, color.r, color.g, color.b, color.a) }) {
            throw CuiException("SDL_SetRenderDrawColor failed: ${lastSdlError()}")
        }
    }

    /**
     * Throws `CuiException` when SDL cannot clear the current render target.
     */
    public func clear(color: Color): Unit {
        // Headless renderers no-op like every other draw entry point, so canvas or shell
        // code that clears explicitly stays testable off-screen.
        if (ptr.isNull()) {
            return
        }
        setColor(color)
        if (!unsafe { SDL_RenderClear(ptr) }) {
            throw CuiException("SDL_RenderClear failed: ${lastSdlError()}")
        }
    }

    public func present(): Unit {
        if (ptr.isNull()) {
            return // headless renderer: nothing to present
        }
        ensureSdl(unsafe { SDL_RenderPresent(ptr) }, "SDL_RenderPresent")
    }

    /**
     * Throws `CuiException` when the scale is invalid or SDL rejects the renderer scale.
     * Headless: the logical scale is still recorded, so text metrics stay consistent.
     */
    public func setScale(scale: Float32): Unit {
        if (scale <= 0.0) {
            throw CuiException("Renderer scale must be greater than 0.")
        }
        if (!ptr.isNull()) {
            ensureSdl(unsafe { SDL_SetRenderScale(ptr, scale, scale) }, "SDL_SetRenderScale")
        }
        scaleX = scale
        scaleY = scale
    }

    public func setVSync(vsync: Int32): Unit {
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe { SDL_SetRenderVSync(ptr, vsync) }, "SDL_SetRenderVSync")
    }

    public func vsync(): Int32 {
        if (ptr.isNull()) {
            return 0
        }
        var value: Int32 = 0
        ensureSdl(unsafe { SDL_GetRenderVSync(ptr, inout value) }, "SDL_GetRenderVSync")
        value
    }

    public func setViewport(rect: Rect): Unit {
        if (ptr.isNull()) {
            return
        }
        var raw = rect.toSdlRect()
        ensureSdl(unsafe { SDL_SetRenderViewport(ptr, inout raw) }, "SDL_SetRenderViewport")
    }

    public func resetViewport(): Unit {
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe { SDL_SetRenderViewport(ptr, CPointer<SdlRect>()) }, "SDL_SetRenderViewport")
    }

    public func viewport(): Rect {
        if (ptr.isNull()) {
            return Rect(0.0, 0.0, 0.0, 0.0)
        }
        var raw = SdlRect()
        ensureSdl(unsafe { SDL_GetRenderViewport(ptr, inout raw) }, "SDL_GetRenderViewport")
        rectFromSdl(raw)
    }

    /**
     * Narrows the active clip to the intersection of `rect` and the current clip, so nested
     * scrollports and fields clip within their ancestors. Pair every call with `popClip`.
     */
    public func pushClip(rect: Rect): Unit {
        let effective = match (currentClip()) {
            case Some(top) => top.intersection(rect)
            case None => rect
        }
        clipStack.add(effective)
        applyClip()
    }

    /** Restores the clip that was active before the matching `pushClip`. */
    public func popClip(): Unit {
        if (!clipStack.isEmpty()) {
            clipStack.remove(at: clipStack.size - 1)
        }
        applyClip()
    }

    /** The clip in effect right now, or `None` when drawing is unclipped. */
    public func currentClip(): ?Rect {
        if (clipStack.isEmpty()) {
            None
        } else {
            Some(clipStack[clipStack.size - 1])
        }
    }

    private func applyClip(): Unit {
        if (ptr.isNull()) {
            return
        }
        match (currentClip()) {
            case Some(rect) => setClip(rect)
            case None => resetClip()
        }
    }

    private func setClip(rect: Rect): Unit {
        var raw = rect.toSdlRect()
        ensureSdl(unsafe { SDL_SetRenderClipRect(ptr, inout raw) }, "SDL_SetRenderClipRect")
    }

    private func resetClip(): Unit {
        ensureSdl(unsafe { SDL_SetRenderClipRect(ptr, CPointer<SdlRect>()) }, "SDL_SetRenderClipRect")
    }

    // Headless, the logical clip stack still answers: the top entry (or a zero rect).
    public func clipRect(): Rect {
        if (ptr.isNull()) {
            return match (currentClip()) {
                case Some(rect) => rect
                case None => Rect(0.0, 0.0, 0.0, 0.0)
            }
        }
        var raw = SdlRect()
        ensureSdl(unsafe { SDL_GetRenderClipRect(ptr, inout raw) }, "SDL_GetRenderClipRect")
        rectFromSdl(raw)
    }

    public func clipEnabled(): Bool {
        if (ptr.isNull()) {
            return !clipStack.isEmpty()
        }
        unsafe { SDL_RenderClipEnabled(ptr) }
    }

    public func setColorScale(scale: Float32): Unit {
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe { SDL_SetRenderColorScale(ptr, scale) }, "SDL_SetRenderColorScale")
    }

    public func colorScale(): Float32 {
        if (ptr.isNull()) {
            return 1.0
        }
        var value: Float32 = 1.0
        ensureSdl(unsafe { SDL_GetRenderColorScale(ptr, inout value) }, "SDL_GetRenderColorScale")
        value
    }

    public func setColorFloat(r: Float32, g: Float32, b: Float32, a: Float32): Unit {
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe {
            SDL_SetRenderDrawColorFloat(ptr, clamp01(r), clamp01(g), clamp01(b), clamp01(a))
        }, "SDL_SetRenderDrawColorFloat")
    }

    public func point(x: Float32, y: Float32, color: Color): Unit {
        setColor(color)
        let _ = unsafe { SDL_RenderPoint(ptr, x, y) }
    }

    public func line(x1: Float32, y1: Float32, x2: Float32, y2: Float32, color: Color): Unit {
        setColor(color)
        let _ = unsafe { SDL_RenderLine(ptr, x1, y1, x2, y2) }
    }

    public func rect(rect: Rect, color: Color): Unit {
        setColor(color)
        var raw = rect.toSdlFRect()
        let _ = unsafe { SDL_RenderRect(ptr, inout raw) }
    }

    public func fill(rect: Rect, color: Color): Unit {
        setColor(color)
        var raw = rect.toSdlFRect()
        let _ = unsafe { SDL_RenderFillRect(ptr, inout raw) }
    }

    /**
     * A thick, round-capped line drawn as one anti-aliased stadium mesh, so strokes stay
     * smooth at any angle and consecutive polyline segments join without notches.
     */
    public func strokeLine(x1: Float32, y1: Float32, x2: Float32, y2: Float32, pen: Pen): Unit {
        geometry.strokeSegment(ptr, Point(x1, y1), Point(x2, y2), pen)
    }

    /**
     * A rectangle outline with lightly rounded joins, stroked as one anti-aliased ring.
     */
    public func strokeRect(rect: Rect, pen: Pen): Unit {
        strokeRoundedRect(rect, pen.width * 0.6, pen)
    }

    /**
     * A rounded-rectangle outline stroked as one anti-aliased ring centred on the path.
     */
    public func strokeRoundedRect(rect: Rect, radius: Float32, pen: Pen): Unit {
        geometry.strokeRoundedRect(ptr, rect, roundedRadius(rect, radius), pen)
    }

    /**
     * A dashed rounded-rectangle outline — `dash` px on, `gap` px off, marched evenly around the
     * perimeter. A non-positive dash or gap draws a solid stroke instead.
     */
    public func strokeRoundedRectDashed(rect: Rect, radius: Float32, pen: Pen, dash!: Float32, gap!: Float32): Unit {
        geometry.strokeRoundedRectDashed(ptr, rect, roundedRadius(rect, radius), pen, dash, gap)
    }

    public func fillRoundedRect(rect: Rect, radius: Float32, color: Color): Unit {
        let r = roundedRadius(rect, radius)
        if (r <= 0.5) {
            fill(rect, color)
            return
        }
        geometry.fillRoundedRect(ptr, rect, r, color)
    }

    /**
     * Fills a rounded rectangle with a linear gradient from `start` to `end` — vertical (top to bottom)
     * by default, or horizontal (left to right) when `vertical` is false. Reuses the same cached mesh a
     * solid fill would, so it costs no extra tessellation.
     */
    public func fillRoundedRectGradient(
        rect: Rect,
        radius: Float32,
        start: Color,
        end: Color,
        vertical!: Bool = true
    ): Unit {
        geometry.fillRoundedRectGradient(ptr, rect, roundedRadius(rect, radius), start, end, vertical)
    }

    /**
     * Fills a rectangle whose four corners take independent radii (top-left, top-right, bottom-right,
     * bottom-left) — for chat bubbles, top-rounded tabs and edge-docked sheets. Each radius is clamped to
     * half the short side. Tessellated per call, leaving the cached uniform-radius fill path untouched.
     */
    public func fillPerCornerRoundedRect(
        rect: Rect,
        color: Color,
        topLeft!: Float32,
        topRight!: Float32,
        bottomRight!: Float32,
        bottomLeft!: Float32
    ): Unit {
        geometry.fillPerCornerRoundedRect(ptr, rect, topLeft, topRight, bottomRight, bottomLeft, color)
    }

    /**
     * A rounded rectangle whose edge fades out across `feather` pixels — a single-pass
     * gradient halo, which is how soft drop shadows and focus glows are drawn banding-free.
     */
    public func fillRoundedRectSoft(rect: Rect, radius: Float32, color: Color, feather!: Float32): Unit {
        geometry.fillRoundedRectSoft(ptr, rect, roundedRadius(rect, radius), color, feather)
    }

    public func circle(cx: Float32, cy: Float32, radius: Float32, color: Color, segments!: Int64 = 0): Unit {
        geometry.strokeCircle(ptr, Point(cx, cy), radius, Pen(width: 1.0, color: color), segments)
    }

    /**
     * A circle outline drawn with the given pen. `segments` is a minimum tessellation
     * hint; arcs are always sampled finely enough to stay smooth for their radius.
     */
    public func strokeCircle(cx: Float32, cy: Float32, radius: Float32, pen: Pen, segments!: Int64 = 0): Unit {
        geometry.strokeCircle(ptr, Point(cx, cy), radius, pen, segments)
    }

    public func fillCircle(cx: Float32, cy: Float32, radius: Float32, color: Color): Unit {
        geometry.fillCircle(ptr, Point(cx, cy), radius, color)
    }

    /**
     * Fills a polygon given as its vertices, closed automatically and anti-aliased with the same
     * feathered edge as the built-in shape fills.
     *
     * The fill fans from the first vertex, so the outline must be convex or star-shaped about
     * `points[0]` — wedges, regular polygons, and radial traces all qualify by construction; a
     * general concave outline needs triangulating before it gets here. Fewer than three distinct
     * points draw nothing, and a headless renderer no-ops like every other draw call.
     */
    public func fillConvexPolygon(points: ArrayList<Point>, color: Color): Unit {
        geometry.fillConvexPolygon(ptr, points, color)
    }

    /**
     * Draws a textured triangle strip for skinned or deformable sprites: `points` holds
     * consecutive (left, right) vertex pairs along the strip in draw coordinates, and
     * `texPoints` holds matching texture coordinates in source-image pixels. `alphas`
     * optionally gives one opacity per vertex, letting overlapping parts cross-fade.
     * All provided lists need the same even size of at least four; invalid sizes draw
     * nothing.
     *
     * Throws `CuiException` when the texture is closed.
     */
    public func texturedStrip(
        texture: Texture,
        points: ArrayList<Point>,
        texPoints: ArrayList<Point>,
        alphas!: ?ArrayList<Float32> = None
    ): Unit {
        if (texture.isClosed()) {
            throw CuiException("Cannot render a closed texture.")
        }
        geometry.texturedStrip(ptr, texture.ptr, points, texPoints, alphas, texture.width, texture.height)
    }

    /**
     * Draws UTF-8 text with the platform UI font through SDL3_ttf.
     *
     * Text takes a dedicated path through the render scale: glyphs are rasterized by
     * FreeType at the EFFECTIVE pixel size (`pointSize` x the live scale) and drawn with
     * the GPU scale reset to 1:1 at snapped target-pixel positions. Rasterizing at the
     * logical size and letting the render scale stretch the small bitmaps — as geometry
     * does — resamples every glyph twice and is what made text visibly softer and fainter
     * than the vector primitives around it. Under supersampling, positions snap to
     * multiples of `SUPERSAMPLE` so the resolve lands glyph origins on whole physical
     * pixels.
     */
    public func text(
        text: String,
        x: Float32,
        y: Float32,
        color: Color,
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): Unit {
        drawTextCount += 1
        match (textBackend) {
            case Some(value) =>
                let native = NativeTextColor(color.r, color.g, color.b, color.a)
                let flags = style.ttfFlags()
                let facePath = resolveFacePath(font)
                if (scaleX == 1.0 && scaleY == 1.0) {
                    value.draw(text, snapPixel(x, 1.0), snapPixel(y, 1.0), pointSize, flags, facePath, native)
                    return
                }
                let step: Float32 = if (ssEnabled) {
                    Float32(ssFactor)
                } else {
                    1.0
                }
                let px = snapPixel(x * scaleX, step)
                let py = snapPixel(y * scaleY, step)
                let _ = unsafe { SDL_SetRenderScale(ptr, 1.0, 1.0) }
                applyClipForTextPass()
                value.draw(text, px, py, pointSize * scaleY, flags, facePath, native)
                let _ = unsafe { SDL_SetRenderScale(ptr, scaleX, scaleY) }
                applyClip()
            case None => ()
        }
    }

    /**
     * Measures UTF-8 text using the same font, point size, and style used for drawing.
     */
    public func textWidth(
        text: String,
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): Float32 {
        textMetrics(text, pointSize, style, resolveFacePath(font)).width
    }

    /**
     * Returns the standard line height for the requested point size and style.
     */
    public func textHeight(
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): Float32 {
        textMetrics("国Ag", pointSize, style, resolveFacePath(font)).height
    }

    /**
     * Draws UTF-8 text centered within a rectangle.
     */
    public func textCenter(
        text: String,
        rect: Rect,
        color: Color,
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): Unit {
        let metrics = textMetrics(text, pointSize, style, resolveFacePath(font))
        let tx = rect.centerX() - metrics.width / 2.0
        let ty = rect.centerY() - metrics.height / 2.0
        this.text(text, tx, ty, color, pointSize: pointSize, style: style, font: font)
    }

    /**
     * Draws UTF-8 text rotated by `angleDegrees` (clockwise; -90 reads bottom-to-top), centred on
     * `(centerX, centerY)` in logical coordinates.
     *
     * The straight-text path (`text`) draws through the SDL_ttf text engine, which rasterizes
     * glyphs directly onto the render target and cannot rotate them. This path instead rasterizes
     * the whole string once into a texture (TTF_RenderText_Blended) and draws it through the
     * rotating texture pipeline. Glyphs are rasterized at the EFFECTIVE pixel size (`pointSize`
     * times the live render scale), so under supersampling the texture maps 1:1 onto physical
     * pixels — as sharp as straight text, not an upscale.
     *
     * Rasterizations are cached across frames (keyed by text, size, style, face, and scale;
     * colour is applied per draw as a colour mod), so a static rotated label costs one
     * rasterization, not one per frame. Headless renderers and empty text no-op.
     */
    public func textRotated(
        text: String,
        centerX: Float32,
        centerY: Float32,
        angleDegrees: Float64,
        color: Color,
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): Unit {
        if (ptr.isNull() || text.isEmpty()) {
            return
        }
        let backend = match (textBackend) {
            case Some(value) => value
            case None => return
        }
        let texture = match (rotatedTextTexture(backend, text, pointSize, style, resolveFacePath(font))) {
            case Some(value) => value
            case None => return
        }
        // The cached texture is white glyphs on transparency; the draw colour rides in as a
        // colour mod, which the texture pipeline honours (unlike the geometry batch).
        texture.setColorMod(color)
        texture.setAlpha(Int64(color.a))
        let width = texture.width / scaleX
        let height = texture.height / scaleY
        // Snap the centre to a physical pixel so an axis-aligned (±90°) label lands on the grid
        // instead of being smeared across two columns by the linear filter.
        let cx = snapPixel(centerX * scaleX, 1.0) / scaleX
        let cy = snapPixel(centerY * scaleY, 1.0) / scaleY
        // The rotating draw itself lives in the texture extension (`textureRotated`); calling
        // SDL directly here keeps the class body independent of its own extensions, which the
        // compiler does not resolve from inside the declaration.
        var dst = Rect(cx - width / 2.0, cy - height / 2.0, width, height).toSdlFRect()
        ensureSdl(unsafe {
            SDL_RenderTextureRotated(ptr, texture.ptr, CPointer<SdlFRect>(), inout dst, angleDegrees,
                CPointer<SdlFPoint>(), 0)
        }, "SDL_RenderTextureRotated")
    }

    /*
     * The cached white rasterization of a string at the current render scale. The effective size
     * lives in the key, so the same label rasterized inside a supersampled scene and outside one
     * are distinct entries and each draws 1:1 on its own pixel grid.
     */
    private func rotatedTextTexture(
        backend: NativeTextRenderer,
        text: String,
        pointSize: Float32,
        style: FontStyle,
        facePath: String
    ): ?Texture {
        let effectiveSize = pointSize * scaleY
        let key = "${facePath}|${style.ttfFlags()}|${Int64(effectiveSize * 256.0)}|${text}"
        match (textTextureCache.get(key)) {
            case Some(cached) => return Some(cached)
            case None => ()
        }
        let surface = backend.renderSurface(text, effectiveSize, style.ttfFlags(), facePath)
        if (surface.isNull()) {
            return None
        }
        let raw = unsafe { SDL_CreateTextureFromSurface(ptr, surface) }
        unsafe { SDL_DestroySurface(surface) }
        if (raw.isNull()) {
            return None
        }
        let texture = Texture(raw)
        texture.setBlendMode(TextureBlendMode.Blend)
        // Wholesale clear on overflow: the population is a handful of axis titles, and clearing
        // it costs one re-rasterization each — cheaper than tracking recency ever gets.
        if (textTextureCache.size >= TEXT_TEXTURE_CACHE_CAP) {
            clearTextTextureCache()
        }
        textTextureCache[key] = texture
        Some(texture)
    }

    private func clearTextTextureCache(): Unit {
        for ((_, texture) in textTextureCache) {
            texture.close()
        }
        textTextureCache.clear()
    }

    /** Text measurements requested since the last reset — a per-frame text-cost probe. */
    public func textMeasureCount(): UInt64 {
        measureCount
    }

    /** Actual measurement computations (cache misses) since the last reset — SDL_ttf calls on a real backend. */
    public func textComputeCount(): UInt64 {
        computeCount
    }

    /** Text draws issued since the last reset — each rasterizes a (cached, already-shaped) string on a real backend. */
    public func textDrawCount(): UInt64 {
        drawTextCount
    }

    /**
     * Shaping operations (shaped-text cache misses) since the last reset — the real TTF_CreateText
     * calls on a display backend, 0 when headless. On a warm cache during a scroll this stays flat
     * while `textDrawCount` scales with frames, which is the shaped-text cache working.
     */
    public func textShapeCount(): UInt64 {
        match (textBackend) {
            case Some(value) => value.shapeCount()
            case None => 0
        }
    }

    /** Resets the text measurement, compute, draw, and shape counters; call at a frame boundary to sample one frame. */
    public func resetTextMeasureCount(): Unit {
        measureCount = 0
        computeCount = 0
        drawTextCount = 0
        match (textBackend) {
            case Some(value) => value.resetShapeCount()
            case None => ()
        }
    }

    // Resolves a font selector to a face path for the backend: `None` (the common case) and any
    // unregistered name both yield the empty path, which the backend reads as the system UI font;
    // a registered name yields its file path. Kept here so name→path lookup happens once per call.
    private func resolveFacePath(font: ?String): String {
        match (font) {
            case None => ""
            case Some(name) => match (Fonts.pathFor(name)) {
                case Some(path) => path
                case None => ""
            }
        }
    }

    // The metrics cache for a face path. The default face ("") keeps the original single cache on the
    // hot path; each application font gets its own cache created on first use, so a named font never
    // perturbs the default font's cache or key space.
    private func metricsCacheFor(facePath: String): TextMetricsCache {
        if (facePath.isEmpty()) {
            return metricsCache
        }
        match (namedMetricsCaches.get(facePath)) {
            case Some(cache) => cache
            case None =>
                let cache = TextMetricsCache(TEXT_METRICS_CAP_PER_SIZE)
                namedMetricsCaches[facePath] = cache
                cache
        }
    }

    private func textMetrics(text: String, pointSize: Float32, style: FontStyle, facePath: String): NativeTextMetrics {
        measureCount += 1
        let flags = style.ttfFlags()
        // Cache the unscaled path only — all layout-time measurement and unscaled draw. The scaled
        // text-pass path (scaleX/scaleY != 1) is rare and recomputed. The cache sits above the
        // backend/estimate split, so it serves both the real font backend (skipping SDL_ttf) and the
        // headless estimate, and `computeCount` tracks the misses in either mode.
        if (scaleX == 1.0 && scaleY == 1.0) {
            // Fold the style flags (0..15) into the low bits of the size key so bold and plain runs
            // of the same size are cached and measured apart rather than colliding. The face path
            // selects the cache, so named fonts are kept apart without lengthening the string key.
            let sizeKey = Int64(pointSize * Float32(256.0)) * 16 + Int64(flags)
            let cache = metricsCacheFor(facePath)
            match (cache.get(sizeKey, text)) {
                case Some(cached) => return cached
                case None => ()
            }
            computeCount += 1
            let computed = computeMetrics(text, pointSize, style, facePath)
            cache.put(sizeKey, text, computed)
            return computed
        }
        computeCount += 1
        match (textBackend) {
            case Some(value) =>
                // Measure the same scaled rasterization the text pass draws, mapped back to
                // logical units — carets, selection bands and ellipsis decisions computed
                // from these metrics then line up with the pixels actually painted.
                let scaled = value.measure(text, pointSize * scaleY, flags, facePath)
                NativeTextMetrics(scaled.width / scaleX, scaled.height / scaleY)
            case None => headlessMetrics(text, pointSize, style)
        }
    }

    // The uncached measurement: the real font backend, or a proportional estimate when headless.
    private func computeMetrics(text: String, pointSize: Float32, style: FontStyle, facePath: String): NativeTextMetrics {
        match (textBackend) {
            case Some(value) => value.measure(text, pointSize, style.ttfFlags(), facePath)
            case None => headlessMetrics(text, pointSize, style)
        }
    }

    // The proportional estimate used with no font backend, so layout and event tests run headless.
    // Bold widens the advance a touch (mirroring faux-bold), giving the style path a deterministic,
    // assertable width difference off-screen; underline/strikethrough leave metrics unchanged.
    private func headlessMetrics(text: String, pointSize: Float32, style: FontStyle): NativeTextMetrics {
        let boldFactor: Float32 = if (style.bold) {
            1.06
        } else {
            1.0
        }
        NativeTextMetrics(Float32(text.size) * pointSize * 0.55 * boldFactor, pointSize * 1.3)
    }

    // While the text pass draws with the GPU scale reset to 1:1, the active clip must be
    // re-expressed in target pixels: SDL clip rectangles live in the current scaled space.
    private func applyClipForTextPass(): Unit {
        match (currentClip()) {
            case Some(rect) => setClip(Rect(rect.x * scaleX, rect.y * scaleY, rect.w * scaleX, rect.h * scaleY))
            case None => ()
        }
    }

    /**
     * Reads back the current render target and writes it to a BMP file. Useful for
     * automated visual snapshots and documentation thumbnails. Headless it is a no-op —
     * there are no pixels to read.
     *
     * Throws `CuiException` when SDL cannot read the pixels or save the file.
     */
    public func captureBmp(path: String): Unit {
        if (ptr.isNull()) {
            return
        }
        let surface = unsafe { SDL_RenderReadPixels(ptr, CPointer<SdlRect>()) }
        if (surface.isNull()) {
            throw CuiException("SDL_RenderReadPixels failed: ${lastSdlError()}")
        }
        let cPath = unsafe { LibC.mallocCString(path) }
        try (pathResource = cPath.asResource()) {
            let saved = unsafe { SDL_SaveBMP(surface, pathResource.value) }
            unsafe { SDL_DestroySurface(surface) }
            if (!saved) {
                throw CuiException("SDL_SaveBMP failed: ${lastSdlError()}")
            }
        }
    }
}

private func rectFromSdl(raw: SdlRect): Rect {
    Rect(Float32(raw.x), Float32(raw.y), Float32(raw.w), Float32(raw.h))
}

/*
 * Rounds a target-pixel coordinate to the nearest multiple of `step` (1 = whole pixels;
 * the supersample factor = positions that resolve onto whole physical pixels). Glyphs
 * drawn between pixels get smeared across two columns by the linear filter, which reads
 * as blur — snapping is what keeps stems solid.
 */
private func snapPixel(value: Float32, step: Float32): Float32 {
    let units = value / step
    let snapped = if (units >= 0.0) {
        Float32(Int64(units + 0.5))
    } else {
        -Float32(Int64(-units + 0.5))
    }
    snapped * step
}

private func clamp01(value: Float32): Float32 {
    clampF32(value, 0.0, 1.0)
}

private func roundedRadius(rect: Rect, radius: Float32): Float32 {
    clampF32(radius, 0.0, min(rect.w, rect.h) / 2.0)
}

/**
 * Throws `CuiException` when the system-font backend cannot initialize.
 */
private func createTextBackend(renderer: CPointer<Unit>): ?NativeTextRenderer {
    if (renderer.isNull()) {
        return None
    }
    try {
        Some(NativeTextRenderer(renderer))
    } catch (error: NativeTextException) {
        throw CuiException("System UI font initialization failed: ${error.message}")
    }
}
