package sdl

import std.collection.{ArrayList, HashMap}
import sdl.text.{NativeFontFamily, NativeTextColor, NativeTextException, NativeTextMetrics, NativeTextRenderer,
    normalizeFontPointSize}

/* 0 selects a physical-density-aware factor; positive requests remain exact compatibility knobs. */
private let DEFAULT_SUPERSAMPLE_REQUEST: Int32 = 0

private func nextBatchCapacity(current: Int64, required: Int64): Int64 {
    var capacity = max(Int64(16), current)
    while (capacity < required) {
        capacity *= 2
    }
    capacity
}

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
    private let device: RenderDeviceToken
    private var contentScale: Float32
    private var ssTarget: CPointer<Unit> = CPointer<Unit>()
    private var ssWidth: Int32 = 0
    private var ssHeight: Int32 = 0
    private var ssInitialized = false
    // The request is stable; Auto may change the effective factor after a display-density move.
    private let supersampleRequest: Int32
    private let maxTextureSize: Int32
    private var ssFactor: Int32
    private var ssEnabled: Bool
    private var plannedTargetWidth: Int32 = 0
    private var plannedTargetHeight: Int32 = 0
    private var failedTargetWidth: Int32 = 0
    private var failedTargetHeight: Int32 = 0
    private var samplingStatus: RenderSamplingStatus
    // The live drawing scale (render coordinates -> target pixels), mirrored from every
    // SDL_SetRenderScale call. Geometry draws through the GPU scale; TEXT rasterizes at
    // this scale and draws 1:1 on the pixel grid instead (see `text`), because stretching
    // small glyph bitmaps through the render scale is what blurs it.
    private var scaleX: Float32 = 1.0
    private var scaleY: Float32 = 1.0
    private let geometry = GeometryBatch()
    private var imageGeometry: ?ImageGeometry = None
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
    private var metricsCacheClock: UInt64 = UInt64(0)
    // Color-preserving text rasters, keyed by face/style/effective-size/text/RGB.
    // Colour is applied per draw as a texture colour mod, so one entry serves every colour.
    private let textTextureCache = TextRasterCache()
    private var scopedFontFamily: ?String = None
    private let resolvedFontFamilies = HashMap<String, NativeFontFamily>()
    // A display-list recording is renderer-local and synchronous. Drawing entry points append value
    // commands while active; frame/device control APIs reject recording rather than mutate SDL.
    private var activeCommandRecorder: ?RenderCommandRecorder = None
    private var commandEpoch: UInt64 = UInt64(0)
    private var observedFontRevision: UInt64 = UInt64.Max
    // Host-side replay scratch grows geometrically and is reused across immutable display lists;
    // primitive batches therefore allocate neither Cangjie lists nor C arrays per frame.
    private var rectBatchScratch: CPointer<SdlFRect> = CPointer<SdlFRect>()
    private var rectBatchCapacity: Int64 = 0
    private var pointBatchScratch: CPointer<SdlFPoint> = CPointer<SdlFPoint>()
    private var pointBatchCapacity: Int64 = 0

    internal init(
        ptr: CPointer<Unit>,
        contentScale!: Float32 = 1.0,
        supersample!: Int32 = DEFAULT_SUPERSAMPLE_REQUEST
    ) {
        this.ptr = ptr
        this.device = RenderDeviceToken(native: ptr.isNotNull())
        this.contentScale = contentScale
        this.supersampleRequest = supersample
        this.maxTextureSize = rendererMaxTextureSize(ptr)
        this.ssFactor = resolveSupersampleFactor(supersample, contentScale)
        this.ssEnabled = ptr.isNotNull() && this.ssFactor > Int32(1)
        this.samplingStatus = if (this.ssFactor > Int32(1)) {
            RenderSamplingStatus.Supersampled
        } else {
            RenderSamplingStatus.Direct
        }
        this.textBackend = createTextBackend(ptr)
        refreshOutputSampling()
    }

    /**
     * A renderer backed by no SDL device. Drawing becomes a no-op, which makes it useful
     * for headless widget tests that exercise layout and event handling without a window.
     */
    public static func headless(): Renderer {
        Renderer(CPointer<Unit>())
    }

    /**
     * Records drawing operations as an immutable value-command buffer without submitting them.
     * Nested recordings are isolated and can be replayed into their parent recording; an unbalanced
     * clip stack and frame/device control inside `body` throw `IllegalStateException`. Mutable
     * point/alpha lists are copied before this call returns.
     */
    public func recordCommands(body: () -> Unit): RenderCommandBuffer {
        ensureRenderAccess("record render commands")
        synchronizeFontRegistry()
        let previous = activeCommandRecorder
        let recorder = RenderCommandRecorder(currentClipUnchecked())
        activeCommandRecorder = Some(recorder)
        try {
            body()
            synchronizeFontRegistry()
            recorder.finish(this, commandEpoch)
        } finally {
            activeCommandRecorder = previous
        }
    }

    internal func recordRenderCommand(command: RenderCommand): Bool {
        ensureRenderAccess("draw")
        match (activeCommandRecorder) {
            case Some(recorder) =>
                recorder.record(command)
                true
            case None => false
        }
    }

    internal func isRecordingCommands(): Bool {
        activeCommandRecorder.isSome()
    }

    internal func appendRecordedCommand(command: RenderCommand): Unit {
        match (activeCommandRecorder) {
            case Some(recorder) => recorder.append(command)
            case None => throw IllegalStateException("No active render command recording")
        }
    }

    internal func renderCommandEpoch(): UInt64 {
        synchronizeFontRegistry()
        commandEpoch
    }

    internal func renderDevice(): RenderDeviceToken {
        device
    }

    internal func ensureRenderAccess(operation: String): Unit {
        device.ensureAccess(operation)
    }

    // Reject illegal teardown before the window marks itself closed or destroys native objects.
    internal func ensureWindowCloseAllowed(): Unit {
        device.ensureOwner("close SdlWindow")
        rejectDuringCommandRecording("close SdlWindow")
    }

    internal func updateContentScale(scale: Float32): Unit {
        ensureRenderAccess("update Renderer content scale")
        let normalized = normalizedScale(scale)
        let contentScaleChanged = contentScale.toBits() != normalized.toBits()
        let nextPlan = currentOutputSamplingPlan(normalized)
        let supersampleChanged = installSamplingPlan(nextPlan)
        if (!contentScaleChanged && !supersampleChanged) {
            return
        }
        contentScale = normalized
        advanceCommandEpoch()
        clearTextTextureCache()
        if (ptr.isNotNull()) {
            ensureSdl(unsafe { SDL_SetRenderScale(ptr, normalized, normalized) }, "SDL_SetRenderScale")
        }
        scaleX = normalized
        scaleY = normalized
    }

    /* Re-evaluates Auto after a resize before allocating or multiplying native dimensions. */
    internal func updateOutputSampling(
        outputWidth: Int32,
        outputHeight: Int32,
        maxTextureSizeOverride!: Int32 = 0
    ): Unit {
        ensureRenderAccess("update Renderer output sampling")
        updateOutputSamplingUnchecked(outputWidth, outputHeight, maxTextureSizeOverride)
    }

    private func updateOutputSamplingUnchecked(
        outputWidth: Int32,
        outputHeight: Int32,
        maxTextureSizeOverride: Int32
    ): Unit {
        let limit = if (maxTextureSizeOverride > Int32(0)) {
            maxTextureSizeOverride
        } else {
            maxTextureSize
        }
        let plan = planSupersampleTarget(supersampleRequest, contentScale, outputWidth, outputHeight, limit)
        if (installSamplingPlan(plan)) {
            advanceCommandEpoch()
            clearTextTextureCache()
        }
    }

    internal func refreshOutputSampling(): Unit {
        ensureRenderAccess("refresh Renderer output sampling")
        if (ptr.isNull()) {
            return
        }
        var outputWidth: Int32 = 0
        var outputHeight: Int32 = 0
        if (!unsafe { SDL_GetRenderOutputSize(ptr, inout outputWidth, inout outputHeight) }) {
            updateOutputSamplingUnchecked(0, 0, 0)
            return
        }
        updateOutputSamplingUnchecked(outputWidth, outputHeight, 0)
    }

    private func currentOutputSamplingPlan(scale: Float32): SupersampleTargetPlan {
        if (ptr.isNull()) {
            return SupersampleTargetPlan(resolveSupersampleFactor(supersampleRequest, scale))
        }
        var outputWidth: Int32 = 0
        var outputHeight: Int32 = 0
        if (!unsafe { SDL_GetRenderOutputSize(ptr, inout outputWidth, inout outputHeight) }) {
            return planSupersampleTarget(supersampleRequest, scale, 0, 0, maxTextureSize)
        }
        planSupersampleTarget(supersampleRequest, scale, outputWidth, outputHeight, maxTextureSize)
    }

    private func installSamplingPlan(plan: SupersampleTargetPlan): Bool {
        let factorChanged = plan.factor != ssFactor
        let targetChanged = plan.targetWidth != plannedTargetWidth || plan.targetHeight != plannedTargetHeight
        if (factorChanged || targetChanged) {
            if (ssTarget.isNotNull()) {
                unsafe { SDL_DestroyTexture(ssTarget) }
                ssTarget = CPointer<Unit>()
            }
            ssWidth = 0
            ssHeight = 0
            ssInitialized = false
        }
        if (targetChanged && (plan.targetWidth != failedTargetWidth || plan.targetHeight != failedTargetHeight)) {
            failedTargetWidth = 0
            failedTargetHeight = 0
        }
        ssFactor = plan.factor
        plannedTargetWidth = plan.targetWidth
        plannedTargetHeight = plan.targetHeight
        let repeatedAllocationFailure = plan.targetWidth > Int32(0) && plan.targetWidth == failedTargetWidth &&
            plan.targetHeight == failedTargetHeight
        samplingStatus = if (repeatedAllocationFailure) {
            RenderSamplingStatus.TargetAllocationFailure
        } else if (plan.automaticBudgetLimited) {
            RenderSamplingStatus.AutomaticPixelBudget
        } else if (plan.textureSizeLimited) {
            RenderSamplingStatus.TextureSizeLimit
        } else if (plan.outputUnavailable) {
            RenderSamplingStatus.OutputUnavailable
        } else if (plan.factor > Int32(1)) {
            RenderSamplingStatus.Supersampled
        } else {
            RenderSamplingStatus.Direct
        }
        ssEnabled = ptr.isNotNull() && plan.factor > Int32(1) && !repeatedAllocationFailure
        factorChanged
    }

    internal func noteRenderReset(): Unit {
        ensureRenderAccess("handle Renderer reset")
        advanceCommandEpoch()
        // Reset invalidates texture contents, not their wrapper ownership. Release owned handles
        // before advancing the generation, including both glyph and whole-run text caches.
        clearTextTextureCache()
        if (let Some(backend) <- textBackend) {
            backend.invalidateGlyphAtlas()
        }
        if (ssTarget.isNotNull()) {
            unsafe { SDL_DestroyTexture(ssTarget) }
        }
        device.advanceGeneration()
        ssTarget = CPointer<Unit>()
        ssWidth = 0
        ssHeight = 0
        ssInitialized = false
        failedTargetWidth = 0
        failedTargetHeight = 0
        ssEnabled = ptr.isNotNull() && ssFactor > Int32(1)
    }

    internal func captureCommandClipStack(): Array<Rect> {
        clipStack.toArray()
    }

    internal func restoreCommandClipStack(saved: Array<Rect>): Unit {
        clipStack.clear()
        for (rect in saved) {
            clipStack.add(rect)
        }
        applyClip()
    }

    private func rejectDuringCommandRecording(operation: String): Unit {
        if (activeCommandRecorder.isSome()) {
            throw IllegalStateException("${operation} cannot run while recording render commands")
        }
    }

    private func advanceCommandEpoch(): Unit {
        commandEpoch = nextRenderCommandEpoch(commandEpoch)
    }

    /**
     * The SDL render backend actually chosen (for example "direct3d11", "direct3d12", "opengl",
     * "vulkan", or "software"). A hardware/software tell: "software" means every pixel is drawn on
     * the CPU, which dominates a supersampled frame. "headless" when there is no device.
     */
    public func driverName(): String {
        ensureRenderAccess("inspect Renderer driver")
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

    /** The selected factor after density/budget planning; allocation status is in `renderSamplingStats`. */
    public func supersampleFactor(): Int32 {
        ensureRenderAccess("inspect Renderer supersample factor")
        ssFactor
    }

    /** Current density/budget decision and planned RGBA8 target cost; performs no GPU query. */
    public func renderSamplingStats(): RenderSamplingStats {
        ensureRenderAccess("inspect Renderer sampling statistics")
        let estimatedBytes = if (plannedTargetWidth > Int32(0) && plannedTargetHeight > Int32(0)) {
            UInt64(plannedTargetWidth) * UInt64(plannedTargetHeight) * UInt64(4)
        } else {
            UInt64(0)
        }
        RenderSamplingStats(
            supersampleRequest,
            ssFactor,
            plannedTargetWidth,
            plannedTargetHeight,
            estimatedBytes,
            maxTextureSize,
            samplingStatus
        )
    }

    /**
     * Begins a frame. When supersampling is available the scene is redirected into a
     * high-resolution offscreen target sized to `logicalWidth`/`logicalHeight`; otherwise
     * it draws straight to the window. Either way the target is cleared to `clearColor`.
     */
    public func beginScene(logicalWidth: Float32, logicalHeight: Float32, clearColor: Color): Unit {
        ensureRenderAccess("begin scene")
        rejectDuringCommandRecording("beginScene")
        // Balanced pushClip/popClip pairs leave the stack empty between frames. Clearing the
        // logical stack is not enough on its own: SDL clip state is persistent per render
        // target, so a leaked push would keep clipping the device too. Each path below also
        // resets the device clip once its target is established (see drawDirect / the
        // supersample branch), so one leaked push cannot clip every later frame.
        clipStack.clear()
        if (ptr.isNull()) {
            return
        }
        var outW: Int32 = 0
        var outH: Int32 = 0
        if (!unsafe { SDL_GetRenderOutputSize(ptr, inout outW, inout outH) } || outW <= 0 || outH <= 0) {
            updateOutputSamplingUnchecked(0, 0, 0)
            drawDirect(clearColor)
            return
        }
        updateOutputSamplingUnchecked(outW, outH, 0)
        if (!ssEnabled) {
            drawDirect(clearColor)
            return
        }
        let targetWidth = plannedTargetWidth
        let targetHeight = plannedTargetHeight
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
        clearTarget(clearColor)
        ssInitialized = true
    }

    /**
     * Begins a partial scene update on an already-initialized supersample target. The damaged
     * rectangle is cleared and remains clipped for subsequent draws; pixels outside it are
     * preserved. Returns false after safely falling back to a full clear when no persistent target
     * exists, its size changed, or this renderer has no offscreen target. Headless returns true.
     */
    public func beginSceneDamage(
        logicalWidth: Float32,
        logicalHeight: Float32,
        clearColor: Color,
        damage: Rect
    ): Bool {
        ensureRenderAccess("begin damaged scene")
        rejectDuringCommandRecording("beginSceneDamage")
        clipStack.clear()
        let clipped = damage.intersection(Rect(0.0, 0.0, logicalWidth, logicalHeight))
        if (clipped.w <= 0.0 || clipped.h <= 0.0) {
            beginScene(logicalWidth, logicalHeight, clearColor)
            return false
        }
        if (ptr.isNull()) {
            return true
        }
        if (!prepareDamageTarget(logicalWidth, logicalHeight, clearColor)) {
            return false
        }
        // SDL scissors use integer logical coordinates. Clear the complete scissor, and expose
        // that same conservative extent to scene culling and the physical-pixel text pass.
        match (alignedDamageClip(clipped, scaleX, scaleY)) {
            case Some(region) =>
                pushClip(region)
                fill(region, clearColor)
                true
            case None =>
                beginScene(logicalWidth, logicalHeight, clearColor)
                false
        }
    }

    private func prepareDamageTarget(logicalWidth: Float32, logicalHeight: Float32, clearColor: Color): Bool {
        var outW: Int32 = 0
        var outH: Int32 = 0
        if (!unsafe { SDL_GetRenderOutputSize(ptr, inout outW, inout outH) } || outW <= 0 || outH <= 0) {
            updateOutputSamplingUnchecked(0, 0, 0)
            drawDirect(clearColor)
            return false
        }
        updateOutputSamplingUnchecked(outW, outH, 0)
        if (!ssEnabled) {
            drawDirect(clearColor)
            return false
        }
        let targetWidth = plannedTargetWidth
        let targetHeight = plannedTargetHeight
        let targetMatches = ssTarget.isNotNull() && targetWidth == ssWidth && targetHeight == ssHeight
        let canPreserve = targetMatches && ssInitialized
        if (!targetMatches) {
            allocateTarget(targetWidth, targetHeight)
        }
        if (!ssEnabled || ssTarget.isNull()) {
            drawDirect(clearColor)
            return false
        }
        ensureSdl(unsafe { SDL_SetRenderTarget(ptr, ssTarget) }, "SDL_SetRenderTarget")
        let sx = Float32(targetWidth) / max(1.0, logicalWidth)
        let sy = Float32(targetHeight) / max(1.0, logicalHeight)
        ensureSdl(unsafe { SDL_SetRenderScale(ptr, sx, sy) }, "SDL_SetRenderScale")
        scaleX = sx
        scaleY = sy
        resetClip()
        if (!canPreserve) {
            clearTarget(clearColor)
            ssInitialized = true
            return false
        }
        true
    }

    /**
     * Ends a frame. With supersampling active this resolves the offscreen target back onto
     * the window with linear filtering (the actual anti-aliasing step). Direct rendering restores
     * logical scale 1 so measurement between scenes stays cacheable.
     */
    public func endScene(): Unit {
        ensureRenderAccess("end scene")
        rejectDuringCommandRecording("endScene")
        if (ptr.isNull()) {
            return
        }
        if (!ssEnabled || ssTarget.isNull()) {
            // Direct rendering leaves the device at contentScale. Layout happens between scenes and
            // must observe logical scale 1, otherwise textMetrics treats every measurement as a
            // scaled draw-time query and bypasses its cross-frame cache.
            ensureSdl(unsafe { SDL_SetRenderScale(ptr, 1.0, 1.0) }, "SDL_SetRenderScale")
            scaleX = 1.0
            scaleY = 1.0
            return
        }
        ensureSdl(unsafe { SDL_SetRenderTarget(ptr, CPointer<Unit>()) }, "SDL_SetRenderTarget")
        ensureSdl(unsafe { SDL_SetRenderScale(ptr, 1.0, 1.0) }, "SDL_SetRenderScale")
        scaleX = 1.0
        scaleY = 1.0
        resetClip()
        var outW: Int32 = 0
        var outH: Int32 = 0
        ensureSdl(unsafe { SDL_GetRenderOutputSize(ptr, inout outW, inout outH) }, "SDL_GetRenderOutputSize")
        var dst = SdlFRect()
        dst.x = 0.0
        dst.y = 0.0
        dst.w = Float32(outW)
        dst.h = Float32(outH)
        ensureSdl(unsafe { SDL_RenderTexture(ptr, ssTarget, CPointer<SdlFRect>(), inout dst) }, "SDL_RenderTexture")
    }

    private func drawDirect(clearColor: Color): Unit {
        ensureSdl(unsafe { SDL_SetRenderScale(ptr, contentScale, contentScale) }, "SDL_SetRenderScale")
        scaleX = contentScale
        scaleY = contentScale
        // Direct mode draws on the window target, whose clip persists across frames too.
        resetClip()
        clearTarget(clearColor)
    }

    /**
     * Releases resources the renderer owns beyond the SDL renderer itself — the
     * supersampling target and the geometry buffers. The owning window calls this on
     * close, just before destroying the SDL renderer; safe to call more than once.
     */
    internal func releaseResources(): Unit {
        device.ensureOwner("release Renderer resources")
        if (!device.isActive()) {
            return
        }
        rejectDuringCommandRecording("releaseResources")
        try {
            advanceCommandEpoch()
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
            if (let Some(painter) <- imageGeometry) {
                painter.close()
            }
            imageGeometry = None
            releasePrimitiveBatchScratch()
        } finally {
            device.invalidate()
        }
    }

    private func allocateTarget(width: Int32, height: Int32): Unit {
        ssInitialized = false
        if (ssTarget.isNotNull()) {
            unsafe { SDL_DestroyTexture(ssTarget) }
            ssTarget = CPointer<Unit>()
        }
        let tex = unsafe { SDL_CreateTexture(ptr, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, width, height) }
        if (tex.isNull()) {
            ssEnabled = false
            failedTargetWidth = width
            failedTargetHeight = height
            samplingStatus = RenderSamplingStatus.TargetAllocationFailure
            return
        }
        let _ = unsafe { SDL_SetTextureScaleMode(tex, SDL_SCALEMODE_LINEAR) } // cjcheck-ignore: ignore-result # cosmetic filter preference; the texture works with the default mode
        let _ = unsafe { SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_NONE) } // cjcheck-ignore: ignore-result # cosmetic blend preference; the texture works with the default mode
        ssTarget = tex
        ssWidth = width
        ssHeight = height
        failedTargetWidth = 0
        failedTargetHeight = 0
        samplingStatus = RenderSamplingStatus.Supersampled
    }

    /**
     * Throws `SdlException` when SDL rejects the renderer draw color update.
     */
    public func setColor(color: Color): Unit {
        ensureRenderAccess("set Renderer draw color")
        rejectDuringCommandRecording("setColor")
        applyDrawColor(color)
    }

    private func applyDrawColor(color: Color): Unit {
        // A headless renderer (null ptr, used by widget unit tests) draws nothing rather than
        // throwing, so draw() can be exercised off-screen. The geometry paths already no-op this way.
        if (ptr.isNull()) {
            return
        }
        if (!unsafe { SDL_SetRenderDrawColor(ptr, color.r, color.g, color.b, color.a) }) {
            throw SdlException("SDL_SetRenderDrawColor failed: ${lastSdlError()}")
        }
    }

    /**
     * Throws `SdlException` when SDL cannot clear the current render target.
     */
    public func clear(color: Color): Unit {
        ensureRenderAccess("clear Renderer target")
        rejectDuringCommandRecording("clear")
        clearTarget(color)
    }

    private func clearTarget(color: Color): Unit {
        // Headless renderers no-op like every other draw entry point, so canvas or shell
        // code that clears explicitly stays testable off-screen.
        if (ptr.isNull()) {
            return
        }
        applyDrawColor(color)
        if (!unsafe { SDL_RenderClear(ptr) }) {
            throw SdlException("SDL_RenderClear failed: ${lastSdlError()}")
        }
    }

    /**
     * Presents the finished frame to the window (SDL_RenderPresent); call after `endScene`.
     *
     * Throws `SdlException` when SDL cannot present the frame.
     */
    public func present(): Unit {
        ensureRenderAccess("present Renderer frame")
        rejectDuringCommandRecording("present")
        if (ptr.isNull()) {
            return // headless renderer: nothing to present
        }
        ensureSdl(unsafe { SDL_RenderPresent(ptr) }, "SDL_RenderPresent")
    }

    /**
     * Copies an on-screen logical rectangle from the current render target into a GPU texture.
     * Returns `None` for headless renderers, empty/out-of-bounds rectangles, or a backend readback
     * failure. This is intended for explicit opaque retained-paint caches; routine screenshots
     * should keep using `captureBmp` to avoid a GPU readback in the frame loop.
     */
    public func snapshotTexture(rect: Rect): ?Texture {
        ensureRenderAccess("snapshot Renderer target")
        rejectDuringCommandRecording("snapshotTexture")
        if (ptr.isNull() || rect.w <= 0.0 || rect.h <= 0.0) {
            return None
        }
        var outW: Int32 = 0
        var outH: Int32 = 0
        if (!unsafe { SDL_GetCurrentRenderOutputSize(ptr, inout outW, inout outH) }) {
            return None
        }
        let x = Int32(rect.x * scaleX)
        let y = Int32(rect.y * scaleY)
        let right = Int32(rect.right() * scaleX + 0.999)
        let bottom = Int32(rect.bottom() * scaleY + 0.999)
        if (x < 0 || y < 0 || right > outW || bottom > outH || right <= x || bottom <= y) {
            return None
        }
        var rawRect = SdlRect()
        rawRect.x = x
        rawRect.y = y
        rawRect.w = right - x
        rawRect.h = bottom - y
        let surface = unsafe { SDL_RenderReadPixels(ptr, inout rawRect) }
        if (surface.isNull()) {
            return None
        }
        let rawTexture = unsafe { SDL_CreateTextureFromSurface(ptr, surface) }
        unsafe { SDL_DestroySurface(surface) }
        if (rawTexture.isNull()) {
            return None
        }
        try {
            let texture = Texture(rawTexture, device)
            try {
                texture.setBlendMode(TextureBlendMode.None)
                Some(texture)
            } catch (_: SdlException) {
                // Paint caching is optional. A backend that cannot apply the required opaque blend
                // mode falls back to normal drawing, but the newly created GPU handle must not leak.
                texture.close()
                None
            }
        } catch (_: SdlException) {
            // Texture construction owns and frees rawTexture on metadata-query failure.
            None
        }
    }

    /**
     * Throws `SdlException` when the scale is invalid or SDL rejects the renderer scale.
     * Headless: the logical scale is still recorded, so text metrics stay consistent.
     */
    public func setScale(scale: Float32): Unit {
        ensureRenderAccess("set Renderer scale")
        rejectDuringCommandRecording("setScale")
        if (scale <= 0.0) {
            throw SdlException("Renderer scale must be greater than 0.")
        }
        if (!ptr.isNull()) {
            ensureSdl(unsafe { SDL_SetRenderScale(ptr, scale, scale) }, "SDL_SetRenderScale")
        }
        scaleX = scale
        scaleY = scale
        advanceCommandEpoch()
    }

    /**
     * Sets the renderer's vsync mode (SDL_SetRenderVSync): 0 disables, 1 syncs every refresh,
     * -1 requests adaptive vsync. Throws `SdlException` when SDL rejects the mode.
     */
    public func setVSync(vsync: Int32): Unit {
        ensureRenderAccess("set Renderer vsync")
        rejectDuringCommandRecording("setVSync")
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe { SDL_SetRenderVSync(ptr, vsync) }, "SDL_SetRenderVSync")
    }

    /**
     * The renderer's current vsync mode (SDL_GetRenderVSync); 0 when headless.
     * Throws `SdlException` when SDL cannot report the mode.
     */
    public func vsync(): Int32 {
        ensureRenderAccess("inspect Renderer vsync")
        if (ptr.isNull()) {
            return 0
        }
        var value: Int32 = 0
        ensureSdl(unsafe { SDL_GetRenderVSync(ptr, inout value) }, "SDL_GetRenderVSync")
        value
    }

    /**
     * Restricts drawing to `rect` and moves the coordinate origin to its top-left corner
     * (SDL_SetRenderViewport). Throws `SdlException` when SDL rejects the viewport.
     */
    public func setViewport(rect: Rect): Unit {
        ensureRenderAccess("set Renderer viewport")
        rejectDuringCommandRecording("setViewport")
        if (ptr.isNull()) {
            return
        }
        var raw = rect.toSdlRect()
        ensureSdl(unsafe { SDL_SetRenderViewport(ptr, inout raw) }, "SDL_SetRenderViewport")
        advanceCommandEpoch()
    }

    /**
     * Restores the viewport to the entire render target (SDL_SetRenderViewport with null).
     * Throws `SdlException` when SDL cannot reset the viewport.
     */
    public func resetViewport(): Unit {
        ensureRenderAccess("reset Renderer viewport")
        rejectDuringCommandRecording("resetViewport")
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe { SDL_SetRenderViewport(ptr, CPointer<SdlRect>()) }, "SDL_SetRenderViewport")
        advanceCommandEpoch()
    }

    /**
     * The current viewport rectangle (SDL_GetRenderViewport); a zero rect when headless.
     * Throws `SdlException` when SDL cannot report the viewport.
     */
    public func viewport(): Rect {
        ensureRenderAccess("inspect Renderer viewport")
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
        ensureRenderAccess("push Renderer clip")
        match (activeCommandRecorder) {
            case Some(recorder) =>
                recorder.pushClip(rect)
                return
            case None => ()
        }
        let effective = match (currentClipUnchecked()) {
            case Some(top) => top.intersection(rect)
            case None => rect
        }
        if (ptr.isNotNull()) {
            setClip(effective)
        }
        clipStack.add(effective)
    }

    /** Restores the clip that was active before the matching `pushClip`. */
    public func popClip(): Unit {
        ensureRenderAccess("pop Renderer clip")
        match (activeCommandRecorder) {
            case Some(recorder) =>
                recorder.popClip()
                return
            case None => ()
        }
        if (ptr.isNotNull()) {
            if (clipStack.size > 1) {
                setClip(clipStack[clipStack.size - 2])
            } else {
                resetClip()
            }
        }
        if (!clipStack.isEmpty()) {
            clipStack.remove(at: clipStack.size - 1)
        }
    }

    /** The clip in effect right now, or `None` when drawing is unclipped. */
    public func currentClip(): ?Rect {
        ensureRenderAccess("inspect Renderer clip")
        currentClipUnchecked()
    }

    private func currentClipUnchecked(): ?Rect {
        match (activeCommandRecorder) {
            case Some(recorder) => return recorder.currentClip()
            case None => ()
        }
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
        match (currentClipUnchecked()) {
            case Some(rect) => setClip(rect)
            case None => resetClip()
        }
    }

    private func setClip(rect: Rect): Unit {
        var raw = enclosingSdlClipRect(rect)
        ensureSdl(unsafe { SDL_SetRenderClipRect(ptr, inout raw) }, "SDL_SetRenderClipRect")
    }

    private func resetClip(): Unit {
        ensureSdl(unsafe { SDL_SetRenderClipRect(ptr, CPointer<SdlRect>()) }, "SDL_SetRenderClipRect")
    }

    /**
     * The device clip rectangle SDL reports (SDL_GetRenderClipRect); headless, the top of the
     * logical clip stack or a zero rect. Throws `SdlException` when SDL cannot report the clip.
     */
    // Headless, the logical clip stack still answers: the top entry (or a zero rect).
    public func clipRect(): Rect {
        ensureRenderAccess("inspect Renderer clip rectangle")
        if (ptr.isNull()) {
            return match (currentClipUnchecked()) {
                case Some(rect) => rect
                case None => Rect(0.0, 0.0, 0.0, 0.0)
            }
        }
        var raw = SdlRect()
        ensureSdl(unsafe { SDL_GetRenderClipRect(ptr, inout raw) }, "SDL_GetRenderClipRect")
        rectFromSdl(raw)
    }

    /** Whether a clip rectangle is currently active (SDL_RenderClipEnabled; headless, a non-empty clip stack). */
    public func clipEnabled(): Bool {
        ensureRenderAccess("inspect Renderer clip state")
        if (ptr.isNull()) {
            return !clipStack.isEmpty()
        }
        unsafe { SDL_RenderClipEnabled(ptr) }
    }

    /**
     * Sets the color scale applied to all subsequent draws (SDL_SetRenderColorScale) — values
     * above 1.0 brighten, below dim. Throws `SdlException` when SDL rejects the scale.
     */
    public func setColorScale(scale: Float32): Unit {
        ensureRenderAccess("set Renderer color scale")
        rejectDuringCommandRecording("setColorScale")
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe { SDL_SetRenderColorScale(ptr, scale) }, "SDL_SetRenderColorScale")
    }

    /**
     * The current renderer color scale (SDL_GetRenderColorScale); 1.0 when headless.
     * Throws `SdlException` when SDL cannot report the scale.
     */
    public func colorScale(): Float32 {
        ensureRenderAccess("inspect Renderer color scale")
        if (ptr.isNull()) {
            return 1.0
        }
        var value: Float32 = 1.0
        ensureSdl(unsafe { SDL_GetRenderColorScale(ptr, inout value) }, "SDL_GetRenderColorScale")
        value
    }

    /**
     * Sets the draw color from floating-point channels, each clamped to `[0, 1]`
     * (SDL_SetRenderDrawColorFloat). Throws `SdlException` when SDL rejects the color.
     */
    public func setColorFloat(r: Float32, g: Float32, b: Float32, a: Float32): Unit {
        ensureRenderAccess("set Renderer float draw color")
        rejectDuringCommandRecording("setColorFloat")
        if (ptr.isNull()) {
            return
        }
        ensureSdl(unsafe {
            SDL_SetRenderDrawColorFloat(ptr, clamp01(r), clamp01(g), clamp01(b), clamp01(a))
        }, "SDL_SetRenderDrawColorFloat")
    }

    /**
     * Draws a single point at (`x`, `y`) in logical pixels (SDL_RenderPoint).
     * Throws `SdlException` when SDL rejects the draw color.
     */
    public func point(x: Float32, y: Float32, color: Color): Unit {
        if (recordRenderCommand(RenderCommand.DrawPoint(x, y, color))) {
            return
        }
        if (ptr.isNull()) {
            return
        }
        applyDrawColor(color)
        ensureSdl(unsafe { SDL_RenderPoint(ptr, x, y) }, "SDL_RenderPoint")
    }

    /**
     * Draws a 1px line between two points in logical pixels (SDL_RenderLine); for thick or
     * anti-aliased strokes use `strokeLine`. Throws `SdlException` when SDL rejects the draw color.
     */
    public func line(x1: Float32, y1: Float32, x2: Float32, y2: Float32, color: Color): Unit {
        if (recordRenderCommand(RenderCommand.DrawLine(x1, y1, x2, y2, color))) {
            return
        }
        if (ptr.isNull()) {
            return
        }
        applyDrawColor(color)
        ensureSdl(unsafe { SDL_RenderLine(ptr, x1, y1, x2, y2) }, "SDL_RenderLine")
    }

    /**
     * Draws a 1px rectangle outline in logical pixels (SDL_RenderRect); for thick or
     * anti-aliased outlines use `strokeRect`. Throws `SdlException` when SDL rejects the draw color.
     */
    public func rect(rect: Rect, color: Color): Unit {
        if (recordRenderCommand(RenderCommand.DrawRect(rect, color))) {
            return
        }
        if (ptr.isNull()) {
            return
        }
        applyDrawColor(color)
        var raw = rect.toSdlFRect()
        ensureSdl(unsafe { SDL_RenderRect(ptr, inout raw) }, "SDL_RenderRect")
    }

    /**
     * Fills a rectangle in logical pixels with a solid color (SDL_RenderFillRect).
     * Throws `SdlException` when SDL rejects the draw color.
     */
    public func fill(rect: Rect, color: Color): Unit {
        if (recordRenderCommand(RenderCommand.FillRect(rect, color))) {
            return
        }
        if (ptr.isNull()) {
            return
        }
        applyDrawColor(color)
        var raw = rect.toSdlFRect()
        ensureSdl(unsafe { SDL_RenderFillRect(ptr, inout raw) }, "SDL_RenderFillRect")
    }

    // Contiguous display-list runs only: callers have already proved same command kind and colour,
    // and never move a primitive across a clip/text/texture boundary. Native arrays live only for
    // the synchronous SDL call.
    internal func fillBatch(rects: Array<Rect>, color: Color): Unit {
        if (ptr.isNull() || rects.isEmpty()) {
            return
        }
        applyDrawColor(color)
        ensureRectBatchCapacity(rects.size)
        for (index in 0..rects.size) {
            unsafe { rectBatchScratch.write(index, rects[index].toSdlFRect()) }
        }
        ensureSdl(unsafe { SDL_RenderFillRects(ptr, rectBatchScratch, Int32(rects.size)) }, "SDL_RenderFillRects")
    }

    internal func rectBatch(rects: Array<Rect>, color: Color): Unit {
        if (ptr.isNull() || rects.isEmpty()) {
            return
        }
        applyDrawColor(color)
        ensureRectBatchCapacity(rects.size)
        for (index in 0..rects.size) {
            unsafe { rectBatchScratch.write(index, rects[index].toSdlFRect()) }
        }
        ensureSdl(unsafe { SDL_RenderRects(ptr, rectBatchScratch, Int32(rects.size)) }, "SDL_RenderRects")
    }

    internal func pointBatch(points: Array<Point>, color: Color): Unit {
        if (ptr.isNull() || points.isEmpty()) {
            return
        }
        applyDrawColor(color)
        ensurePointBatchCapacity(points.size)
        for (index in 0..points.size) {
            var point = SdlFPoint()
            point.x = points[index].x
            point.y = points[index].y
            unsafe { pointBatchScratch.write(index, point) }
        }
        ensureSdl(unsafe { SDL_RenderPoints(ptr, pointBatchScratch, Int32(points.size)) }, "SDL_RenderPoints")
    }

    private func ensureRectBatchCapacity(required: Int64): Unit {
        if (required <= rectBatchCapacity) {
            return
        }
        let capacity = nextBatchCapacity(rectBatchCapacity, required)
        let replacement = unsafe { LibC.malloc<SdlFRect>(count: capacity) }
        if (replacement.isNull()) {
            throw SdlException("Cannot allocate native rectangle batch scratch")
        }
        if (rectBatchScratch.isNotNull()) {
            unsafe { LibC.free(rectBatchScratch) }
        }
        rectBatchScratch = replacement
        rectBatchCapacity = capacity
    }

    private func ensurePointBatchCapacity(required: Int64): Unit {
        if (required <= pointBatchCapacity) {
            return
        }
        let capacity = nextBatchCapacity(pointBatchCapacity, required)
        let replacement = unsafe { LibC.malloc<SdlFPoint>(count: capacity) }
        if (replacement.isNull()) {
            throw SdlException("Cannot allocate native point batch scratch")
        }
        if (pointBatchScratch.isNotNull()) {
            unsafe { LibC.free(pointBatchScratch) }
        }
        pointBatchScratch = replacement
        pointBatchCapacity = capacity
    }

    private func releasePrimitiveBatchScratch(): Unit {
        if (rectBatchScratch.isNotNull()) {
            unsafe { LibC.free(rectBatchScratch) }
            rectBatchScratch = CPointer<SdlFRect>()
        }
        if (pointBatchScratch.isNotNull()) {
            unsafe { LibC.free(pointBatchScratch) }
            pointBatchScratch = CPointer<SdlFPoint>()
        }
        rectBatchCapacity = 0
        pointBatchCapacity = 0
    }

    /**
     * A thick, round-capped line drawn as one anti-aliased stadium mesh, so strokes stay
     * smooth at any angle and consecutive polyline segments join without notches.
     */
    public func strokeLine(x1: Float32, y1: Float32, x2: Float32, y2: Float32, pen: Pen): Unit {
        if (recordRenderCommand(RenderCommand.StrokeLine(x1, y1, x2, y2, pen))) {
            return
        }
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
        if (recordRenderCommand(RenderCommand.StrokeRoundedRect(rect, radius, pen))) {
            return
        }
        geometry.strokeRoundedRect(ptr, rect, roundedRadius(rect, radius), pen)
    }

    /**
     * A dashed rounded-rectangle outline — `dash` px on, `gap` px off, marched evenly around the
     * perimeter. A non-positive dash or gap draws a solid stroke instead.
     */
    public func strokeRoundedRectDashed(rect: Rect, radius: Float32, pen: Pen, dash!: Float32, gap!: Float32): Unit {
        if (recordRenderCommand(RenderCommand.StrokeRoundedRectDashed(rect, radius, pen, dash, gap))) {
            return
        }
        geometry.strokeRoundedRectDashed(ptr, rect, roundedRadius(rect, radius), pen, dash, gap)
    }

    /**
     * Fills a rounded rectangle as an anti-aliased mesh; the radius is clamped to half the
     * short side, and a radius near zero degrades to a plain `fill`.
     */
    public func fillRoundedRect(rect: Rect, radius: Float32, color: Color): Unit {
        if (recordRenderCommand(RenderCommand.FillRoundedRect(rect, radius, color))) {
            return
        }
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
        if (recordRenderCommand(RenderCommand.FillRoundedRectGradient(rect, radius, start, end, vertical))) {
            return
        }
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
        if (recordRenderCommand(
            RenderCommand.FillPerCornerRoundedRect(rect, color, topLeft, topRight, bottomRight, bottomLeft))) {
            return
        }
        geometry.fillPerCornerRoundedRect(ptr, rect, topLeft, topRight, bottomRight, bottomLeft, color)
    }

    /**
     * A rounded rectangle whose edge fades out across `feather` pixels — a single-pass
     * gradient halo, which is how soft drop shadows and focus glows are drawn banding-free.
     */
    public func fillRoundedRectSoft(rect: Rect, radius: Float32, color: Color, feather!: Float32): Unit {
        if (recordRenderCommand(RenderCommand.FillRoundedRectSoft(rect, radius, color, feather))) {
            return
        }
        geometry.fillRoundedRectSoft(ptr, rect, roundedRadius(rect, radius), color, feather)
    }

    /**
     * A 1px-pen circle outline; `segments` is a minimum tessellation hint. Shorthand for
     * `strokeCircle` with a unit-width pen.
     */
    public func circle(cx: Float32, cy: Float32, radius: Float32, color: Color, segments!: Int64 = 0): Unit {
        strokeCircle(cx, cy, radius, Pen(width: 1.0, color: color), segments: segments)
    }

    /**
     * A circle outline drawn with the given pen. `segments` is a minimum tessellation
     * hint; arcs are always sampled finely enough to stay smooth for their radius.
     */
    public func strokeCircle(cx: Float32, cy: Float32, radius: Float32, pen: Pen, segments!: Int64 = 0): Unit {
        if (recordRenderCommand(RenderCommand.StrokeCircle(cx, cy, radius, pen, segments))) {
            return
        }
        geometry.strokeCircle(ptr, Point(cx, cy), radius, pen, segments)
    }

    /** Fills a circle centred on (`cx`, `cy`) as an anti-aliased triangle-fan mesh. */
    public func fillCircle(cx: Float32, cy: Float32, radius: Float32, color: Color): Unit {
        if (recordRenderCommand(RenderCommand.FillCircle(cx, cy, radius, color))) {
            return
        }
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
        ensureRenderAccess("draw convex polygon")
        if (isRecordingCommands()) {
            appendRecordedCommand(RenderCommand.FillConvexPolygon(points.clone(), color))
            return
        }
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
     * Throws `SdlException` when the texture is closed.
     */
    public func texturedStrip(
        texture: Texture,
        points: ArrayList<Point>,
        texPoints: ArrayList<Point>,
        alphas!: ?ArrayList<Float32> = None
    ): Unit {
        ensureRenderAccess("draw textured strip")
        if (isRecordingCommands()) {
            let recordedAlphas: ?ArrayList<Float32> = match (alphas) {
                case Some(values) => Some(values.clone())
                case None => None
            }
            appendRecordedCommand(
                RenderCommand.DrawTexturedStrip(texture, points.clone(), texPoints.clone(), recordedAlphas))
            return
        }
        if (texture.isClosed()) {
            throw SdlException("Cannot render a closed texture.")
        }
        geometry.texturedStrip(ptr, texture.ptr, points, texPoints, alphas, texture.width, texture.height)
    }

    /**
     * Paints a static image with per-draw tint, opacity, rounded corners, filtering and mirroring.
     * The style uses standard alpha blending and ignores texture color/alpha modulation. Blend
     * and sampling state are restored after drawing. Recording rejects invalid/foreign textures
     * with `SdlException`, just like immediate drawing. `IllegalArgumentException` rejects
     * non-finite rectangle coordinates/edges or a source outside the texture.
     */
    public func textureStyled(texture: Texture, destination: Rect, source!: ?Rect = None,
        style!: TextureStyle = TextureStyle()): Unit {
        ensureRenderAccess("draw styled texture")
        validateImageRect(destination)
        let pixels = match (source) {
            case Some(value) => value
            case None => Rect(0.0, 0.0, texture.width, texture.height)
        }
        validateImageRect(pixels)
        if (pixels.x < 0.0 || pixels.y < 0.0 || pixels.w < 0.0 || pixels.h < 0.0 || pixels.right() > texture.width ||
            pixels.bottom() > texture.height) {
            throw IllegalArgumentException("Image source rectangle must lie inside the texture")
        }
        if (texture.isClosed() || !texture.isOwnedBy(this)) {
            throw SdlException("Cannot render a closed texture or a texture from another renderer")
        }
        if (recordRenderCommand(RenderCommand.DrawStyledTexture(texture, destination, pixels, style))) {
            return
        }
        if (destination.w <= 0.0 || destination.h <= 0.0 || pixels.w == 0.0 || pixels.h == 0.0 || style.opacity == 0.0) {
            return
        }
        let painter = match (imageGeometry) {
            case Some(value) => value
            case None =>
                let value = ImageGeometry()
                imageGeometry = Some(value)
                value
        }
        painter.draw(ptr, texture, destination, pixels, style)
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
        if (recordRenderCommand(RenderCommand.DrawText(text, x, y, color, pointSize, style,
            effectiveFontFamily(font: font)))) {
            return
        }
        drawTextCount += 1
        match (textBackend) {
            case Some(value) =>
                let native = NativeTextColor(color.r, color.g, color.b, color.a)
                let flags = style.ttfFlags()
                let family = resolveFontFamily(font, style)
                // SDL_ttf's renderer atlas can stretch synthetic italic bitmaps to estimated
                // glyph widths. Whole-run rasterization preserves shaping and the actual ink.
                if (style.italic) {
                    drawTextRaster(value, text, Point(x, y), color, pointSize, style, family)
                    return
                }
                if (scaleX == 1.0 && scaleY == 1.0) {
                    value.draw(text, snapPixel(x, 1.0), snapPixel(y, 1.0), pointSize, flags, family, native)
                    return
                }
                let step: Float32 = if (ssEnabled) {
                    Float32(ssFactor)
                } else {
                    1.0
                }
                let px = snapPixel(x * scaleX, step)
                let py = snapPixel(y * scaleY, step)
                ensureSdl(unsafe { SDL_SetRenderScale(ptr, 1.0, 1.0) }, "SDL_SetRenderScale")
                try {
                    applyClipForTextPass()
                    value.draw(text, px, py, pointSize * scaleY, flags, family, native)
                } finally {
                    ensureSdl(unsafe { SDL_SetRenderScale(ptr, scaleX, scaleY) }, "SDL_SetRenderScale")
                    applyClip()
                }
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
        ensureRenderAccess("measure text")
        textMetrics(text, pointSize, style, resolveFontFamily(font, style)).width
    }

    /**
     * Returns the standard line height for the requested point size and style.
     */
    public func textHeight(
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): Float32 {
        ensureRenderAccess("measure text")
        textMetrics("国Ag", pointSize, style, resolveFontFamily(font, style)).height
    }

    /** Primary-face ascent/descent and line spacing, using the actual current raster size. */
    public func fontMetrics(pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular,
        font!: ?String = None): FontMetrics {
        ensureRenderAccess("measure font metrics")
        let family = resolveFontFamily(font, style)
        let effectiveSize = normalizeFontPointSize(pointSize * scaleY)
        match (textBackend) {
            case Some(backend) =>
                let metrics = backend.lineMetrics(effectiveSize, style.ttfFlags(), family)
                FontMetrics(metrics.ascent / scaleY, metrics.descent / scaleY, metrics.height / scaleY,
                    metrics.lineSkip / scaleY)
            case None =>
                let size = effectiveSize / scaleY
                FontMetrics(size, size * 0.3, size * 1.3, size * 1.3)
        }
    }

    /**
     * Conservative raster rectangle relative to the top-left `text` origin, for this exact string.
     * Includes raster padding and overhang; this is not a typographic advance or a tight ink box.
     */
    public func textBounds(text: String, pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular,
        font!: ?String = None): Rect {
        ensureRenderAccess("measure text bounds")
        if (text.isEmpty()) {
            return Rect.zero()
        }
        let metrics = textMetrics(text, pointSize, style, resolveFontFamily(font, style))
        Rect(0.0, 0.0, metrics.width, metrics.height)
    }

    /**
     * Glyph bitmap and decoration bounds relative to the text origin, excluding line-box whitespace.
     * Shares the bounded metrics cache. Older SDL_ttf libraries and headless renderers return the
     * conservative textBounds rectangle. This is not a typographic advance or a cluster layout.
     */
    public func textInkBounds(text: String, pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular,
        font!: ?String = None): Rect {
        ensureRenderAccess("measure text ink bounds")
        if (text.isEmpty()) {
            return Rect.zero()
        }
        let metrics = textMetrics(text, pointSize, style, resolveFontFamily(font, style))
        Rect(metrics.inkX, metrics.inkY, metrics.inkWidth, metrics.inkHeight)
    }

    /** Resolves and opens a font request, reporting real faces, synthetic styles and load failures. */
    public func resolveFont(font!: ?String = None, pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular): FontResolution {
        ensureRenderAccess("inspect font resolution")
        let requested = effectiveFontFamily(font: font)
        let family = resolveFontFamily(font, style)
        match (textBackend) {
            case Some(backend) =>
                let resolved = backend.resolve(normalizeFontPointSize(pointSize * scaleY), style.ttfFlags(), family)
                let faces = Array<ResolvedFontFace>(resolved.faces.size) {
                    i =>
                        let face = resolved.faces[i]
                        let flags = face.synthesizedFlags
                        ResolvedFontFace(publicFontSource(face.source), face.familyName, face.styleName,
                            FontStyle(bold: (flags & 1) != 0, italic: (flags & 2) != 0, underline: (flags & 4) != 0,
                                strikethrough: (flags & 8) != 0), weight: FontWeight(max(1, min(1000, face.weight))))
                }
                let warnings = ArrayList<String>(resolved.warnings)
                if (let Some(name) <- requested) {
                    if (Fonts.resolveFamily(name).isNone()) {
                        warnings.add("Unknown font family '${name}'; using platform UI font")
                    }
                }
                if (!faces.isEmpty() && faces[0].weight != style.weight) {
                    warnings.add(
                        "Requested weight ${style.weight.value}; selected face weight ${faces[0].weight.value}")
                }
                FontResolution(requested, faces, warnings.toArray(), requestedWeight: style.weight)
            case None => FontResolution(requested, [], ["Headless renderer uses estimated font metrics"],
                requestedWeight: style.weight)
        }
    }

    /**
     * Opens a reusable measurement session for paragraph fitting. Unlike repeated `textWidth`
     * calls, this owns one UTF-8 buffer and asks SDL_ttf for a fitting prefix directly, avoiding
     * substring construction and repeated full-suffix shaping. Close the returned resource after
     * layout. Off-screen renderers provide the same byte-boundary contract with deterministic
     * estimated metrics.
     */
    public func textMeasureSession(
        text: String,
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): TextMeasureSession {
        ensureRenderAccess("create text measurement session")
        let family = resolveFontFamily(font, style)
        let logicalScaleX = scaleX
        let logicalScaleY = scaleY
        let flags = style.ttfFlags()
        match (textBackend) {
            case Some(backend) => nativeMeasureSession(text, pointSize, flags, family, backend, logicalScaleX,
                logicalScaleY)
            case None => headlessMeasureSession(text, pointSize, style)
        }
    }

    private func nativeMeasureSession(
        text: String,
        pointSize: Float32,
        flags: Int32,
        family: NativeFontFamily,
        backend: NativeTextRenderer,
        logicalScaleX: Float32,
        logicalScaleY: Float32
    ): TextMeasureSession {
        let native = backend.measureSession(text, pointSize * logicalScaleY, flags, family)
        TextMeasureSession(
            text,
            device,
            {
                startByte, maxWidth =>
                    measureCount += 1
                    computeCount += 1
                    let nativeFit = native.fit(startByte, fitWidthToInt32(maxWidth * logicalScaleX))
                    TextFitResult(nativeFit.width / logicalScaleX, nativeFit.byteLength)
            },
            {
                startByte, length =>
                    measureCount += 1
                    computeCount += 1
                    native.measure(startByte, length) / logicalScaleX
            },
            {
                x, y =>
                    let hit = native.hitTest(fitWidthToInt32(x * logicalScaleX), fitWidthToInt32(y * logicalScaleY))
                    TextHitResult(hit.byteOffset, hit.clusterByteLength,
                        Rect(hit.x / logicalScaleX, hit.y / logicalScaleY, hit.width / logicalScaleX,
                            hit.height / logicalScaleY))
            },
            {=> native.close()}
        )
    }

    private func headlessMeasureSession(text: String, pointSize: Float32, style: FontStyle): TextMeasureSession {
        let effective = normalizeFontPointSize(pointSize * scaleY)
        let unitWidth = headlessTextUnitWidth(effective, style) / scaleX
        let lineHeight = effective / scaleY * 1.3
        TextMeasureSession(
            text,
            device,
            {
                startByte, maxWidth =>
                    measureCount += 1
                    computeCount += 1
                    headlessFit(text, startByte, maxWidth, unitWidth)
            },
            {
                _, length =>
                    measureCount += 1
                    computeCount += 1
                    Float32(length) * unitWidth
            },
            {x, _ => headlessTextHit(text, x, unitWidth, lineHeight / 1.3)},
            {=> ()}
        )
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
        ensureRenderAccess("draw centered text")
        let bounds = textInkBounds(text, pointSize: pointSize, style: style, font: font)
        let tx = rect.centerX() - bounds.w / 2.0 - bounds.x
        let ty = rect.centerY() - bounds.h / 2.0 - bounds.y
        this.text(text, tx, ty, color, pointSize: pointSize, style: style, font: font)
    }

    /**
     * Draws UTF-8 text rotated by `angleDegrees` (clockwise; -90 reads bottom-to-top), centred on
     * `(centerX, centerY)` in logical coordinates.
     *
     * The straight-text path (`text`) draws through the SDL_ttf text engine, which rasterizes
     * glyphs directly onto the render target and cannot rotate them. This path instead rasterizes
     * the whole shaped string once into a texture and draws it through the
     * rotating texture pipeline. Glyphs are rasterized at the EFFECTIVE pixel size (`pointSize`
     * times the live render scale), so under supersampling the texture maps 1:1 onto physical
     * pixels — as sharp as straight text, not an upscale.
     *
     * Rasterizations are cached across frames (keyed by text, size, style, face, scale and RGB;
     * alpha is applied per draw), preserving color glyphs. A static rotated label costs one
     * rasterization, not one per frame. Headless renderers and empty text no-op.
     */
    public func textRotated( // cjcheck-ignore: param-count # public fluent API: 5 positional + 3 named-with-default params is the binding's established text signature shape
        text: String,
        centerX: Float32,
        centerY: Float32,
        angleDegrees: Float64,
        color: Color,
        pointSize!: Float32 = FontSizes.BODY,
        style!: FontStyle = FontStyle.regular,
        font!: ?String = None
    ): Unit {
        if (recordRenderCommand(
            RenderCommand.DrawTextRotated(text, centerX, centerY, angleDegrees, color, pointSize, style,
                effectiveFontFamily(font: font)))) {
            return
        }
        if (ptr.isNull() || text.isEmpty()) {
            return
        }
        let backend = match (textBackend) {
            case Some(value) => value
            case None => return
        }
        let raster = match (rotatedTextTexture(backend, text, pointSize, style, resolveFontFamily(font, style), color)) {
            case Some(value) => value
            case None => return
        }
        try (resource = raster) {
            let image = resource.image
            let width = image.layoutSize.w / scaleX
            let height = image.layoutSize.h / scaleY
            let cx = snapPixel(centerX * scaleX, 1.0) / scaleX
            let cy = snapPixel(centerY * scaleY, 1.0) / scaleY
            image.draw(ptr, Point(cx - width / 2.0, cy - height / 2.0), Size(scaleX, scaleY), color, angle: angleDegrees)
        }
    }

    private func drawTextRaster(
        backend: NativeTextRenderer,
        text: String,
        position: Point,
        color: Color,
        pointSize: Float32,
        style: FontStyle,
        family: NativeFontFamily
    ): Unit {
        if (text.isEmpty()) {
            return
        }
        let raster = match (rotatedTextTexture(backend, text, pointSize, style, family, color)) {
            case Some(value) => value
            case None => return
        }
        try (resource = raster) {
            let step: Float32 = if (ssEnabled) {
                Float32(ssFactor)
            } else {
                1.0
            }
            let origin = Point(snapPixel(position.x * scaleX, step), snapPixel(position.y * scaleY, step))
            ensureSdl(unsafe { SDL_SetRenderScale(ptr, 1.0, 1.0) }, "SDL_SetRenderScale")
            try {
                applyClipForTextPass()
                resource.image.draw(ptr, origin, Size(1.0, 1.0), color)
            } finally {
                ensureSdl(unsafe { SDL_SetRenderScale(ptr, scaleX, scaleY) }, "SDL_SetRenderScale")
                applyClip()
            }
        }
    }

    /*
     * The cached color-preserving rasterization at the current render scale. The effective size
     * lives in the key, so the same label rasterized inside a supersampled scene and outside one
     * are distinct entries and each draws 1:1 on its own pixel grid.
     */
    private func rotatedTextTexture(
        backend: NativeTextRenderer,
        text: String,
        pointSize: Float32,
        style: FontStyle,
        family: NativeFontFamily,
        color: Color
    ): ?TextRaster {
        let effectiveSize = normalizeFontPointSize(pointSize * scaleY)
        let rgb = (UInt32(color.r) << 16) | (UInt32(color.g) << 8) | UInt32(color.b)
        let key = TextRasterKey(family.cacheKey, style.ttfFlags(), effectiveSize.toBits(), text, rgb: rgb)
        let tintKey = TextRasterKey(family.cacheKey, style.ttfFlags(), effectiveSize.toBits(), text)
        match (textTextureCache.get(key)) {
            case Some(cached) => return Some(cached)
            case None => ()
        }
        if (key != tintKey) {
            if (let Some(cached) <- textTextureCache.get(tintKey)) {
                if (cached.image.canTint()) {
                    return Some(cached)
                }
                cached.close()
            }
        }
        let raster = backend.renderColorSurface(text, effectiveSize, style.ttfFlags(), family,
            NativeTextColor(color.r, color.g, color.b, 255))
        let surface = raster.pointer;
        let colorBaked = raster.colorBaked
        if (surface.isNull()) {
            return None
        }
        let pixels = Surface(surface)
        try {
            let image = createTextRasterImage(ptr, device, pixels.ptr, maxTextureSize, colorBaked: colorBaked,
                offset: Point(Float32(raster.x), Float32(raster.y)), layoutSize: Some(Size(raster.width, raster.height)))
            try {
                return Some(textTextureCache.put(if (colorBaked) {
                    key
                } else {
                    tintKey
                }, image))
            } catch (error: Exception) {
                image.close()
                throw error
            }
        } finally {
            pixels.close()
        }
    }

    private func clearTextTextureCache(): Unit {
        textTextureCache.clear()
    }

    /**
     * Prepares the next scene's raster scale before layout/input. Allocates the sampling target
     * early so allocation failure uses the same direct-rendering metrics. Does not clear pixels
     * or switch targets. Follow layout with beginScene/beginRenderPass at the same logical size;
     * drawing belongs inside that pass. Call again after resize or endScene. Headless is a no-op.
     * Throws IllegalArgumentException for non-finite/non-positive dimensions, or SdlException
     * if the device rejects the scale. Not allowed while recording render commands.
     */
    public func prepareTextLayout(logicalWidth: Float32, logicalHeight: Float32): Unit {
        ensureRenderAccess("prepare text layout")
        rejectDuringCommandRecording("prepareTextLayout")
        if (logicalWidth <= 0.0 || logicalHeight <= 0.0 || logicalWidth.isNaN() || logicalHeight.isNaN() ||
            logicalWidth.isInf() || logicalHeight.isInf()) {
            throw IllegalArgumentException("Text layout dimensions must be finite and positive")
        }
        if (ptr.isNull()) {
            return
        }
        refreshOutputSampling()
        if (ssEnabled && (ssTarget.isNull() || plannedTargetWidth != ssWidth || plannedTargetHeight != ssHeight)) {
            allocateTarget(plannedTargetWidth, plannedTargetHeight)
        }
        let sx = if (ssEnabled) {
            Float32(plannedTargetWidth) / max(1.0, logicalWidth)
        } else {
            contentScale
        }
        let sy = if (ssEnabled) {
            Float32(plannedTargetHeight) / max(1.0, logicalHeight)
        } else {
            contentScale
        }
        ensureSdl(unsafe { SDL_SetRenderScale(ptr, sx, sy) }, "SDL_SetRenderScale")
        scaleX = sx
        scaleY = sy
    }

    /** Actual logical-to-raster measurement scale, including current supersampling. */
    public func textMeasurementScale(): Size {
        ensureRenderAccess("inspect text measurement scale")
        Size(scaleX, scaleY)
    }

    /** Resolves an explicit selector, a renderer scope, then the application font default. */
    public func effectiveFontFamily(font!: ?String = None): ?String {
        ensureRenderAccess("resolve font selector")
        match (font) {
            case Some(_) => font
            case None => match (scopedFontFamily) {
                case Some(_) => scopedFontFamily
                case None => Fonts.defaultFamily()
            }
        }
    }

    /** Runs a synchronous operation with an inherited font; nested scopes restore on exceptions. */
    public func withFontFamily<T>(name: String, body: () -> T): T {
        ensureRenderAccess("enter font scope")
        let previous = scopedFontFamily
        scopedFontFamily = Some(name)
        try {
            body()
        } finally {
            scopedFontFamily = previous
        }
    }

    /** Counts cached font configurations and whole-run text textures for diagnostics. */
    public func fontCacheStats(): FontCacheStats {
        ensureRenderAccess("inspect font cache")
        let groups = match (textBackend) {
            case Some(backend) => backend.fontGroupCount()
            case None => 0
        }
        let atlas: (Int64, Int64, UInt64) = match (textBackend) {
            case Some(backend) => backend.glyphAtlasStats()
            case None => (0, 0, UInt64(0))
        }
        FontCacheStats(groups, textTextureCache.size(), textTextureCache.bytes(), textTextureCache.rasterizations(),
            glyphAtlasBytes: atlas[0], cachedGlyphs: atlas[1], glyphAtlasEvictions: atlas[2])
    }

    /**
     * Releases this renderer's cached fonts now and invalidates other renderers lazily.
     * Close live measurement sessions first when replacing a file on platforms that lock open fonts.
     */
    public func reloadFonts(): Unit {
        ensureRenderAccess("reload fonts")
        rejectDuringCommandRecording("reloadFonts")
        Fonts.reload()
        synchronizeFontRegistry()
    }

    /** Text measurements requested since the last reset — a per-frame text-cost probe. */
    public func textMeasureCount(): UInt64 {
        ensureRenderAccess("inspect text measurement count")
        measureCount
    }

    /** Actual measurement computations (cache misses) since the last reset — SDL_ttf calls on a real backend. */
    public func textComputeCount(): UInt64 {
        ensureRenderAccess("inspect text computation count")
        computeCount
    }

    /** Text draws issued since the last reset — each rasterizes a (cached, already-shaped) string on a real backend. */
    public func textDrawCount(): UInt64 {
        ensureRenderAccess("inspect text draw count")
        drawTextCount
    }

    /**
     * Shaping operations (shaped-text cache misses) since the last reset — the real TTF_CreateText
     * calls on a display backend, 0 when headless. On a warm cache during a scroll this stays flat
     * while `textDrawCount` scales with frames, which is the shaped-text cache working.
     */
    public func textShapeCount(): UInt64 {
        ensureRenderAccess("inspect text shaping count")
        match (textBackend) {
            case Some(value) => value.shapeCount()
            case None => 0
        }
    }

    /** Resets the text measurement, compute, draw, and shape counters; call at a frame boundary to sample one frame. */
    public func resetTextMeasureCount(): Unit {
        ensureRenderAccess("reset text diagnostics")
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
    private func resolveFontFamily(font: ?String, style: FontStyle): NativeFontFamily {
        synchronizeFontRegistry()
        let family = match (effectiveFontFamily(font: font)) {
            case None => resolvedNamedFamily(FontRole.systemUI)
            case Some(name) => resolvedNamedFamily(name)
        }
        family.withRequest(style.weight.value, style.variations.native(), style.variations.key())
    }

    private func resolvedNamedFamily(name: String): NativeFontFamily {
        match (resolvedFontFamilies.get(name)) {
            case Some(family) => return family
            case None => ()
        }
        let definition = if (textBackend.isSome()) {
            Fonts.resolveFamily(name)
        } else {
            Fonts.familyFor(name)
        }
        let family = match (definition) {
            case Some(value) => value.native("${name.size}:${name}|${Fonts.revision()}")
            case None => FontFamily(FontSource("")).native("system")
        }
        if (resolvedFontFamilies.size >= 64) {
            resolvedFontFamilies.clear()
        }
        resolvedFontFamilies[name] = family
        family
    }

    private func synchronizeFontRegistry(): Unit {
        let revision = Fonts.revision()
        if (observedFontRevision == revision) {
            return
        }
        observedFontRevision = revision
        resolvedFontFamilies.clear()
        advanceCommandEpoch()
        match (textBackend) {
            case Some(backend) => backend.invalidateFonts()
            case None => ()
        }
        metricsCache.clear()
        for ((_, cache) in namedMetricsCaches) {
            cache.clear()
        }
        namedMetricsCaches.clear()
        clearTextTextureCache()
    }

    // The metrics cache for a face path. The default face ("") keeps the original single cache on the
    // hot path; each application font gets its own cache created on first use, so a named font never
    // perturbs the default font's cache or key space.
    private func metricsCacheFor(family: NativeFontFamily): TextMetricsCache {
        if (family.cacheKey == "system") {
            return metricsCache
        }
        metricsCacheClock += 1
        match (namedMetricsCaches.get(family.cacheKey)) {
            case Some(cache) =>
                cache.lastUse = metricsCacheClock
                cache
            case None =>
                trimNamedMetricsCaches()
                let cache = TextMetricsCache(TEXT_METRICS_CAP_PER_SIZE)
                cache.lastUse = metricsCacheClock
                namedMetricsCaches[family.cacheKey] = cache
                cache
        }
    }

    private func trimNamedMetricsCaches(): Unit {
        if (namedMetricsCaches.size < 16) {
            return
        }
        var oldest: UInt64 = UInt64.Max
        var victim = ""
        for ((key, cache) in namedMetricsCaches) {
            if (cache.lastUse < oldest) {
                oldest = cache.lastUse
                victim = key
            }
        }
        namedMetricsCaches.remove(victim)
    }

    private func textMetrics(text: String, pointSize: Float32, style: FontStyle, family: NativeFontFamily): NativeTextMetrics {
        measureCount += 1
        let flags = style.ttfFlags()
        // Cache the metrics in the rasterizer's physical coordinate space. Scaled text is drawn
        // 1:1 at `pointSize * scaleY`, so this native value depends on the effective point size but
        // not on scaleX. Mapping it back after lookup preserves non-uniform-scale semantics and lets
        // centered controls reuse the same FreeType measurement across frames instead of missing on
        // every draw merely because the scene scale is not 1.
        let effectivePointSize = normalizeFontPointSize(pointSize * scaleY)
        // Fold the style flags (0..15) into the low bits of the effective-size key so bold and plain
        // runs are cached apart. The face path selects the cache without lengthening the string key.
        let sizeKey = Int64(effectivePointSize * Float32(256.0)) * 16 + Int64(flags)
        let cache = metricsCacheFor(family)
        let nativeMetrics = match (cache.get(sizeKey, text)) {
            case Some(cached) => cached
            case None =>
                computeCount += 1
                let computed = computeMetrics(text, effectivePointSize, style, family)
                cache.put(sizeKey, text, computed)
                computed
        }
        if (scaleX == 1.0 && scaleY == 1.0) {
            nativeMetrics
        } else {
            // Carets, selection bands and centering decisions remain in logical units while
            // matching the exact hinted rasterization painted by the scaled text pass.
            NativeTextMetrics(nativeMetrics.width / scaleX, nativeMetrics.height / scaleY,
                inkX: nativeMetrics.inkX / scaleX, inkY: nativeMetrics.inkY / scaleY,
                inkWidth: nativeMetrics.inkWidth / scaleX, inkHeight: nativeMetrics.inkHeight / scaleY)
        }
    }

    // The uncached measurement: the real font backend, or a proportional estimate when headless.
    private func computeMetrics(text: String, pointSize: Float32, style: FontStyle, family: NativeFontFamily): NativeTextMetrics {
        match (textBackend) {
            case Some(value) => value.measure(text, pointSize, style.ttfFlags(), family)
            case None => headlessMetrics(text, pointSize, style)
        }
    }

    // The proportional estimate used with no font backend, so layout and event tests run headless.
    // Bold widens the advance a touch (mirroring faux-bold), giving the style path a deterministic,
    // assertable width difference off-screen; underline/strikethrough leave metrics unchanged.
    private func headlessMetrics(text: String, pointSize: Float32, style: FontStyle): NativeTextMetrics {
        NativeTextMetrics(Float32(text.size) * headlessTextUnitWidth(pointSize, style), pointSize * 1.3)
    }

    // While the text pass draws with the GPU scale reset to 1:1, the active clip must be
    // re-expressed in target pixels: SDL clip rectangles live in the current scaled space.
    private func applyClipForTextPass(): Unit {
        match (currentClipUnchecked()) {
            case Some(rect) =>
                var raw = scaledSdlClipRect(rect, scaleX, scaleY)
                ensureSdl(unsafe { SDL_SetRenderClipRect(ptr, inout raw) }, "SDL_SetRenderClipRect text pass")
            case None => ()
        }
    }

    /**
     * Reads back the current render target and writes it to a BMP file. Useful for
     * automated visual snapshots and documentation thumbnails. Headless it is a no-op —
     * there are no pixels to read.
     *
     * Throws `SdlException` when SDL cannot read the pixels or save the file.
     */
    public func captureBmp(path: String): Unit {
        ensureRenderAccess("capture Renderer bitmap")
        rejectDuringCommandRecording("captureBmp")
        if (ptr.isNull()) {
            return
        }
        let surface = unsafe { SDL_RenderReadPixels(ptr, CPointer<SdlRect>()) }
        if (surface.isNull()) {
            throw SdlException("SDL_RenderReadPixels failed: ${lastSdlError()}")
        }
        let cPath = unsafe { LibC.mallocCString(path) }
        try (pathResource = cPath.asResource()) {
            let saved = unsafe { SDL_SaveBMP(surface, pathResource.value) }
            unsafe { SDL_DestroySurface(surface) }
            if (!saved) {
                throw SdlException("SDL_SaveBMP failed: ${lastSdlError()}")
            }
        }
    }
}

private func headlessTextUnitWidth(pointSize: Float32, style: FontStyle): Float32 {
    let boldFactor: Float32 = if (style.bold) {
        1.06
    } else {
        1.0
    }
    pointSize * 0.55 * boldFactor
}

private func fitWidthToInt32(width: Float32): Int32 {
    if (width <= 0.0) {
        0
    } else if (width >= Float32(Int32.Max)) {
        Int32.Max
    } else {
        Int32(width)
    }
}

private func headlessFit(text: String, startByte: Int64, maxWidth: Float32, unitWidth: Float32): TextFitResult {
    let byteBudget = if (unitWidth <= 0.0) {
        text.size - startByte
    } else {
        min(text.size - startByte, Int64(maxWidth / unitWidth))
    }
    var fitted: Int64 = 0
    while (fitted < byteBudget) {
        let lead = text[startByte + fitted]
        let runeBytes: Int64 = if (lead < UInt8(128)) {
            1
        } else if (lead < UInt8(224)) {
            2
        } else if (lead < UInt8(240)) {
            3
        } else {
            4
        }
        if (fitted + runeBytes > byteBudget) {
            break
        }
        fitted += runeBytes
    }
    TextFitResult(Float32(fitted) * unitWidth, fitted)
}

private func headlessTextHit(text: String, x: Float32, unitWidth: Float32, pointSize: Float32): TextHitResult {
    if (text.isEmpty() || x <= 0.0 || unitWidth <= 0.0) {
        return TextHitResult(0, 0, Rect(0.0, 0.0, 0.0, pointSize * 1.3))
    }
    var start: Int64 = 0
    while (start < text.size) {
        let length = utf8RuneByteLength(text[start])
        let left = Float32(start) * unitWidth
        let width = Float32(length) * unitWidth
        if (x < left + width / 2.0) {
            return TextHitResult(start, length, Rect(left, 0.0, width, pointSize * 1.3))
        }
        if (x < left + width) {
            return TextHitResult(start + length, length, Rect(left, 0.0, width, pointSize * 1.3))
        }
        start += length
    }
    TextHitResult(text.size, 0, Rect(Float32(text.size) * unitWidth, 0.0, 0.0, pointSize * 1.3))
}

private func utf8RuneByteLength(lead: UInt8): Int64 {
    if (lead < UInt8(128)) {
        1
    } else if (lead < UInt8(224)) {
        2
    } else if (lead < UInt8(240)) {
        3
    } else {
        4
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
 * Throws `SdlException` when the system-font backend cannot initialize.
 */
private func createTextBackend(renderer: CPointer<Unit>): ?NativeTextRenderer {
    if (renderer.isNull()) {
        return None
    }
    try {
        Some(NativeTextRenderer(renderer, bootstrapSources: fontBootstrapSources()))
    } catch (error: NativeTextException) {
        throw SdlException("System UI font initialization failed: ${error.message}")
    }
}
