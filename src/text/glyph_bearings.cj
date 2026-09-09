package sdl.text

import std.collection.{ArrayList, HashMap}

private let GLYPH_SAMPLE_ENTRIES: Int64 = 256
private let GLYPH_SAMPLE_BYTE_BUDGET: Int64 = 16 * 1024
private let GLYPH_BEARING_ENTRIES: Int64 = 4096
private let GLYPH_PROBE_BATCH: Int64 = 128
private let LARGE_COLOR_TABLE_BYTES: Int64 = 1024 * 1024

internal class GlyphProbeReleases {
    private let pending = ArrayList<GlyphRasterSource>()
    func add(source: GlyphRasterSource): Unit {
        pending.add(source)
    }
    func flush(): Unit {
        for (source in pending) {
            source.releaseQueuedProbe()
        }
        pending.clear()
    }
}

internal struct GlyphBearing {
    let x: Int32
    let y: Int32
    init(x!: Int32 = 0, y!: Int32 = 0) {
        this.x = x
        this.y = y
    }
}

// SDL 3.2's public copy operations use pre-synthesis bearings, while glyph images use the
// transformed outline bearings. A tiny cmap-only probe exposes the final glyph ID through public
// APIs, so no private FreeType/TTF_Font memory is read and no real shaping run is split.
internal class GlyphRasterSource {
    let color: Bool
    private let source: NativeFontSource
    private let size: Float32
    private let style: Int32
    private let bearings = HashMap<UInt32, GlyphBearing>()
    private let samples = HashMap<UInt32, String>()
    private var sampleBytes: Int64 = 0
    private let original: CPointer<Unit>
    private let acceptsSamples: Bool
    private let largeColor: Bool
    private let releases: ?GlyphProbeReleases
    private var queued = false
    private var font = CPointer<Unit>()
    private var stream = CPointer<Unit>()
    private var probes: Int64 = 0
    init(source: NativeFontSource, size: Float32, style: Int32, original!: CPointer<Unit> = CPointer<Unit>(),
        releases!: ?GlyphProbeReleases = None) {
        this.source = source
        this.size = size
        this.style = style & 3
        this.original = original
        this.releases = releases
        var color = false
        var large = false
        for (table in sfntFile(source.path).faces[source.faceIndex & 65535].tables) {
            let colored = table.tagCode == SFNT_COLOR_LAYERS || table.tagCode == SFNT_COLOR_BITMAP || table.tagCode ==
                SFNT_APPLE_BITMAP || table.tagCode == SFNT_SVG_OUTLINES
            color = color || colored
            large = large || (colored && table.length >= LARGE_COLOR_TABLE_BYTES)
        }
        this.largeColor = large
        this.color = color
        this.acceptsSamples = original.isNotNull() && ((style & 2) != 0 || color)
    }

    func needsSample(glyph: UInt32): Bool {
        acceptsSamples && !bearings.contains(glyph) && !samples.contains(glyph)
    }

    func rememberSample(glyph: UInt32, text: String, offset: Int64, length: Int64): Unit {
        if (!needsSample(glyph) || length <= 0 || length > GLYPH_SAMPLE_MAX_BYTES || offset < 0 || offset > text.size -
            length) {
            return
        }
        if (samples.size >= GLYPH_SAMPLE_ENTRIES || sampleBytes + length > GLYPH_SAMPLE_BYTE_BUDGET) {
            samples.clear()
            sampleBytes = 0
        }
        // Own only the bounded sample bytes; do not retain a slice of a large paragraph.
        samples[glyph] = String.fromUtf8(Array<UInt8>(length) {i => text[offset + i]})
        sampleBytes += length
    }

    func bearing(glyph: UInt32, image: CPointer<Unit>, color: Bool): GlyphBearing {
        if ((style & 2) == 0 && !color) {
            return GlyphBearing()
        }
        if (let Some(value) <- bearings.get(glyph)) {
            return value
        }
        if (let Some(sample) <- samples.remove(glyph)) {
            sampleBytes -= sample.size
            if (let Some(value) <- sampleGlyphBearing(original, glyph, sample, image)) {
                rememberBearing(glyph, value)
                return value
            }
        }
        if (font.isNull()) {
            let metadata = sfntSourceInfo(source)
            let view = SfntView(source, metadata, glyphProbe: true)
            let (opened, io) = openNativeFontView(source.path, size, view, if (metadata.axes.isEmpty()) {
                0
            } else {
                65536
            })
            font = opened
            stream = io
            let intrinsic = unsafe { TTF_GetFontStyle(font) }
            unsafe { TTF_SetFontStyle(font, intrinsic | style) }
            if (largeColor && !queued) {
                if (let Some(queue) <- releases) {
                    queue.add(this)
                    queued = true
                }
            }
        }
        let value = try {
            calibrateGlyphBearing(font, glyph, image)
        } catch (error: Exception) {
            throw NativeTextException("${error.message}; ${source.path}, glyph ${glyph}, size ${size}, style ${style}")
        }
        rememberBearing(glyph, value)
        probes += 1
        // Keep numeric corrections, not a second unbounded native glyph cache.
        if (probes >= GLYPH_PROBE_BATCH) {
            close()
        }
        value
    }

    func releaseQueuedProbe(): Unit {
        close()
        queued = false
    }

    private func rememberBearing(glyph: UInt32, value: GlyphBearing): Unit {
        if (bearings.size >= GLYPH_BEARING_ENTRIES) {
            bearings.clear()
        }
        bearings[glyph] = value
    }

    func close(): Unit {
        if (font.isNotNull()) {
            unsafe { TTF_CloseFont(font) };
            font = CPointer<Unit>()
        }
        if (stream.isNotNull()) {
            let _ = closeFontView(stream) // cjcheck-ignore: ignore-result # read-only stream is always released; no buffered writes to recover
            stream = CPointer<Unit>()
        }
        probes = 0
    }
}

private func calibrateGlyphBearing(font: CPointer<Unit>, glyph: UInt32, image: CPointer<Unit>): GlyphBearing {
    let value = glyphProbeString(glyph)
    let encoded = unsafe { LibC.mallocCString(value) }
    var rendered = CPointer<Unit>()
    try (resource = encoded.asResource()) {
        var width: Int32 = 0;
        var height: Int32 = 0
        if (!unsafe { TTF_GetStringSize(font, resource.value, UIntNative(value.size), inout width, inout height) } ||
            width < 1 || height < 1 || width > GLYPH_ATLAS_MAX_SIDE || height > GLYPH_ATLAS_MAX_SIDE) {
            throw NativeTextException("Font bearing probe exceeds the glyph raster budget")
        }
        rendered = unsafe { TTF_RenderText_Blended(font, resource.value, UIntNative(value.size), 0xFFFFFFFF) }
    }
    if (rendered.isNull()) {
        throw NativeTextException("Cannot probe glyph bitmap bearings: ${lastNativeError()}")
    }
    try {
        var minX: Int32 = 0;
        var maxX: Int32 = 0;
        var minY: Int32 = 0;
        var maxY: Int32 = 0;
        var advance: Int32 = 0
        if (!unsafe { TTF_GetGlyphMetrics(font, glyphProbeCodepoint(glyph), inout minX, inout maxX, inout minY,
            inout maxY, inout advance) }) {
            throw NativeTextException("Cannot measure glyph bearing probe")
        }
        let glyphImage = unsafe { CPointer<EngineSurface>(image).read() }
        let probe = unsafe { CPointer<EngineSurface>(rendered).read() }
        let offset = locateGlyphBitmap(glyphImage, probe)
        let ascent = unsafe { TTF_GetFontAscent(font) }
        GlyphBearing(x: offset.x - max(Int32(0), -minX) - minX, y: offset.y - max(Int32(0), maxY - ascent) - ascent +
            maxY)
    } finally {
        unsafe { SDL_DestroySurface(rendered) }
    }
}

private func alphaBounds(image: EngineSurface): TtfSubstringRect {
    var left = image.width;
    var right: Int32 = 0;
    var top = image.height;
    var bottom: Int32 = 0
    for (y in 0..Int64(image.height)) {
        let row = unsafe { CPointer<UInt32>(CPointer<UInt8>(image.pixels) + y * Int64(image.pitch)) }
        for (x in 0..Int64(image.width)) {
            if ((unsafe { row.read(x) } >> 24) != 0) {
                left = min(left, Int32(x))
                right = max(right, Int32(x) + 1)
                top = min(top, Int32(y))
                bottom = max(bottom, Int32(y) + 1)
            }
        }
    }
    if (right <= left || bottom <= top) {
        return TtfSubstringRect()
    }
    engineRect(left, top, right - left, bottom - top)
}

private func locateGlyphBitmap(glyph: EngineSurface, probe: EngineSurface): GlyphBearing {
    match (findGlyphBitmap(glyph, probe)) {
        case Some(value) => value
        case None => throw NativeTextException("Glyph bearing probe did not reproduce the original bitmap")
    }
}

internal func findGlyphBitmap(glyph: EngineSurface, probe: EngineSurface, complete!: Bool = false): ?GlyphBearing {
    let source = alphaBounds(glyph);
    let target = alphaBounds(probe)
    if (source.w == 0 || target.w == 0) {
        return if (source.w == 0 && target.w == 0) {
            Some(GlyphBearing())
        } else {
            None
        }
    }
    if (complete && (source.w != target.w || source.h != target.h)) {
        return None
    }
    let xs = [target.x - source.x, target.x + target.w - source.x - source.w]
    let ys = [target.y - source.y, target.y + target.h - source.y - source.h]
    for (x in xs) {
        for (y in ys) {
            if (glyphPlacementMatches(glyph, probe, x, y)) {
                return Some(GlyphBearing(x: x, y: y))
            }
        }
    }
    None
}

private func glyphPlacementMatches(glyph: EngineSurface, probe: EngineSurface, dx: Int32, dy: Int32): Bool {
    for (y in 0..Int64(probe.height)) {
        let row = unsafe { CPointer<UInt32>(CPointer<UInt8>(probe.pixels) + y * Int64(probe.pitch)) }
        let sourceY = y - Int64(dy)
        for (x in 0..Int64(probe.width)) {
            let sourceX = x - Int64(dx)
            var alpha: Int64 = 0
            if (sourceX >= 0 && sourceX < Int64(glyph.width) && sourceY >= 0 && sourceY < Int64(glyph.height)) {
                let source = unsafe { CPointer<UInt32>(CPointer<UInt8>(glyph.pixels) + sourceY * Int64(glyph.pitch)) }
                alpha = Int64(unsafe { source.read(sourceX) } >> 24)
            }
            let wanted = Int64(unsafe { row.read(x) } >> 24)
            if (alpha != wanted) {
                return false
            }
        }
    }
    true
}
