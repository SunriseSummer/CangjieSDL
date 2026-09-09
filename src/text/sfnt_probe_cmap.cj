package sdl.text

// Calibration maps private-use codepoints directly to final glyph IDs, with GSUB/GPOS disabled.
// It never changes the application's font or shapes real text, so ligatures and contextual forms
// selected by the original layout remain intact. Noncharacters at plane ends are avoided.
internal let PROBE_GLYPH_BASE: UInt32 = 0xF0000
private let SFNT_MAX_GLYPHS: Int64 = 65535
private let CMAP_PREFIX_BYTES: Int64 = 28
private let CMAP_GROUP_BYTES: Int64 = 12
private let CMAP_SUBTABLE_BYTES: Int64 = 16
private let CMAP_GROUP_COUNT_FIELD: Int64 = 24
private let PROBE_PLANE_CAPACITY: Int64 = 65534
private let PROBE_LAST_CODEPOINT: UInt32 = 0xE000

internal func sfntGlyphProbeCmap(count: Int64): Array<UInt8> {
    if (count < 1 || count > SFNT_MAX_GLYPHS) {
        throw NativeTextException("Invalid glyph count for font probe")
    }
    let groups: Int64 = if (count > PROBE_PLANE_CAPACITY) {
        2
    } else {
        1
    }
    let bytes = Array<UInt8>(CMAP_PREFIX_BYTES + groups * CMAP_GROUP_BYTES, repeat: 0)
    sfntPut16(bytes, 2, 1);
    sfntPut16(bytes, 4, 3);
    sfntPut16(bytes, 6, 10)
    sfntPut32(bytes, 8, UInt32(CMAP_GROUP_BYTES));
    sfntPut16(bytes, CMAP_GROUP_BYTES, CMAP_GROUP_BYTES)
    sfntPut32(bytes, CMAP_SUBTABLE_BYTES, UInt32(CMAP_SUBTABLE_BYTES + groups * CMAP_GROUP_BYTES));
    sfntPut32(bytes, CMAP_GROUP_COUNT_FIELD, UInt32(groups))
    var start = CMAP_PREFIX_BYTES
    if (groups == 2) {
        sfntPut32(bytes, start, PROBE_LAST_CODEPOINT);
        sfntPut32(bytes, start + 4, PROBE_LAST_CODEPOINT)
        sfntPut32(bytes, start + 8, UInt32(PROBE_PLANE_CAPACITY));
        start += CMAP_GROUP_BYTES
    }
    sfntPut32(bytes, start, PROBE_GLYPH_BASE)
    sfntPut32(bytes, start + 4, PROBE_GLYPH_BASE + UInt32(min(count, PROBE_PLANE_CAPACITY)) - 1)
    sfntPut32(bytes, start + 8, 0)
    bytes
}

internal func glyphProbeCodepoint(glyph: UInt32): UInt32 {
    if (glyph < UInt32(PROBE_PLANE_CAPACITY)) {
        PROBE_GLYPH_BASE + glyph
    } else {
        PROBE_LAST_CODEPOINT
    }
}

internal func glyphProbeString(glyph: UInt32): String {
    Rune(glyphProbeCodepoint(glyph)).toString()
}
