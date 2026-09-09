package sdl.text

// Unicode 17.0.0 UAX #29, rules GB3..GB13. Properties come from the pinned UCD.
private let GCB_CR: UInt32 = 1
private let GCB_LF: UInt32 = 2
private let GCB_CONTROL: UInt32 = 3
private let GCB_EXTEND: UInt32 = 4
private let GCB_ZWJ: UInt32 = 5
private let GCB_RI: UInt32 = 6
private let GCB_PREPEND: UInt32 = 7
private let GCB_SPACING: UInt32 = 8
private let GCB_L: UInt32 = 9
private let GCB_V: UInt32 = 10
private let GCB_T: UInt32 = 11
private let GCB_LV: UInt32 = 12
private let GCB_LVT: UInt32 = 13
private let GCB_MASK: UInt32 = 0x0F
private let INCB_MASK: UInt32 = 0x30
private let INCB_CONSONANT: UInt32 = 0x10
private let INCB_EXTEND: UInt32 = 0x20
private let INCB_LINKER: UInt32 = 0x30
private let EXTENDED_PICTOGRAPHIC: UInt32 = 0x40
private let HANGUL_START: UInt32 = 0xAC00
private let HANGUL_END: UInt32 = 0xD7A3
private let HANGUL_T_COUNT: UInt32 = 28
private let GRAPHEME_TABLES = [GRAPHEME_DATA_0, GRAPHEME_DATA_1, GRAPHEME_DATA_2, GRAPHEME_DATA_3, GRAPHEME_DATA_4]

internal class GraphemeBoundaryMachine {
    private var previous: UInt32 = 0
    private var regionalOdd = false
    private var pictographicRun = false
    private var pictographicZwj = false
    private var indicRun = false
    private var indicLinker = false

    func consume(codePoint: UInt32): Bool {
        let properties = graphemeProperties(codePoint)
        let current = properties & GCB_MASK
        let indic = properties & INCB_MASK
        let pictographic = (properties & EXTENDED_PICTOGRAPHIC) != 0
        let boundary = breaksBefore(current, indic, pictographic)
        pictographicZwj = current == GCB_ZWJ && pictographicRun
        pictographicRun = pictographic || (current == GCB_EXTEND && pictographicRun)
        if (indic == INCB_CONSONANT) {
            indicRun = true
            indicLinker = false
        } else if (indic == INCB_LINKER || indic == INCB_EXTEND) {
            indicLinker = indicRun && (indicLinker || indic == INCB_LINKER)
        } else {
            indicRun = false
            indicLinker = false
        }
        regionalOdd = current == GCB_RI && (previous != GCB_RI || !regionalOdd)
        previous = current
        boundary
    }

    private func breaksBefore(current: UInt32, indic: UInt32, pictographic: Bool): Bool {
        if (previous == GCB_CR && current == GCB_LF) {
            return false
        }
        if (isGraphemeControl(previous) || isGraphemeControl(current)) {
            return true
        }
        if (previous == GCB_L && (current == GCB_L || current == GCB_V || current == GCB_LV || current == GCB_LVT)) {
            return false
        }
        if ((previous == GCB_LV || previous == GCB_V) && (current == GCB_V || current == GCB_T)) {
            return false
        }
        if ((previous == GCB_LVT || previous == GCB_T) && current == GCB_T) {
            return false
        }
        if (current == GCB_EXTEND || current == GCB_ZWJ || current == GCB_SPACING || previous == GCB_PREPEND) {
            return false
        }
        if (indic == INCB_CONSONANT && indicRun && indicLinker) {
            return false
        }
        if (pictographic && pictographicZwj) {
            return false
        }
        if (previous == GCB_RI && current == GCB_RI && regionalOdd) {
            return false
        }
        true
    }
}

private func isGraphemeControl(value: UInt32): Bool {
    value == GCB_CR || value == GCB_LF || value == GCB_CONTROL
}

internal func graphemeProperties(codePoint: UInt32): UInt32 {
    if (codePoint >= HANGUL_START && codePoint <= HANGUL_END) {
        return if ((codePoint - HANGUL_START) % HANGUL_T_COUNT == 0) {
            GCB_LV
        } else {
            GCB_LVT
        }
    }
    for (table in GRAPHEME_TABLES) {
        if (codePoint <= table[table.size - 1][1]) {
            return propertyFromRanges(table, codePoint)
        }
    }
    0
}

private func propertyFromRanges(ranges: Array<(UInt32, UInt32, UInt32)>, codePoint: UInt32): UInt32 {
    var lower: Int64 = 0
    var upper = ranges.size
    while (lower < upper) {
        let middle = lower + (upper - lower) / 2
        let (start, end, value) = ranges[middle]
        if (codePoint < start) {
            upper = middle
        } else if (codePoint > end) {
            lower = middle + 1
        } else {
            return value
        }
    }
    0
}
