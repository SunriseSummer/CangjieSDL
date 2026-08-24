package sdl.text

import std.collection.{ArrayList, HashMap, HashSet}
import std.math.abs

private let DEFAULT_POINT_SIZE: Float32 = 15.0
private let FONT_SIZE_EPSILON: Float32 = 0.01

// TTF_STYLE_BOLD, and the mask of every other flag (italic/underline/strikethrough). Bold is the
// one style worth a real companion face — synthetic emboldening thickens strokes unevenly and
// roughens edges, while slants and rules synthesise cleanly.
private let STYLE_BOLD: Int32 = 0x01
private let STYLE_NON_BOLD_MASK: Int32 = 0x0E

// SDL_Color packed as the UInt32 the TTF_RenderText_Blended binding declares: white at full
// alpha. Glyph coverage is colour-independent, so surfaces render white once and callers apply
// the actual colour as a texture colour mod.
private let WHITE_TEXT_PIXEL: UInt32 = 0xFFFFFFFF

protected class NativeTextException <: Exception {
    public init(message: String) {
        super(message)
    }
}

protected struct NativeTextMetrics {
    public let width: Float32
    public let height: Float32

    public init(width: Float32, height: Float32) {
        this.width = width
        this.height = height
    }
}

protected struct NativeTextFit {
    public let width: Float32
    public let byteLength: Int64

    public init(width: Float32, byteLength: Int64) {
        this.width = width
        this.byteLength = byteLength
    }
}

protected struct NativeTextHit {
    public let byteOffset: Int64
    public let clusterByteLength: Int64
    public let x: Float32
    public let y: Float32
    public let width: Float32
    public let height: Float32

    public init(byteOffset: Int64, clusterByteLength: Int64, x: Float32, y: Float32, width: Float32, height: Float32) {
        this.byteOffset = byteOffset
        this.clusterByteLength = clusterByteLength
        this.x = x
        this.y = y
        this.width = width
        this.height = height
    }
}

/** Resolved primary/fallback paths supplied by the parent renderer package. */
protected struct NativeFontFamily {
    public let primaryPath: String
    public let fallbackPaths: Array<String>
    public let cacheKey: String

    public init(primaryPath: String, fallbackPaths: Array<String>, cacheKey: String) {
        this.primaryPath = primaryPath
        this.fallbackPaths = fallbackPaths
        this.cacheKey = cacheKey
    }
}

/*
 * One owned UTF-8 buffer plus one resolved font. Paragraph layout creates this once and measures
 * many ranges without allocating a CString for every line/probe. The caller validates UTF-8
 * boundaries; SDL_ttf receives explicit byte lengths and never scans past the selected range.
 */
protected class NativeTextMeasureSession <: Resource {
    private static let INITIAL_FIT_WINDOW_BYTES: Int64 = 256
    private static let FIT_WINDOW_GROWTH: Int64 = 4
    private static let UTF8_CONTINUATION_MIN: UInt8 = UInt8(0x80)
    private static let UTF8_CONTINUATION_LIMIT: UInt8 = UInt8(0xC0)
    private static let UTF8_TWO_BYTE_LIMIT: UInt8 = UInt8(0xE0)
    private static let UTF8_THREE_BYTE_LIMIT: UInt8 = UInt8(0xF0)
    private static let UTF8_ONE_BYTE_LENGTH: Int64 = 1
    private static let UTF8_TWO_BYTE_LENGTH: Int64 = 2
    private static let UTF8_THREE_BYTE_LENGTH: Int64 = 3
    private static let UTF8_FOUR_BYTE_LENGTH: Int64 = 4
    private let font: CPointer<Unit>
    private let engine: CPointer<Unit>
    private let text: CString
    private let source: String
    private let byteLength: Int64
    private var closed: Bool = false
    private var layout: CPointer<Unit> = CPointer<Unit>()

    public init(engine: CPointer<Unit>, font: CPointer<Unit>, value: String) {
        this.engine = engine
        this.font = font
        this.text = unsafe { LibC.mallocCString(value) }
        this.source = value
        this.byteLength = value.size
    }

    /*
     * Measures the longest UTF-8 prefix beginning at `startByte` that fits `maxWidth`.
     */
    public func fit(startByte: Int64, maxWidth: Int32): NativeTextFit {
        ensureOpen()
        let remaining = byteLength - startByte
        if (remaining <= 0 || maxWidth <= 0) {
            return NativeTextFit(0.0, 0)
        }
        let start = unsafe { text.getChars() + startByte }
        var probeLength = utf8BoundedProbe(startByte, min(remaining, INITIAL_FIT_WINDOW_BYTES))
        var result = NativeTextFit(0.0, 0)
        var settled = false
        while (!settled) {
            var measuredWidth: Int32 = 0
            var measuredLength: UIntNative = UIntNative(0)
            ensureNative(unsafe {
                TTF_MeasureString(
                    font,
                    CString(start),
                    UIntNative(probeLength),
                    maxWidth,
                    inout measuredWidth,
                    inout measuredLength
                )
            }, "TTF_MeasureString")
            if (measuredLength > UIntNative(probeLength)) {
                throw NativeTextException("TTF_MeasureString returned a byte count beyond the supplied buffer")
            }
            let accepted = Int64(measuredLength)
            if (accepted < probeLength || probeLength >= remaining) {
                result = NativeTextFit(Float32(measuredWidth), accepted)
                settled = true
            } else {
                let expanded = if (probeLength > remaining / FIT_WINDOW_GROWTH) {
                    remaining
                } else {
                    probeLength * FIT_WINDOW_GROWTH
                }
                probeLength = utf8BoundedProbe(startByte, min(remaining, expanded))
            }
        }
        result
    }

    /*
     * Measures one validated UTF-8 byte range without constructing a temporary CString.
     */
    public func measure(startByte: Int64, length: Int64): Float32 {
        ensureOpen()
        if (length <= 0) {
            return 0.0
        }
        var width: Int32 = 0
        var height: Int32 = 0
        let start = unsafe { text.getChars() + startByte }
        ensureNative(unsafe {
            TTF_GetStringSize(
                font,
                CString(start),
                UIntNative(length),
                inout width,
                inout height
            )
        }, "TTF_GetStringSize")
        Float32(width)
    }

    /** Returns the shaped cluster/caret boundary closest to a text-local point. */
    public func hitTest(x: Int32, y: Int32): NativeTextHit {
        ensureOpen()
        ensureLayout()
        var substring = TtfSubstring()
        ensureNative(unsafe { TTF_GetTextSubStringForPoint(layout, x, y, inout substring) },
            "TTF_GetTextSubStringForPoint")
        let direction = substring.flags & UInt32(0xFF)
        let afterVisualMidpoint = x >= substring.rect.x + substring.rect.w / 2
        let offset = if (direction == UInt32(5)) {
            if (afterVisualMidpoint) {
                substring.offset
            } else {
                substring.offset + substring.length
            }
        } else if (afterVisualMidpoint) {
            substring.offset + substring.length
        } else {
            substring.offset
        }
        NativeTextHit(Int64(offset), Int64(substring.length), Float32(substring.rect.x), Float32(substring.rect.y),
            Float32(substring.rect.w), Float32(substring.rect.h))
    }

    /*
     * Releases the owned UTF-8 buffer; repeated calls are safe.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        if (layout.isNotNull()) {
            unsafe { TTF_DestroyText(layout) }
            layout = CPointer<Unit>()
        }
        unsafe { LibC.free(text) }
    }

    /*
     * Reports whether the owned UTF-8 buffer has already been released.
     */
    public func isClosed(): Bool {
        closed
    }

    private func ensureOpen(): Unit {
        if (closed) {
            throw IllegalStateException("Text measurement session is closed")
        }
    }

    private func ensureLayout(): Unit {
        if (layout.isNotNull()) {
            return
        }
        layout = unsafe { TTF_CreateText(engine, font, text, UIntNative(byteLength)) }
        if (layout.isNull()) {
            throw NativeTextException("TTF_CreateText failed: ${lastNativeError()}")
        }
    }

    private func utf8BoundedProbe(startByte: Int64, wanted: Int64): Int64 {
        var end = startByte + wanted
        while (end < byteLength && source[end] >= UTF8_CONTINUATION_MIN && source[end] < UTF8_CONTINUATION_LIMIT) {
            end -= 1
        }
        if (end == startByte) {
            let lead = source[startByte]
            end += if (lead < UTF8_CONTINUATION_MIN) {
                UTF8_ONE_BYTE_LENGTH
            } else if (lead < UTF8_TWO_BYTE_LIMIT) {
                UTF8_TWO_BYTE_LENGTH
            } else if (lead < UTF8_THREE_BYTE_LIMIT) {
                UTF8_THREE_BYTE_LENGTH
            } else {
                UTF8_FOUR_BYTE_LENGTH
            }
        }
        end - startByte
    }
}

protected struct NativeTextColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }
}

protected class NativeTextRenderer {
    private let engine: CPointer<Unit>
    private let systemPath: String
    // The always-available platform UI font. Every text draw with no explicit face, and any face
    // whose file cannot be opened, falls back to this.
    private let defaultFace: FontFace
    // Successfully opened application font files, keyed by file path — opened lazily on first use.
    private let faces = HashMap<String, FontFace>()
    // Paths that failed to open once, remembered so a bad path degrades to the system font without
    // re-attempting the open every frame.
    private let failedPaths = HashSet<String>()
    private var closed: Bool = false

    /**
     * Throws `NativeTextException` when SDL_ttf cannot initialize the system-font backend.
     */
    public init(renderer: CPointer<Unit>) {
        if (!unsafe { TTF_Init() }) {
            throw NativeTextException("TTF_Init failed: ${lastNativeError()}")
        }
        let found = findSystemFontPath()
        if (let Some(value) <- found) {
            this.systemPath = value
        } else {
            unsafe { TTF_Quit() }
            throw NativeTextException("No supported system UI font was found: ${lastNativeError()}")
        }
        let createdEngine = unsafe { TTF_CreateRendererTextEngine(renderer) }
        this.engine = createdEngine
        if (createdEngine.isNull()) {
            unsafe { TTF_Quit() }
            throw NativeTextException("TTF_CreateRendererTextEngine failed: ${lastNativeError()}")
        }
        this.defaultFace = FontFace(systemPath, engine)
        // Warm the default face at the base size, so a font engine that cannot shape for the system
        // font fails fast at construction (as the previous eager text object did) rather than mid-frame.
        try {
            defaultFace.fontFor(DEFAULT_POINT_SIZE, 0)
        } catch (error: NativeTextException) {
            defaultFace.close()
            unsafe { TTF_DestroyRendererTextEngine(engine) }
            unsafe { TTF_Quit() }
            throw error
        }
    }

    /**
     * Measures `text` at the given size and style via TTF_GetStringSize, returning width and
     * height in pixels. Throws `NativeTextException` when SDL_ttf cannot measure the string.
     */
    public func measure(text: String, pointSize: Float32, styleFlags: Int32, family: NativeFontFamily): NativeTextMetrics {
        let font = fontForFamily(family, pointSize, styleFlags)
        let cText = unsafe { LibC.mallocCString(text) }
        var metrics = NativeTextMetrics(0.0, 0.0)
        try (textResource = cText.asResource()) {
            var width: Int32 = 0
            var height: Int32 = 0
            ensureNative(unsafe {
                TTF_GetStringSize(font.pointer(), textResource.value, UIntNative(text.size), inout width, inout height)
            }, "TTF_GetStringSize")
            metrics = NativeTextMetrics(Float32(width), Float32(height))
        }
        metrics
    }

    /** Creates an owned, reusable UTF-8 measurement buffer for paragraph layout. */
    public func measureSession(
        text: String,
        pointSize: Float32,
        styleFlags: Int32,
        family: NativeFontFamily
    ): NativeTextMeasureSession {
        NativeTextMeasureSession(engine, fontForFamily(family, pointSize, styleFlags).pointer(), text)
    }

    /**
     * Rasterizes `text` into a new RGBA surface via TTF_RenderText_Blended and returns the raw
     * SDL surface pointer — null for empty text or when rasterization fails. Glyphs are white at
     * full alpha so the caller can colour the resulting texture with a colour mod, which also
     * keeps colour out of any caching key. The caller owns the surface and must destroy it.
     *
     * This is the path for text that must be transformed (rotated axis titles): the text engine
     * `draw` uses rasterizes straight onto the render target and cannot rotate, while a surface
     * can become a texture and go through the rotating texture pipeline.
     */
    public func renderSurface(text: String, pointSize: Float32, styleFlags: Int32, family: NativeFontFamily): CPointer<Unit> {
        if (text.isEmpty()) {
            return CPointer<Unit>()
        }
        let font = fontForFamily(family, pointSize, styleFlags)
        let cText = unsafe { LibC.mallocCString(text) }
        var surface = CPointer<Unit>()
        try (textResource = cText.asResource()) {
            surface = unsafe {
                TTF_RenderText_Blended(font.pointer(), textResource.value, UIntNative(text.size), WHITE_TEXT_PIXEL)
            }
        }
        surface
    }

    /**
     * Draws `text` at (`x`, `y`) in target pixels through the renderer text engine, reusing the
     * cached shaped-text object for an unchanged string; empty text is a no-op. Throws
     * `NativeTextException` when SDL_ttf cannot shape or draw the string.
     */
    public func draw(
        text: String,
        x: Float32,
        y: Float32,
        pointSize: Float32,
        styleFlags: Int32,
        family: NativeFontFamily,
        color: NativeTextColor
    ): Unit {
        if (text.isEmpty()) {
            return
        }
        // The font reuses a cached, already-shaped text object for `text`, so an unchanged string
        // (every visible label during a scroll) is not re-shaped by SDL_ttf — only redrawn.
        fontForFamily(family, pointSize, styleFlags).drawText(text, x, y, color)
    }

    private func fontForFamily(family: NativeFontFamily, pointSize: Float32, styleFlags: Int32): NativeFont {
        let primary = fontForPath(family.primaryPath, pointSize, styleFlags)
        let fallbacks = ArrayList<NativeFont>()
        for (path in family.fallbackPaths) {
            let fallback = fontForPath(path, pointSize, styleFlags)
            if (!sameNativeFont(primary, fallback) && !containsNativeFont(fallbacks, fallback)) {
                fallbacks.add(fallback)
            }
        }
        // A named application face always ends at the platform UI face, preventing tofu when its
        // declared chain omitted a script. The default face cannot fall back to itself.
        if (!family.primaryPath.isEmpty()) {
            let system = defaultFace.fontFor(pointSize, styleFlags)
            if (!sameNativeFont(primary, system) && !containsNativeFont(fallbacks, system)) {
                fallbacks.add(system)
            }
        }
        primary.configureFallbacks(family.cacheKey, fallbacks)
        primary
    }

    /*
     * The font handle for (facePath, size, style), degrading like faceFor does. faceFor only guards a
     * face's FIRST open: a face already cached can still fail later, because each new (size, style)
     * variant opens the file again (ejected drive, file replaced mid-run). A named face failing here is
     * remembered and evicted, and the call falls back to the system face at the same size and style —
     * only the system face itself failing propagates, matching the constructor's fail-fast contract.
     */
    private func fontForPath(facePath: String, pointSize: Float32, styleFlags: Int32): NativeFont {
        let face = faceFor(facePath)
        try {
            face.fontFor(pointSize, styleFlags)
        } catch (error: NativeTextException) {
            if (facePath.isEmpty() || failedPaths.contains(facePath)) {
                throw error
            }
            failedPaths.add(facePath)
            // Keep an already-open face alive: another primary may still reference one of its
            // fonts as a fallback. It is reclaimed with the renderer after all chains are cleared.
            defaultFace.fontFor(pointSize, styleFlags)
        }
    }

    /*
     * Total shaping operations across all faces and sizes since the last reset — each is one
     * TTF_CreateText, a shaped-text cache miss. A per-frame text-cost probe: on a warm cache this
     * stays flat while draw calls scale with frames, which is the caching doing its job.
     */
    public func shapeCount(): UInt64 {
        var total = defaultFace.shapeCount()
        for ((_, face) in faces) {
            total += face.shapeCount()
        }
        total
    }

    /** Zeroes the shaping counters on every face; call at a frame boundary to sample one frame. */
    public func resetShapeCount(): Unit {
        defaultFace.resetShapeCount()
        for ((_, face) in faces) {
            face.resetShapeCount()
        }
    }

    /** The default face's font family name, or "System UI" when SDL_ttf reports none. */
    public func familyName(): String {
        let name = defaultFace.familyName()
        if (name.isEmpty()) {
            "System UI"
        } else {
            name
        }
    }

    /** The file path of the system font the default face was opened from. */
    public func path(): String {
        systemPath
    }

    /**
     * Closes every open face, destroys the text engine, and shuts down SDL_ttf; safe to call
     * more than once.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        defaultFace.clearFallbacks()
        for ((_, face) in faces) {
            face.clearFallbacks()
        }
        defaultFace.close()
        for ((_, face) in faces) {
            face.close()
        }
        faces.clear()
        unsafe { TTF_DestroyRendererTextEngine(engine) }
        unsafe { TTF_Quit() }
    }

    // The face for a font-file path: empty selects the default system face; a path opens (and caches)
    // that file's face lazily. A path that cannot be opened is remembered as failed and falls back to
    // the default face, so a bad or missing font file degrades to the system font instead of throwing.
    private func faceFor(facePath: String): FontFace {
        if (facePath.isEmpty() || failedPaths.contains(facePath)) {
            return defaultFace
        }
        match (faces.get(facePath)) {
            case Some(face) => return face
            case None => ()
        }
        let face = FontFace(facePath, engine)
        try {
            face.fontFor(DEFAULT_POINT_SIZE, 0)
        } catch (_: NativeTextException) {
            face.close()
            failedPaths.add(facePath)
            return defaultFace
        }
        faces[facePath] = face
        face
    }
}

/*
 * One typeface: a font file opened at whatever (size, style) combinations the UI asks for. Each
 * combination is its own TTF_Font handle with its own shaped-text cache — TTF_SetFontStyle changes
 * glyph shape and advance width, so a variant needs a distinct handle for correct measurement and
 * rendering. The default system font and every application-loaded font are each one FontFace.
 */
private class FontFace {
    private let path: String
    private let engine: CPointer<Unit>
    private let fonts = ArrayList<NativeFont>()
    private var closed: Bool = false
    // Lazily probed path of the true-bold companion file; None when the face has no separately
    // shipped bold weight and bold must be synthesised.
    private var boldProbed: Bool = false
    private var boldCompanionPath: ?String = None

    init(path: String, engine: CPointer<Unit>) {
        this.path = path
        this.engine = engine
    }

    // A font handle for the requested size and style, opened, style-set, and attached on first use
    // and cached for reuse. Throws `NativeTextException` when the file cannot be opened or the engine
    // cannot shape for it.
    func fontFor(pointSize: Float32, styleFlags: Int32): NativeFont {
        let normalized = normalizePointSize(pointSize)
        for (font in fonts) {
            if (font.styleFlags == styleFlags && abs(font.pointSize - normalized) < FONT_SIZE_EPSILON) {
                return font
            }
        }
        let font = openStyled(normalized, styleFlags)
        // Close the freshly opened font if it cannot attach: it is not yet in `fonts`, so close()
        // would never reach it, and there is no finalizer — a failed attach would otherwise leak the
        // native TTF_Font handle.
        try {
            font.attach(engine)
        } catch (error: NativeTextException) {
            font.close()
            throw error
        }
        fonts.add(font)
        font
    }

    /*
     * Opens the handle for (size, style), preferring a real bold face over a synthetic one: a bold
     * request opens the face's true-bold companion file when one ships alongside (msyh.ttc ->
     * msyhbd.ttc, segoeui.ttf -> segoeuib.ttf, X-Regular -> X-Bold), with only the remaining flags
     * synthesised on top of it. A face without a companion — or a companion that fails to open
     * mid-run — falls back to synthesising every flag from the base file.
     */
    private func openStyled(pointSize: Float32, styleFlags: Int32): NativeFont {
        if ((styleFlags & STYLE_BOLD) != 0) {
            if (let Some(boldFile) <- boldCompanion()) {
                try {
                    return openFont(boldFile, pointSize, styleFlags, styleFlags & STYLE_NON_BOLD_MASK)
                } catch (_: NativeTextException) { // cjcheck-ignore: swallow-catch # recovery is the fall-through: the return above is skipped and the base file opens in faux bold below
                    // Degrade like every other font failure: the base file still renders, in faux bold.
                }
            }
        }
        openFont(path, pointSize, styleFlags, styleFlags)
    }

    // The true-bold companion file's path, probed once per face and remembered (None when the face
    // ships no separate bold weight).
    private func boldCompanion(): ?String {
        if (!boldProbed) {
            boldProbed = true
            boldCompanionPath = probeBoldCompanion(path)
        }
        boldCompanionPath
    }

    func familyName(): String {
        if (fonts.isEmpty()) {
            return ""
        }
        let name = unsafe { TTF_GetFontFamilyName(fonts[0].pointer()) }
        if (name.isNull()) {
            ""
        } else {
            name.toString()
        }
    }

    func shapeCount(): UInt64 {
        var total: UInt64 = 0
        for (font in fonts) {
            total += font.shapeCount
        }
        total
    }

    func resetShapeCount(): Unit {
        for (font in fonts) {
            font.shapeCount = 0
        }
    }

    func clearFallbacks(): Unit {
        for (font in fonts) {
            font.clearFallbacks()
        }
    }

    func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        var index = fonts.size - 1
        while (index >= 0) {
            fonts[index].close()
            index -= 1
        }
        fonts.clear()
    }
}

// One shaped, ready-to-draw text object plus the colour last applied to it, so redrawing the same
// string in the same colour next frame skips even the colour update.
internal class ShapedText {
    let pointer: CPointer<Unit>
    var colorKey: Int64 = -1

    init(pointer: CPointer<Unit>) {
        this.pointer = pointer
    }
}

// Packs an RGBA colour into one Int64 so a text object's current colour compares in a single check.
private func colorKey(color: NativeTextColor): Int64 {
    (Int64(color.red) << 24) | (Int64(color.green) << 16) | (Int64(color.blue) << 8) | Int64(color.alpha)
}

private class NativeFont {
    let pointSize: Float32
    // The SDL_ttf TTF_STYLE_* bitmask baked into this handle (0 = regular). Part of the cache key
    // alongside pointSize, so bold and regular text of the same size resolve to distinct handles.
    let styleFlags: Int32
    private let font: CPointer<Unit>
    private var engine = CPointer<Unit>()
    private var fallbackKey: String = ""
    // Already-shaped text objects for this size, reused across frames; a miss is the only path that
    // shapes a string. Bounded and self-freeing: an evicted object's TTF_Text is destroyed.
    private let cache: GenerationCache<String, ShapedText>
    // Shaped-text cache misses (real TTF_CreateText calls) since the last reset. No access modifier
    // so the renderer can total it as a per-frame text-cost probe.
    var shapeCount: UInt64 = 0
    private var closed: Bool = false

    init(font: CPointer<Unit>, pointSize: Float32, styleFlags: Int32, syntheticFlags: Int32) {
        this.font = font
        this.pointSize = pointSize
        this.styleFlags = styleFlags
        // Bake the synthesised styles into the handle once. A handle opened from a true-bold
        // companion file arrives with the bold bit already cleared here — the weight is in the
        // outlines — while slants and rules are always synthesised on top.
        if (syntheticFlags != 0) {
            unsafe { TTF_SetFontStyle(font, syntheticFlags) }
        }
        this.cache = GenerationCache<String, ShapedText>(SHAPED_TEXT_CACHE_CAP) {
            shaped => if (shaped.pointer.isNotNull()) {
                unsafe { TTF_DestroyText(shaped.pointer) }
            }
        }
    }

    /**
     * Binds this font to the shared text engine and fails fast — as the previous eager text object
     * did — if the engine cannot shape for it. Throws `NativeTextException` on failure.
     */
    func attach(engine: CPointer<Unit>): Unit {
        this.engine = engine
        let probe = unsafe { TTF_CreateText(engine, font, CString(CPointer<UInt8>()), UIntNative(0)) }
        if (probe.isNull()) {
            throw NativeTextException("TTF_CreateText failed: ${lastNativeError()}")
        }
        unsafe { TTF_DestroyText(probe) }
    }

    /**
     * Draws `text` at (x, y) in `color`, reusing a cached shaped-text object so an unchanged string
     * is not re-shaped by SDL_ttf — only a cache miss shapes. Throws `NativeTextException` on failure.
     */
    func drawText(text: String, x: Float32, y: Float32, color: NativeTextColor): Unit {
        let shaped = obtainShaped(text)
        let wanted = colorKey(color)
        // The text object remembers its colour, so only a genuine change touches SDL_ttf again.
        if (shaped.colorKey != wanted) {
            ensureNative(unsafe {
                TTF_SetTextColor(shaped.pointer, color.red, color.green, color.blue, color.alpha)
            }, "TTF_SetTextColor")
            shaped.colorKey = wanted
        }
        ensureNative(unsafe { TTF_DrawRendererText(shaped.pointer, x, y) }, "TTF_DrawRendererText")
    }

    // The shaped text object for `text`, created and cached on first use. Only this miss path calls
    // TTF_CreateText (the shaping cost); repeats hit the cache.
    private func obtainShaped(text: String): ShapedText {
        match (cache.get(text)) {
            case Some(shaped) => return shaped
            case None => ()
        }
        let cText = unsafe { LibC.mallocCString(text) }
        var pointer = CPointer<Unit>()
        try (textResource = cText.asResource()) {
            pointer = unsafe { TTF_CreateText(engine, font, textResource.value, UIntNative(text.size)) }
        }
        if (pointer.isNull()) {
            throw NativeTextException("TTF_CreateText failed: ${lastNativeError()}")
        }
        shapeCount += 1
        let shaped = ShapedText(pointer)
        cache.put(text, shaped)
        shaped
    }

    func pointer(): CPointer<Unit> {
        font
    }

    func configureFallbacks(key: String, fallbacks: ArrayList<NativeFont>): Unit {
        if (fallbackKey == key) {
            return
        }
        clearFallbacks()
        for (fallback in fallbacks) {
            ensureNative(unsafe { TTF_AddFallbackFont(font, fallback.pointer()) }, "TTF_AddFallbackFont")
        }
        fallbackKey = key
    }

    func clearFallbacks(): Unit {
        unsafe { TTF_ClearFallbackFonts(font) }
        fallbackKey = ""
    }

    func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        clearFallbacks()
        cache.clear()
        unsafe { TTF_CloseFont(font) }
    }
}

private func sameNativeFont(left: NativeFont, right: NativeFont): Bool {
    refEq(left, right)
}

private func containsNativeFont(fonts: ArrayList<NativeFont>, wanted: NativeFont): Bool {
    for (font in fonts) {
        if (sameNativeFont(font, wanted)) {
            return true
        }
    }
    false
}

// The first system-font candidate that SDL_ttf can open, probed by opening then immediately closing
// it. The default face reopens it lazily per size; this only settles which path to use.
private func findSystemFontPath(): ?String {
    for (path in systemFontCandidates()) {
        let cPath = unsafe { LibC.mallocCString(path) }
        try (pathResource = cPath.asResource()) {
            let pointer = unsafe { TTF_OpenFont(pathResource.value, DEFAULT_POINT_SIZE) }
            if (pointer.isNotNull()) {
                unsafe { TTF_CloseFont(pointer) }
                return path
            }
        }
    }
    None
}

/**
 * Throws `NativeTextException` when SDL_ttf cannot open the selected system font.
 */
private func openFont(path: String, pointSize: Float32, styleFlags: Int32, syntheticFlags: Int32): NativeFont {
    let cPath = unsafe { LibC.mallocCString(path) }
    var font = CPointer<Unit>()
    try (pathResource = cPath.asResource()) {
        font = unsafe { TTF_OpenFont(pathResource.value, pointSize) }
        if (font.isNull()) {
            throw NativeTextException("TTF_OpenFont failed: ${lastNativeError()}")
        }
    }
    NativeFont(font, pointSize, styleFlags, syntheticFlags)
}

// Splits a font path into stem and extension, recognising only real font-file extensions so a
// dotted directory name is never mistaken for one.
private func splitFontExt(path: String): (String, String) {
    for (ext in [".ttf", ".ttc", ".otf", ".TTF", ".TTC", ".OTF"]) {
        if (path.endsWith(ext)) {
            return (path[0..path.size - ext.size], ext)
        }
    }
    (path, "")
}

/*
 * Filename spellings under which a face's true-bold companion ships, tried in order: the
 * "-Regular" -> "-Bold" convention of most downloadable families (Noto, LXGW WenKai), then the
 * Windows stem suffixes ("bd" for msyh -> msyhbd and arial -> arialbd, "b" for segoeui ->
 * segoeuib), then a plain "-Bold" suffix. Pure string work so tests can pin the shapes; whether a
 * candidate exists is settled by probeBoldCompanion.
 */
protected func boldCompanionCandidates(path: String): Array<String> {
    let (stem, ext) = splitFontExt(path)
    let out = ArrayList<String>()
    if (!ext.isEmpty()) {
        if (stem.endsWith("-Regular")) {
            out.add(stem[0..stem.size - 8] + "-Bold" + ext)
        } else if (stem.endsWith("Regular")) {
            out.add(stem[0..stem.size - 7] + "Bold" + ext)
        }
        out.add(stem + "bd" + ext)
        out.add(stem + "b" + ext)
        out.add(stem + "-Bold" + ext)
    }
    out.toArray()
}

// The first bold-companion candidate SDL_ttf can actually open, probed open-then-close exactly like
// findSystemFontPath; None when no candidate exists. Runs once per face and is remembered.
private func probeBoldCompanion(path: String): ?String {
    for (candidate in boldCompanionCandidates(path)) {
        let cPath = unsafe { LibC.mallocCString(candidate) }
        try (pathResource = cPath.asResource()) {
            let pointer = unsafe { TTF_OpenFont(pathResource.value, DEFAULT_POINT_SIZE) }
            if (pointer.isNotNull()) {
                unsafe { TTF_CloseFont(pointer) }
                return candidate
            }
        }
    }
    None
}

private func systemFontCandidates(): Array<String> {
    [
        "C:\\Windows\\Fonts\\msyh.ttc",
        "C:\\Windows\\Fonts\\segoeui.ttf",
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/SFNS.ttf",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    ]
}

private func normalizePointSize(pointSize: Float32): Float32 {
    if (pointSize <= 0.0) {
        DEFAULT_POINT_SIZE
    } else {
        pointSize
    }
}

/**
 * Throws `NativeTextException` when an SDL_ttf operation reports failure.
 */
private func ensureNative(ok: Bool, api: String): Unit {
    if (!ok) {
        throw NativeTextException("${api} failed: ${lastNativeError()}")
    }
}

private func lastNativeError(): String {
    let error = unsafe { SDL_GetError() }
    if (error.isNull()) {
        "unknown SDL_ttf error"
    } else {
        error.toString()
    }
}
