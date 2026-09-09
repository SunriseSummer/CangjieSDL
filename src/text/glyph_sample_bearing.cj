package sdl.text

import std.collection.HashMap

internal let GLYPH_SAMPLE_MAX_BYTES: Int64 = 128
private let SAMPLE_PREFIX_ATTEMPTS: Int64 = 8
private let FONT_DECORATION_FLAGS: Int32 = 12
private let UTF8_CONTINUATION_MASK: UInt8 = 0xC0
private let UTF8_CONTINUATION_BITS: UInt8 = 0x80
private let SAMPLE_INK_WHITE: UInt32 = 0xFFFFFFFF

// Created only for layouts needing uncached color/italic bearings. Ordinary text does not
// allocate this map or copy its UTF-8 buffer.
internal class GlyphSampleClusters {
    private let text: String
    private let lengths = HashMap<Int32, Int32>()
    init(text: CString, clusters: Array<TtfSubstring>) {
        this.text = unsafe { text.toString() }
        for (cluster in clusters) {
            if (cluster.length > 0) {
                lengths[cluster.offset] = cluster.length
            }
        }
    }
    func remember(source: GlyphRasterSource, operation: EngineCopy): Unit {
        if (let Some(length) <- lengths.get(operation.textOffset)) {
            source.rememberSample(operation.glyph, text, Int64(operation.textOffset), Int64(length))
        }
    }
}

// Reuse the original font when a bounded cluster reproduces exactly one shaped glyph.
// The public text-engine operations give the pre-raster position; the official surface gives
// the actual bitmap position. A mismatch falls back to glyph-ID calibration without changing
// the original font, its fallbacks, or the application's shaping run.
internal func sampleGlyphBearing(font: CPointer<Unit>, glyph: UInt32, sample: String, image: CPointer<Unit>): ?GlyphBearing {
    if (font.isNull() || sample.isEmpty() || sample.size > GLYPH_SAMPLE_MAX_BYTES ||
        (unsafe { TTF_GetFontStyle(font) } & FONT_DECORATION_FLAGS) != 0) {
        return None
    }
    if (let Some(value) <- singleSampleBearing(font, glyph, sample, image)) {
        return Some(value)
    }
    // SDL fallback spans can end inside a cluster (for example before a ZWJ). Try bounded
    // UTF-8 prefixes, accepting only the original glyph ID and an exact raster match.
    var end = sample.size - 1
    var attempts: Int64 = 0
    while (end > 0 && attempts < SAMPLE_PREFIX_ATTEMPTS) {
        if ((sample[end] & UTF8_CONTINUATION_MASK) != UTF8_CONTINUATION_BITS) {
            attempts += 1
            if (let Some(value) <- singleSampleBearing(font, glyph, sample[0..end], image)) {
                return Some(value)
            }
        }
        end -= 1
    }
    None
}

private func singleSampleBearing(font: CPointer<Unit>, glyph: UInt32, sample: String, image: CPointer<Unit>): ?GlyphBearing {
    let encoded = unsafe { LibC.mallocCString(sample) }
    try (resource = encoded.asResource()) {
        let text = unsafe { TTF_CreateText(CPointer<Unit>(), font, resource.value, UIntNative(sample.size)) }
        if (text.isNull()) {
            throw NativeTextException("Cannot create glyph sample layout: ${lastNativeError()}")
        }
        try {
            if (!unsafe { TTF_UpdateText(text) }) {
                throw NativeTextException("Cannot update glyph sample layout: ${lastNativeError()}")
            }
            let data = unsafe { CPointer<EngineText>(text).read().data.read() }
            if (data.operationCount != 1 || data.operations.isNull() || data.width < 1 || data.height < 1 ||
                data.width > GLYPH_ATLAS_MAX_SIDE || data.height > GLYPH_ATLAS_MAX_SIDE) {
                return None
            }
            let operation = unsafe { data.operations.read() }
            if (operation.command != 2 || operation.glyph != glyph || operation.font.toUIntNative() !=
                font.toUIntNative()) {
                return None
            }
            let rendered = unsafe { TTF_RenderText_Blended(font, resource.value, UIntNative(sample.size),
                SAMPLE_INK_WHITE) }
            if (rendered.isNull()) {
                throw NativeTextException("Cannot render glyph sample: ${lastNativeError()}")
            }
            try {
                let offset = findGlyphBitmap(unsafe { CPointer<EngineSurface>(image).read() },
                    unsafe { CPointer<EngineSurface>(rendered).read() }, complete: true)
                let result: ?GlyphBearing = match (offset) {
                    case Some(value) => Some(
                        GlyphBearing(x: value.x - operation.destination.x + operation.source.x,
                            y: value.y - operation.destination.y + operation.source.y))
                    case None => None
                }
                return result
            } finally {
                unsafe { SDL_DestroySurface(rendered) }
            }
        } finally {
            unsafe { TTF_DestroyText(text) }
        }
    }
    None
}
