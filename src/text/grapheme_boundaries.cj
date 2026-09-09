package sdl.text

import std.collection.ArrayList

private let TEXT_PRESENTATION_SELECTOR: UInt32 = 0xFE0E
private let EMOJI_PRESENTATION_SELECTOR: UInt32 = 0xFE0F
private let EMOJI_KEYCAP_MARK: UInt32 = 0x20E3
private let EMOJI_ZERO_WIDTH_JOINER: UInt32 = 0x200D
private let GRAPHEME_EMOJI: UInt32 = 0x100
private let GRAPHEME_EMOJI_PRESENTATION: UInt32 = 0x80
private let GRAPHEME_PICTOGRAPHIC: UInt32 = 0x40

/** Unicode 17 extended-grapheme boundaries in rune indices, including zero and the end. */
public func graphemeRuneBoundaries(runes: Array<Rune>): Array<Int64> {
    let boundaries = ArrayList<Int64>()
    boundaries.add(0)
    let machine = GraphemeBoundaryMachine()
    for (i in 0..runes.size) {
        let boundary = machine.consume(UInt32(runes[i]))
        if (i > 0 && boundary) {
            boundaries.add(i)
        }
    }
    if (!runes.isEmpty()) {
        boundaries.add(runes.size)
    }
    boundaries.toArray()
}

/** Unicode 17 extended-grapheme boundaries in UTF-8 bytes; empty text returns [0]. */
public func graphemeByteBoundaries(text: String): Array<Int64> {
    let boundaries = ArrayList<Int64>()
    boundaries.add(0)
    let machine = GraphemeBoundaryMachine()
    var offset: Int64 = 0
    for (rune in text.runes()) {
        let code = UInt32(rune)
        let boundary = machine.consume(code)
        if (offset > 0 && boundary) {
            boundaries.add(offset)
        }
        offset += graphemeUtf8Length(code)
    }
    if (offset > 0) {
        boundaries.add(offset)
    }
    boundaries.toArray()
}

internal func graphemeUtf8Length(code: UInt32): Int64 {
    if (code <= 0x7F) {
        1
    } else if (code <= 0x7FF) {
        2
    } else if (code <= 0xFFFF) {
        3
    } else {
        4
    }
}

// Presentation selectors apply to their cluster, never to neighboring text. Emoji_Presentation
// and Emoji come from the same pinned UCD as the boundary machine (not broad symbol ranges).
internal func emojiPresentationCluster(text: String): Bool {
    var defaultEmoji = false
    var emojiBase = false
    var selector = false
    var joiner = false
    var pictographic = false
    for (rune in text.runes()) {
        let code = UInt32(rune)
        if (code == TEXT_PRESENTATION_SELECTOR) {
            return false
        }
        let properties = graphemeProperties(code)
        defaultEmoji = defaultEmoji || (properties & GRAPHEME_EMOJI_PRESENTATION) != 0
        emojiBase = emojiBase || (properties & GRAPHEME_EMOJI) != 0
        pictographic = pictographic || (properties & GRAPHEME_PICTOGRAPHIC) != 0
        selector = selector || code == EMOJI_PRESENTATION_SELECTOR || code == EMOJI_KEYCAP_MARK
        joiner = joiner || code == EMOJI_ZERO_WIDTH_JOINER
    }
    defaultEmoji || (emojiBase && selector) || (pictographic && joiner)
}

/** Cheap eligibility check; ordinary text does not allocate a grapheme map or open emoji fonts. */
internal func hasEmojiCandidates(text: String): Bool {
    for (rune in text.runes()) {
        let code = UInt32(rune)
        if (code <= 0x7F) {
            continue
        }
        if (code == EMOJI_PRESENTATION_SELECTOR || code == EMOJI_KEYCAP_MARK || code == EMOJI_ZERO_WIDTH_JOINER ||
            (graphemeProperties(code) & GRAPHEME_EMOJI_PRESENTATION) != 0) {
            return true
        }
    }
    false
}
