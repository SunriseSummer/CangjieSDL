package sdl.text

import std.collection.{ArrayList, HashMap, HashSet}
import std.env.getVariable

private let DEFAULT_POINT_SIZE: Float32 = 15.0
private let FONT_GROUP_CAPACITY: Int64 = 24
// FreeType retains COLR/CPAL tables per face, even when several faces share the same file.
// Bound cached color-table residency as well as configuration count; live sessions keep leases.
private let FONT_COLOR_TABLE_BUDGET: Int64 = 64 * 1024 * 1024
private let FONT_FAILURE_CACHE_CAPACITY: Int64 = 512
private let SHAPED_TEXT_ENTRY_OVERHEAD: Int64 = 256
private let SHAPED_TEXT_BYTE_BUDGET: Int64 = 512 * 1024
private let ESTIMATED_SHAPED_BYTES_PER_UTF8_BYTE: Int64 = 192

// SDL_ttf style bits: real weight/slant faces are preferred; decorations remain independent.
private let STYLE_BOLD: Int32 = 0x01
private let STYLE_ITALIC: Int32 = 0x02
private let STYLE_FACE_MASK: Int32 = 0x03
private let STYLE_DECORATION_MASK: Int32 = 0x0C
private let NORMAL_FONT_WEIGHT: Int64 = 400
private let BOLD_FONT_WEIGHT: Int64 = 700

protected class NativeTextException <: Exception {
    public init(message: String) {
        super(message)
    }
}

protected struct NativeTextMetrics {
    public let width: Float32
    public let height: Float32
    public let inkX: Float32
    public let inkY: Float32
    public let inkWidth: Float32
    public let inkHeight: Float32

    public init(width: Float32, height: Float32, inkX!: Float32 = 0.0, inkY!: Float32 = 0.0, inkWidth!: Float32 = -1.0,
        inkHeight!: Float32 = -1.0) {
        this.width = width
        this.height = height
        this.inkX = inkX
        this.inkY = inkY
        this.inkWidth = if (inkWidth < 0.0) {
            width
        } else {
            inkWidth
        }
        this.inkHeight = if (inkHeight < 0.0) {
            height
        } else {
            inkHeight
        }
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
    private let systemSource: NativeFontSource
    // The always-available platform UI font. Every text draw with no explicit face, and any face
    // whose file cannot be opened, falls back to this.
    private let defaultFace: FontFace
    // Each cache entry owns a complete, immutable primary/fallback graph. Sharing a mutable
    // TTF_Font between family names corrupts both shaping caches and outstanding sessions.
    private let groups = HashMap<NativeFontKey, NativeFontGroup>()
    private let failedPaths = HashMap<String, String>()
    private let emojiFallback = EmojiFallback()
    // Non-owning lookup: immutable emoji leaves are leased by their font groups, never kept
    // alive by this map. Different sizes and renderer engines remain isolated.
    private let emojiFaces = HashMap<UInt32, SharedEmojiFace>()
    private let sessions = ArrayList<NativeTextMeasureSession>()
    private var useCounter: UInt64 = UInt64(0)
    private var retiredShapes: UInt64 = UInt64(0)
    private var closed: Bool = false

    /**
     * Throws `NativeTextException` when SDL_ttf cannot initialize the system-font backend.
     */
    public init(renderer: CPointer<Unit>, bootstrapSources!: ?Array<NativeFontSource> = None) {
        if (!unsafe { TTF_Init() }) {
            throw NativeTextException("TTF_Init failed: ${lastNativeError()}")
        }
        let found = findBootstrapFont(bootstrapSources.getOrDefault({=> nativeSystemFontCandidates()}))
        if (let Some(value) <- found) {
            this.systemSource = value
        } else {
            unsafe { TTF_Quit() }
            throw NativeTextException(
                "No usable font. Configure an application default or fallback font file: ${lastNativeError()}")
        }
        let createdEngine = createNativeTextEngine(renderer)
        this.engine = createdEngine
        if (createdEngine.isNull()) {
            unsafe { TTF_Quit() }
            throw NativeTextException("Cangjie text engine creation failed: ${lastNativeError()}")
        }
        this.defaultFace = FontFace(systemSource, engine)
        // Warm the default face at the base size, so a font engine that cannot shape for the system
        // font fails fast at construction (as the previous eager text object did) rather than mid-frame.
        try {
            defaultFace.fontFor(DEFAULT_POINT_SIZE, 0)
        } catch (error: NativeTextException) {
            defaultFace.close()
            destroyNativeTextEngine(engine)
            unsafe { TTF_Quit() }
            throw error
        }
    }

    /**
     * Measures `text` at the given size and style via TTF_GetStringSize, returning width and
     * height in pixels. Throws `NativeTextException` when SDL_ttf cannot measure the string.
     */
    public func measure(text: String, pointSize: Float32, styleFlags: Int32, family: NativeFontFamily): NativeTextMetrics {
        fontForFamily(family, pointSize, styleFlags, emoji: emojiFallback.needed(text)).measureText(text)
    }

    /** Creates an owned, reusable UTF-8 measurement buffer for paragraph layout. */
    public func measureSession(
        text: String,
        pointSize: Float32,
        styleFlags: Int32,
        family: NativeFontFamily
    ): NativeTextMeasureSession {
        sessions.removeIf({session => session.isClosed()})
        let group = groupForFamily(family, pointSize, styleFlags, emoji: emojiFallback.needed(text))
        group.acquire()
        let session = NativeTextMeasureSession(engine, group.primary.pointer(), text, {=> group.release()})
        sessions.add(session)
        session
    }

    /**
     * Rasterizes shaped `text` into a straight-alpha surface with white monochrome glyphs.
     * Returns null for zero-area text and throws on shaping/allocation failure.
     * The caller owns the surface and must destroy it; color glyphs retain their palette.
     *
     * This is the path for text that must be transformed (rotated axis titles): the text engine
     * `draw` uses rasterizes straight onto the render target and cannot rotate, while a surface
     * can become a texture and go through the rotating texture pipeline.
     */
    public func renderSurface(text: String, pointSize: Float32, styleFlags: Int32, family: NativeFontFamily): CPointer<Unit> {
        if (text.isEmpty()) {
            return CPointer<Unit>()
        }
        fontForFamily(family, pointSize, styleFlags, emoji: emojiFallback.needed(text)).rasterText(text, None).pointer
    }

    /** Returns an owned raster and whether RGB is baked with premultiplied alpha for color glyphs. */
    public func renderColorSurface(text: String, pointSize: Float32, styleFlags: Int32, family: NativeFontFamily,
        color: NativeTextColor): NativeTextSurface {
        if (text.isEmpty()) {
            return NativeTextSurface(CPointer<Unit>(), TtfSubstringRect(), NativeTextMetrics(0.0, 0.0))
        }
        fontForFamily(family, pointSize, styleFlags, emoji: emojiFallback.needed(text)).rasterText(text, Some(color))
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
        fontForFamily(family, pointSize, styleFlags, emoji: emojiFallback.needed(text)).drawText(text, x, y, color)
    }

    private func fontForFamily(family: NativeFontFamily, pointSize: Float32, styleFlags: Int32, emoji!: Bool = false): NativeFont {
        groupForFamily(family, pointSize, styleFlags, emoji: emoji).primary
    }

    private func groupForFamily(family: NativeFontFamily, pointSize: Float32, styleFlags: Int32, emoji!: Bool = false): NativeFontGroup {
        let normalized = normalizePointSize(pointSize)
        let key = NativeFontKey(family.cacheKey, normalized.toBits(), styleFlags, emoji: emoji)
        useCounter += 1
        match (groups.get(key)) {
            case Some(group) =>
                group.lastUse = useCounter
                return group
            case None => ()
        }
        let request = if (family.weight == 0) {
            family.withRequest(if ((styleFlags & STYLE_BOLD) != 0) {
                BOLD_FONT_WEIGHT
            } else {
                NORMAL_FONT_WEIGHT
            }, family.coordinates, "legacy")
        } else {
            family
        }
        let group = openGroup(request, normalized, styleFlags, emoji: emoji)
        trimGroups()
        group.lastUse = useCounter
        groups[key] = group
        trimColorGroups(key)
        group
    }

    private func trimColorGroups(current: NativeFontKey): Unit {
        while (cachedColorTableBytes() > FONT_COLOR_TABLE_BUDGET) {
            var oldest = UInt64.Max
            var victim: ?NativeFontKey = None
            for ((key, group) in groups) {
                if (key != current && group.hasColorTables() && group.lastUse < oldest) {
                    oldest = group.lastUse
                    victim = Some(key)
                }
            }
            // A single large active request or externally pinned sessions can exceed the budget.
            // Keeping that request usable takes precedence over discarding the font's color data.
            match (victim) {
                case Some(key) =>
                    if (let Some(group) <- groups.remove(key)) {
                        retiredShapes += group.shapeCount()
                        group.retire()
                    }
                case None => return
            }
        }
    }

    private func cachedColorTableBytes(): Int64 {
        let seen = HashSet<UIntNative>()
        var bytes: Int64 = 0
        for ((_, group) in groups) {
            bytes += group.colorTableBytes(seen)
        }
        bytes
    }

    private func openGroup(family: NativeFontFamily, pointSize: Float32, styleFlags: Int32, emoji!: Bool): NativeFontGroup {
        let owned = ArrayList<FontFace>()
        let used = HashSet<String>()
        let system = systemSource
        let source = if (family.primaryPath.isEmpty()) {
            system
        } else {
            family.primary
        }
        let warnings = ArrayList<String>()
        var emojiFace: ?SharedEmojiFace = None
        try {
            let primaryFace = openPrimaryFace(source, family, pointSize, styleFlags, warnings)
            owned.add(primaryFace)
            let primary = primaryFace.fontFor(pointSize, styleFlags)
            used.add(primaryFace.sourceKey())
            let fallbackFonts = ArrayList<NativeFont>()
            let sources = ArrayList<NativeFontSource>(family.fallbacks)
            sources.add(system)
            for (fallbackSource in sources) {
                if (used.contains(fallbackSource.key())) {
                    continue
                }
                used.add(fallbackSource.key())
                let fallbackFamily = NativeFontFamily(fallbackSource, [], family.cacheKey, synthesize: family.synthesize,
                    weight: family.weight)
                match (openFace(fallbackSource, pointSize, styleFlags, warnings, family: Some(fallbackFamily))) {
                    case Some(face) =>
                        owned.add(face)
                        fallbackFonts.add(face.fontFor(pointSize, styleFlags))
                    case None => ()
                }
            }
            if (emoji) {
                emojiFace = appendEmojiFallback(family, pointSize, used, fallbackFonts, warnings)
            }
            primary.configureFallbacks(family.cacheKey, fallbackFonts)
            NativeFontGroup(primary, owned.toArray(), warnings.toArray(), emoji: emojiFace)
        } catch (error: Exception) {
            closeUnpublishedFaces(owned)
            if (let Some(face) <- emojiFace) {
                face.release()
            }
            throw error
        }
    }

    private func openPrimaryFace(source: NativeFontSource, family: NativeFontFamily, pointSize: Float32,
        styleFlags: Int32, warnings: ArrayList<String>): FontFace {
        match (openFace(source, pointSize, styleFlags, warnings, family: Some(family))) {
            case Some(face) => face
            case None => FontFace(systemSource, engine,
                family: Some(
                    NativeFontFamily(systemSource, [], family.cacheKey, synthesize: family.synthesize,
                        weight: family.weight)))
        }
    }

    private func closeUnpublishedFaces(owned: ArrayList<FontFace>): Unit {
        // Detach every fallback edge before freeing any face referenced by another font.
        for (face in owned) {
            face.clearFallbacks()
        }
        for (face in owned) {
            face.close()
        }
    }

    private func appendEmojiFallback(family: NativeFontFamily, pointSize: Float32, used: HashSet<String>,
        fallbacks: ArrayList<NativeFont>, warnings: ArrayList<String>): ?SharedEmojiFace {
        if (let Some(source) <- emojiFallback.source()) {
            if (used.contains(source.key())) {
                return None
            }
            let key = pointSize.toBits()
            if (let Some(face) <- emojiFaces.get(key)) {
                if (face.alive()) {
                    fallbacks.add(face.font)
                    face.acquire()
                    return Some(face)
                }
            }
            let expired = ArrayList<UInt32>()
            for ((size, face) in emojiFaces) {
                if (!face.alive()) {
                    expired.add(size)
                }
            }
            for (size in expired) {
                let _ = emojiFaces.remove(size) // cjcheck-ignore: ignore-result # keys were collected from the non-owning lookup above
            }
            // Emoji palettes and bitmap strikes should not inherit synthetic bold/slant or variable axes.
            let emojiFamily = NativeFontFamily(source, [], family.cacheKey + "|emoji-fallback", synthesize: false,
                weight: 400)
            if (let Some(face) <- openFace(source, pointSize, 0, warnings, family: Some(emojiFamily))) {
                let shared = SharedEmojiFace(face, face.fontFor(pointSize, 0))
                fallbacks.add(shared.font)
                shared.acquire()
                emojiFaces[key] = shared
                return Some(shared)
            }
        }
        None
    }

    private func openFace(source: NativeFontSource, pointSize: Float32, styleFlags: Int32, warnings: ArrayList<String>,
        family!: ?NativeFontFamily = None): ?FontFace {
        let familyKey = family.getOrDefault({=> NativeFontFamily(source, [], "")}).cacheKey
        let key = "${source.key()}|${pointSize.toBits()}|${styleFlags}|${familyKey}"
        match (failedPaths.get(key)) {
            case Some(message) =>
                warnings.add(message)
                return None
            case None => ()
        }
        let face = FontFace(source, engine, family: family)
        try {
            face.fontFor(pointSize, styleFlags)
            Some(face)
        } catch (error: NativeTextException) {
            face.close()
            let message = "${source.path} [face ${source.faceIndex}]: ${error.message}"
            if (failedPaths.size >= FONT_FAILURE_CACHE_CAPACITY) {
                failedPaths.clear()
            }
            failedPaths[key] = message
            warnings.add(message)
            None
        }
    }

    /** Primary font vertical metrics, at the same native size used for drawing. */
    public func lineMetrics(pointSize: Float32, styleFlags: Int32, family: NativeFontFamily): NativeLineMetrics {
        fontForFamily(family, pointSize, styleFlags).lineMetrics()
    }

    /** Actual immutable face graph and source failures for this request. */
    public func resolve(pointSize: Float32, styleFlags: Int32, family: NativeFontFamily): NativeFontResolution {
        let group = groupForFamily(family, pointSize, styleFlags)
        let faces = Array<NativeFontInfo>(group.faces.size) {i => group.faces[i].fontFor(pointSize, styleFlags).info()}
        NativeFontResolution(faces, group.warnings)
    }

    private func trimGroups(): Unit {
        if (groups.size < FONT_GROUP_CAPACITY) {
            return
        }
        var oldest: UInt64 = UInt64.Max
        var victim = NativeFontKey("", UInt32(0), 0)
        for ((key, group) in groups) {
            if (group.lastUse < oldest) {
                oldest = group.lastUse
                victim = key
            }
        }
        match (groups.remove(victim)) {
            case Some(group) =>
                retiredShapes += group.shapeCount()
                group.retire()
            case None => ()
        }
    }

    /** Invalidates positive and negative font caches; live sessions keep their old font graph. */
    public func invalidateFonts(): Unit {
        for ((_, group) in groups) {
            retiredShapes += group.shapeCount()
            group.retire()
        }
        groups.clear()
        failedPaths.clear()
        emojiFallback.reset()
        emojiFaces.clear()
    }

    /** Cached immutable font configurations, excluding resources pinned by live sessions. */
    public func glyphAtlasStats(): (Int64, Int64, UInt64) {
        let atlas = nativeTextEngine(engine).atlas
        (atlas.bytes, atlas.size(), atlas.evictions)
    }

    /** Cached immutable font configurations, excluding resources pinned by live sessions. */
    public func fontGroupCount(): Int64 {
        groups.size
    }

    /** Total shaped-text cache misses since the last reset, including evicted groups. */
    public func shapeCount(): UInt64 {
        var total = retiredShapes
        for ((_, group) in groups) {
            total += group.shapeCount()
        }
        total
    }

    /** Zeroes shaping counters without invalidating cached text. */
    public func resetShapeCount(): Unit {
        retiredShapes = UInt64(0)
        for ((_, group) in groups) {
            group.resetShapeCount()
        }
    }

    /** Family name of the platform UI face. */
    public func familyName(): String {
        let name = defaultFace.familyName()
        if (name.isEmpty()) {
            "System UI"
        } else {
            name
        }
    }

    /** File path of the platform UI face. */
    public func path(): String {
        systemSource.path
    }

    /** Drops only GPU glyph resources; shaped layouts and live measurement sessions remain valid. */
    public func invalidateGlyphAtlas(): Unit {
        nativeTextEngine(engine).atlas.close()
    }

    /** Closes sessions before fonts and their shared text engine; repeated calls are safe. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        for (session in sessions) {
            session.close()
        }
        sessions.clear()
        invalidateFonts()
        defaultFace.close()
        destroyNativeTextEngine(engine)
        unsafe { TTF_Quit() }
    }
}

// The group's primary/fallback edges are immutable. Automatic emoji leaves can be shared:
// detach all outgoing edges before releasing the leaf lease, including on construction failure.
private class NativeFontGroup {
    let primary: NativeFont
    let faces: Array<FontFace>
    let warnings: Array<String>
    var lastUse: UInt64 = UInt64(0)
    private var leases: Int64 = 0
    private var retired: Bool = false
    private var disposed: Bool = false
    private let emoji: ?SharedEmojiFace

    init(primary: NativeFont, faces: Array<FontFace>, warnings: Array<String>, emoji!: ?SharedEmojiFace = None) {
        this.primary = primary
        this.faces = faces
        this.warnings = warnings
        this.emoji = emoji
    }

    func acquire(): Unit {
        leases += 1
    }
    func hasColorTables(): Bool {
        for (face in faces) {
            if (face.hasColorTables()) {
                return true
            }
        }
        match (emoji) {
            case Some(face) => face.font.residentColorBytes > 0
            case None => false
        }
    }
    func colorTableBytes(seen: HashSet<UIntNative>): Int64 {
        var bytes: Int64 = 0
        for (face in faces) {
            bytes += face.colorTableBytes(seen)
        }
        if (let Some(face) <- emoji) {
            bytes += face.font.colorTableBytes(seen)
        }
        bytes
    }
    func release(): Unit {
        leases -= 1
        disposeIfUnused()
    }
    func retire(): Unit {
        retired = true
        disposeIfUnused()
    }
    private func disposeIfUnused(): Unit {
        if (!retired || leases > 0 || disposed) {
            return
        }
        disposed = true
        for (face in faces) {
            face.clearFallbacks()
        }
        for (face in faces) {
            face.close()
        }
        if (let Some(face) <- emoji) {
            face.release()
        }
    }
    func shapeCount(): UInt64 {
        var total: UInt64 = UInt64(0)
        for (face in faces) {
            total += face.shapeCount()
        }
        total
    }
    func resetShapeCount(): Unit {
        for (face in faces) {
            face.resetShapeCount()
        }
    }
}

// This font has no outgoing fallback edges and never changes size, style or coordinates.
// SDL_ttf can therefore reference it from several immutable graphs in the same renderer.
private class SharedEmojiFace {
    let font: NativeFont
    private let face: FontFace
    private var leases: Int64 = 0
    init(face: FontFace, font: NativeFont) {
        this.face = face
        this.font = font
    }
    func alive(): Bool {
        leases > 0
    }
    func acquire(): Unit {
        leases += 1
    }
    func release(): Unit {
        if (leases <= 0) {
            throw IllegalStateException("Emoji font lease already released")
        }
        leases -= 1
        if (leases == 0) {
            face.close()
        }
    }
}

/*
 * One typeface: a font file opened at whatever (size, style) combinations the UI asks for. Each
 * combination is its own TTF_Font handle with its own shaped-text cache — TTF_SetFontStyle changes
 * glyph shape and advance width, so a variant needs a distinct handle for correct measurement and
 * rendering. The default system font and every application-loaded font are each one FontFace.
 */
private class FontFace {
    private let source: NativeFontSource
    private let configured: ?NativeFontFamily
    private let engine: CPointer<Unit>
    private let fonts = ArrayList<NativeFont>()
    private var closed: Bool = false
    init(path: String, engine: CPointer<Unit>) {
        this.source = NativeFontSource(path, 0)
        this.configured = None
        this.engine = engine
    }

    init(source: NativeFontSource, engine: CPointer<Unit>, family!: ?NativeFontFamily = None) {
        this.source = source
        this.configured = family
        this.engine = engine
    }

    func sourceKey(): String {
        source.key()
    }
    func hasColorTables(): Bool {
        for (font in fonts) {
            if (font.residentColorBytes > 0) {
                return true
            }
        }
        false
    }
    func colorTableBytes(seen: HashSet<UIntNative>): Int64 {
        var bytes: Int64 = 0
        for (font in fonts) {
            bytes += font.colorTableBytes(seen)
        }
        bytes
    }

    // A font handle for the requested size and style, opened, style-set, and attached on first use
    // and cached for reuse. Throws `NativeTextException` when the file cannot be opened or the engine
    // cannot shape for it.
    func fontFor(pointSize: Float32, styleFlags: Int32): NativeFont {
        let normalized = normalizePointSize(pointSize)
        for (font in fonts) {
            if (font.styleFlags == styleFlags && font.pointSize.toBits() == normalized.toBits()) {
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

    // Explicit family faces take precedence over filename conventions. The base face remains
    // the final recovery path; decoration flags are independent of synthetic bold/italic policy.
    private func openStyled(pointSize: Float32, styleFlags: Int32): NativeFont {
        if (let Some(font) <- openMatched(pointSize, styleFlags)) {
            return font
        }
        let faceStyle = styleFlags & STYLE_FACE_MASK
        let candidates = ArrayList<NativeFontSource>()
        var synthesize = true
        match (configured) {
            case Some(family) =>
                synthesize = family.synthesize
                let explicit: ?NativeFontSource = if (faceStyle == STYLE_BOLD) {
                    family.bold
                } else if (faceStyle == STYLE_ITALIC) {
                    family.italic
                } else if (faceStyle == STYLE_FACE_MASK) {
                    family.boldItalic
                } else {
                    None
                }
                if (let Some(value) <- explicit) {
                    candidates.add(value)
                }
            case None => ()
        }
        if (source.faceIndex == 0 && faceStyle != 0) {
            for (path in styleCompanionCandidates(source.path, faceStyle)) {
                candidates.add(NativeFontSource(path, 0))
            }
        }
        for (candidate in candidates) {
            match (tryStyledCompanion(candidate, pointSize, styleFlags, faceStyle, synthesize: synthesize)) {
                case Some(font) => return font
                case None => ()
            }
        }
        // Preserve a real bold or italic face when the combined face is unavailable.
        if (faceStyle == STYLE_FACE_MASK) {
            if (let Some(font) <- openPartialStyle(pointSize, styleFlags, synthesize: synthesize)) {
                return font
            }
        }
        let synthesized = if (synthesize) {
            styleFlags
        } else {
            styleFlags & STYLE_DECORATION_MASK
        }
        openFont(source, pointSize, styleFlags, synthesized)
    }

    private func openMatched(pointSize: Float32, styleFlags: Int32): ?NativeFont {
        if (let Some(family) <- configured) {
            let faces = inspectFontCandidates(source, family)
            if (let Some(selected) <- selectNativeFont(faces, family.weight, italic: (styleFlags & STYLE_ITALIC) != 0)) {
                let synthesized = if (family.synthesize) {
                    styleFlags
                } else {
                    styleFlags & STYLE_DECORATION_MASK
                }
                return Some(
                    openFont(requestedVariableSource(selected, family, (styleFlags & STYLE_ITALIC) != 0), pointSize,
                        styleFlags, synthesized))
            }
        }
        None
    }

    private func openPartialStyle(pointSize: Float32, styleFlags: Int32, synthesize!: Bool): ?NativeFont {
        for (partial in [STYLE_BOLD, STYLE_ITALIC]) {
            let partialCandidates = ArrayList<NativeFontSource>()
            if (let Some(family) <- configured) {
                let explicit = if (partial == STYLE_BOLD) {
                    family.bold
                } else {
                    family.italic
                }
                if (let Some(value) <- explicit) {
                    partialCandidates.add(value)
                }
            }
            if (source.faceIndex == 0) {
                for (path in styleCompanionCandidates(source.path, partial)) {
                    partialCandidates.add(NativeFontSource(path, 0))
                }
            }
            for (candidate in partialCandidates) {
                match (tryStyledCompanion(candidate, pointSize, styleFlags, partial, synthesize: synthesize)) {
                    case Some(font) => return Some(font)
                    case None => ()
                }
            }
        }
        None
    }

    private func tryStyledCompanion(source: NativeFontSource, pointSize: Float32, styleFlags: Int32, faceStyle: Int32,
        synthesize!: Bool): ?NativeFont {
        try {
            let applied = if (synthesize) {
                styleFlags
            } else {
                styleFlags & STYLE_DECORATION_MASK
            }
            let font = openFont(source, pointSize, styleFlags, applied)
            // Never infer a real style solely from a filename: a renamed regular file is still regular.
            if ((font.intrinsicStyle() & faceStyle) == faceStyle) {
                return Some(font)
            }
            font.close()
            None
        } catch (_: NativeTextException) {
            None
        }
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

// A shaped text is shared by measurement and drawing, then released with its immutable font graph.
internal class ShapedText {
    let pointer: CPointer<Unit>
    init(pointer: CPointer<Unit>) {
        this.pointer = pointer
    }
}

private class NativeFont {
    let pointSize: Float32
    let residentColorBytes: Int64
    // The SDL_ttf TTF_STYLE_* bitmask baked into this handle (0 = regular). Part of the cache key
    // alongside pointSize, so bold and regular text of the same size resolve to distinct handles.
    let styleFlags: Int32
    private let font: CPointer<Unit>
    private let source: NativeFontSource
    private let originalStyle: Int32
    private let metadata: NativeInstalledFont
    private let stream: CPointer<Unit>
    private let synthesizedStyle: Int32
    private var engine = CPointer<Unit>()
    private var fallbackKey: String = ""
    // Already-shaped text objects for this size, reused across frames; a miss is the only path that
    // shapes a string. Bounded and self-freeing: an evicted object's TTF_Text is destroyed.
    private let cache: GenerationCache<String, ShapedText>
    private var cachedTextWeight: Int64 = 0
    // Shaped-text cache misses (real TTF_CreateText calls) since the last reset. No access modifier
    // so the renderer can total it as a per-frame text-cost probe.
    var shapeCount: UInt64 = 0
    private var closed: Bool = false

    init(font: CPointer<Unit>, pointSize: Float32, styleFlags: Int32, syntheticFlags: Int32, source: NativeFontSource,
        stream: CPointer<Unit>) {
        this.font = font
        this.pointSize = pointSize
        this.styleFlags = styleFlags
        this.source = source
        this.stream = stream
        let intrinsic = unsafe { TTF_GetFontStyle(font) }
        this.metadata = sfntSourceInfo(source)
        var colorBytes: Int64 = 0
        for (table in sfntFile(source.path).faces[source.faceIndex & 65535].tables) {
            if (table.tagCode == SFNT_COLOR_LAYERS || table.tagCode == SFNT_COLOR_PALETTE) {
                colorBytes += table.length
            }
        }
        this.residentColorBytes = colorBytes
        this.originalStyle = intrinsic | metadata.styleFlags
        this.synthesizedStyle = syntheticFlags & (0x0F ^ originalStyle)
        // Preserve styles intrinsic to the opened face, and add only the requested synthesis.
        // This also avoids double slanting a registered real italic face.
        if (syntheticFlags != 0) {
            unsafe { TTF_SetFontStyle(font, intrinsic | synthesizedStyle) }
        }
        this.cache = GenerationCache<String, ShapedText>(SHAPED_TEXT_CACHE_CAP) {
            shaped => if (shaped.pointer.isNotNull()) {
                destroyNativeText(shaped.pointer)
            }
        }
    }

    /**
     * Binds this font to the shared text engine and fails fast — as the previous eager text object
     * did — if the engine cannot shape for it. Throws `NativeTextException` on failure.
     */
    func attach(engine: CPointer<Unit>): Unit {
        this.engine = engine
        registerNativeEngineFont(engine, font, source, pointSize, synthesizedStyle)
        let probe = createNativeText(engine, font, CString(CPointer<UInt8>()), UIntNative(0))
        if (probe.isNull()) {
            throw NativeTextException("TTF_CreateText failed: ${lastNativeError()}")
        }
        try {
            let _ = nativeEngineEntry(probe) // cjcheck-ignore: ignore-result # this probe validates construction; its empty layout is intentionally discarded
        } finally {
            destroyNativeText(probe)
        }
    }

    /**
     * Draws `text` at (x, y) in `color`, reusing a cached shaped-text object so an unchanged string
     * is not re-shaped by SDL_ttf — only a cache miss shapes. Throws `NativeTextException` on failure.
     */
    func drawText(text: String, x: Float32, y: Float32, color: NativeTextColor): Unit {
        let shaped = obtainShaped(text)
        let transient = shapedTextWeight(text) > SHAPED_TEXT_BYTE_BUDGET
        try {
            drawShaped(shaped, x, y, color)
        } finally {
            if (transient) {
                destroyNativeText(shaped.pointer)
            }
        }
    }

    private func drawShaped(shaped: ShapedText, x: Float32, y: Float32, color: NativeTextColor): Unit {
        drawNativeEngineText(shaped.pointer, x, y, color)
    }

    func measureText(text: String): NativeTextMetrics {
        let shaped = obtainShaped(text)
        try {
            nativeEngineEntry(shaped.pointer).layout.metrics
        } finally {
            if (shapedTextWeight(text) > SHAPED_TEXT_BYTE_BUDGET) {
                destroyNativeText(shaped.pointer)
            }
        }
    }

    func rasterText(text: String, color: ?NativeTextColor): NativeTextSurface {
        let shaped = obtainShaped(text)
        try {
            let layout = nativeEngineEntry(shaped.pointer).layout
            let state = nativeTextEngine(engine)
            nativeEngineColorSurface(layout, state, color)
        } finally {
            if (shapedTextWeight(text) > SHAPED_TEXT_BYTE_BUDGET) {
                destroyNativeText(shaped.pointer)
            }
        }
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
            pointer = createNativeText(engine, font, textResource.value, UIntNative(text.size))
        }
        if (pointer.isNull()) {
            throw NativeTextException("TTF_CreateText failed: ${lastNativeError()}")
        }
        shapeCount += 1
        let shaped = ShapedText(pointer)
        let weight = shapedTextWeight(text)
        if (weight <= SHAPED_TEXT_BYTE_BUDGET) {
            if (cachedTextWeight + weight > SHAPED_TEXT_BYTE_BUDGET) {
                cache.clear()
                cachedTextWeight = 0
            }
            cache.put(text, shaped)
            cachedTextWeight += weight
        }
        shaped
    }

    private func shapedTextWeight(text: String): Int64 {
        // Conservative host/native layout estimate, not a promise about SDL's atlas/driver storage.
        text.size * ESTIMATED_SHAPED_BYTES_PER_UTF8_BYTE + SHAPED_TEXT_ENTRY_OVERHEAD
    }

    func intrinsicStyle(): Int32 {
        originalStyle
    }

    func info(): NativeFontInfo {
        let actual = NativeFontSource(source.path, source.faceIndex, coordinates: metadata.coordinates)
        NativeFontInfo(actual, metadata.familyName, metadata.styleName, synthesizedStyle, weight: metadata.weight)
    }

    func lineMetrics(): NativeLineMetrics {
        NativeLineMetrics(Float32(unsafe { TTF_GetFontAscent(font) }), Float32(-unsafe { TTF_GetFontDescent(font) }),
            Float32(unsafe { TTF_GetFontHeight(font) }), Float32(unsafe { TTF_GetFontLineSkip(font) }))
    }

    func pointer(): CPointer<Unit> {
        font
    }
    func colorTableBytes(seen: HashSet<UIntNative>): Int64 {
        if (residentColorBytes > 0 && seen.add(font.toUIntNative())) {
            residentColorBytes
        } else {
            Int64(0)
        }
    }

    func configureFallbacks(key: String, fallbacks: ArrayList<NativeFont>): Unit {
        if (fallbackKey == key) {
            return
        }
        clearFallbacks()
        for (fallback in fallbacks) {
            ensureNative(unsafe { TTF_AddFallbackFont(font, fallback.pointer()) }, "TTF_AddFallbackFont")
        }
        nativeTextEngine(engine).fallbacks[font.toUIntNative()] = Array<CPointer<Unit>>(fallbacks.size) {
            i => fallbacks[i].pointer()
        }
        fallbackKey = key
    }

    func clearFallbacks(): Unit {
        unsafe { TTF_ClearFallbackFonts(font) }
        if (engine.isNotNull()) {
            let _ = nativeTextEngine(engine).fallbacks.remove(font.toUIntNative()) // cjcheck-ignore: ignore-result # clearing a font without registered fallbacks is valid
        }
        fallbackKey = ""
    }

    func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        clearFallbacks()
        cache.clear()
        forgetNativeEngineFont(engine, font)
        unsafe { TTF_CloseFont(font) }
        if (stream.isNotNull()) {
            let _ = closeFontView(stream) // cjcheck-ignore: ignore-result # final release of a read-only font memory stream has no pending data to flush
        }
    }
}

// The first system-font candidate that SDL_ttf can open, probed by opening then immediately closing
// it. The default face reopens it lazily per size; this only settles which path to use.
private func findBootstrapFont(sources: Array<NativeFontSource>): ?NativeFontSource {
    for (source in sources) {
        try {
            let font = openFont(source, DEFAULT_POINT_SIZE, 0, 0)
            font.close()
            return source
        } catch (_: NativeTextException) {
            // Bootstrap is an ordered recovery chain; exhaust it before reporting that no font is usable.
            continue
        }
    }
    None
}

/** Cheap explicit-source bootstrap probe; avoids a system catalog scan for a supplied application font. */
protected func canOpenNativeFont(source: NativeFontSource): Bool {
    if (!unsafe { TTF_Init() }) {
        return false
    }
    try {
        findBootstrapFont([source]).isSome()
    } finally {
        unsafe { TTF_Quit() }
    }
}

/**
 * Throws `NativeTextException` when SDL_ttf cannot open the selected system font.
 */
private func openFont(source: NativeFontSource, pointSize: Float32, styleFlags: Int32, syntheticFlags: Int32): NativeFont {
    var font = CPointer<Unit>()
    var stream = CPointer<Unit>()
    if (!source.coordinates.isEmpty()) {
        let opened = openVariableNativeFont(source, pointSize)
        font = opened[0]
        stream = opened[1]
    } else {
        let cPath = unsafe { LibC.mallocCString(source.path) }
        try (pathResource = cPath.asResource()) {
            font = if (source.faceIndex == 0) {
                unsafe { TTF_OpenFont(pathResource.value, pointSize) }
            } else {
                openCollectionFace(pathResource.value, source.faceIndex, pointSize)
            }
        }
    }
    if (font.isNull()) {
        throw NativeTextException("TTF_OpenFont failed: ${lastNativeError()}")
    }
    try {
        NativeFont(font, pointSize, styleFlags, syntheticFlags, source, stream)
    } catch (error: Exception) {
        unsafe { TTF_CloseFont(font) }
        if (stream.isNotNull()) {
            let _ = closeFontView(stream) // cjcheck-ignore: ignore-result # final release of a read-only font memory stream has no pending data to flush
        }
        throw error
    }
}

internal func openCollectionFace(path: CString, index: Int64, pointSize: Float32): CPointer<Unit> {
    let props = unsafe { SDL_CreateProperties() }
    if (props == UInt32(0)) {
        throw NativeTextException("SDL_CreateProperties failed: ${lastNativeError()}")
    }
    var result = CPointer<Unit>()
    try {
        let filenameKey = unsafe { LibC.mallocCString("SDL_ttf.font.create.filename") }
        let sizeKey = unsafe { LibC.mallocCString("SDL_ttf.font.create.size") }
        let faceKey = unsafe { LibC.mallocCString("SDL_ttf.font.create.face") }
        try (fileResource = filenameKey.asResource(), sizeResource = sizeKey.asResource(), faceResource = faceKey
            .asResource()) {
            ensureNative(unsafe { SDL_SetStringProperty(props, fileResource.value, path) }, "SDL_SetStringProperty")
            ensureNative(unsafe { SDL_SetFloatProperty(props, sizeResource.value, pointSize) }, "SDL_SetFloatProperty")
            ensureNative(unsafe { SDL_SetNumberProperty(props, faceResource.value, index) }, "SDL_SetNumberProperty")
            result = unsafe { TTF_OpenFontWithProperties(props) }
        }
    } finally {
        unsafe { SDL_DestroyProperties(props) }
    }
    result
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

protected func styleCompanionCandidates(path: String, style: Int32): Array<String> {
    if (style == STYLE_BOLD) {
        return boldCompanionCandidates(path)
    }
    let (stem, ext) = splitFontExt(path)
    if (ext.isEmpty()) {
        return []
    }
    let suffix = if (style == STYLE_ITALIC) {
        "Italic"
    } else {
        "BoldItalic"
    }
    let out = ArrayList<String>()
    if (stem.endsWith("-Regular")) {
        out.add(stem[0..stem.size - 8] + "-" + suffix + ext)
    }
    if (stem.endsWith("Regular")) {
        out.add(stem[0..stem.size - 7] + suffix + ext)
    }
    if (stem.endsWith("segoeui") && style == STYLE_FACE_MASK) {
        out.add(stem[0..stem.size - 7] + "segoeuiz" + ext)
    }
    if (stem.endsWith("calibri") || stem.endsWith("cambria") || stem.endsWith("georgia") || stem.endsWith("verdana")) {
        if (style == STYLE_FACE_MASK) {
            out.add(stem + "z" + ext)
        }
    }
    out.add(stem + (if (style == STYLE_ITALIC) {
        "i"
    } else {
        "bi"
    }) + ext)
    out.add(stem + "-" + suffix + ext)
    out.add(stem + suffix + ext)
    out.toArray()
}

protected func nativeSystemFontCandidates(): Array<NativeFontSource> {
    let windows = getVariable("WINDIR").getOrDefault({=> "C:/Windows"})
    let paths = [
        windows + "/Fonts/msyh.ttc",
        windows + "/Fonts/segoeui.ttf",
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/SFNS.ttf",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    ]
    Array<NativeFontSource>(paths.size) {i => NativeFontSource(paths[i], 0)}
}

private func normalizePointSize(pointSize: Float32): Float32 {
    normalizeFontPointSize(pointSize)
}

/**
 * Throws `NativeTextException` when an SDL_ttf operation reports failure.
 */
private func ensureNative(ok: Bool, api: String): Unit {
    if (!ok) {
        throw NativeTextException("${api} failed: ${lastNativeError()}")
    }
}

internal func lastNativeError(): String {
    let error = unsafe { SDL_GetError() }
    if (error.isNull()) {
        "unknown SDL_ttf error"
    } else {
        error.toString()
    }
}
