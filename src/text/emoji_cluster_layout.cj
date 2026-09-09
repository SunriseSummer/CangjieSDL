package sdl.text

import std.collection.{ArrayList, HashMap}

private let EMOJI_OPERATION_LIMIT: Int32 = 1048576
private let EMOJI_CHOICE_OVERHEAD: Int64 = 32
private let EMOJI_UTF8_FOUR: UInt8 = 0xF0
private let EMOJI_UTF8_SYMBOL: UInt8 = 0xE2
private let EMOJI_UTF8_SELECTOR: UInt8 = 0xEF
private let EMOJI_LOCAL_CACHE_BYTES: Int64 = 64 * 1024
private let EMOJI_LOCAL_CACHE_ENTRIES: Int64 = 128

internal class EmojiShape {
    let font: CPointer<Unit>
    init(font: CPointer<Unit>) {
        this.font = font
    }
}

internal class EmojiReplacement {
    let start: Int32
    let end: Int32
    let shape: EmojiShape
    init(start: Int32, end: Int32, shape: EmojiShape) {
        this.start = start
        this.end = end
        this.shape = shape
    }
}

// Chooses one font per complete emoji grapheme before publishing a shared layout.
// Ordinary text remains in continuous runs; native visual order is retained.
// Neither the input string, font cmap nor the native fallback graph is modified.
internal func prepareEmojiLayout(text: CPointer<EngineText>, base: EngineLayout, state: CangjieTextEngine): EngineLayout {
    let header = unsafe { text.read() }
    if (!nativeEmojiCandidateBytes(header.text)) {
        return base
    }
    let value = unsafe { header.text.toString() }
    if (!hasEmojiCandidates(value)) {
        return base
    }
    let primary = unsafe { header.data.read().font }
    let candidates = ArrayList<CPointer<Unit>>()
    candidates.add(primary)
    if (let Some(fonts) <- state.fallbacks.get(primary.toUIntNative())) {
        candidates.add(all: fonts)
    }
    let replacements = collectEmojiReplacements(value, base, primary, candidates, state)
    if (replacements.isEmpty()) {
        return base
    }
    mergeEmojiLayout(value, base, replacements, primary, state)
}

private func collectEmojiReplacements(value: String, base: EngineLayout, primary: CPointer<Unit>,
    candidates: ArrayList<CPointer<Unit>>, state: CangjieTextEngine): Array<EmojiReplacement> {
    let lookup = HashMap<Int32, TtfSubstring>()
    for (cluster in base.clusters) {
        if (cluster.length > 0) {
            lookup[cluster.offset] = cluster
        }
    }
    let boundaries = graphemeByteBoundaries(value)
    let replacements = ArrayList<EmojiReplacement>()
    let cache = HashMap<String, ?EmojiShape>()
    var bytes: Int64 = 0
    for (i in 1..boundaries.size) {
        let start = boundaries[i - 1];
        let end = boundaries[i]
        let sample = value[start..end]
        if (!emojiPresentationCluster(sample)) {
            continue
        }
        // Native cluster boundaries must agree with the complete grapheme. Never cut through a
        // surrounding font ligature or an unsupported cross-cluster shaping context.
        if (let Some(cluster) <- lookup.get(Int32(start))) {
            if (Int64(cluster.length) != end - start) {
                continue
            }
        } else {
            continue
        }
        var found: ?EmojiShape = None
        if (let Some(cached) <- cache.get(sample)) {
            found = cached
        } else {
            found = shapeEmojiCluster(sample, candidates, state)
            let cost = sample.size + EMOJI_CHOICE_OVERHEAD
            if (cache.size >= EMOJI_LOCAL_CACHE_ENTRIES || bytes + cost > EMOJI_LOCAL_CACHE_BYTES) {
                cache.clear();
                bytes = 0
            }
            if (cost <= EMOJI_LOCAL_CACHE_BYTES) {
                cache[sample] = found
                bytes += cost
            }
        }
        if (let Some(shape) <- found && shape.font.toUIntNative() != primary.toUIntNative()) {
            replacements.add(EmojiReplacement(Int32(start), Int32(end), shape))
        }
    }
    replacements.toArray()
}

// Do not copy ordinary native UTF-8 strings into managed memory just to discover that they
// contain no possible emoji. These lead bytes cover pictographs and presentation selectors.
private func nativeEmojiCandidateBytes(text: CString): Bool {
    let bytes = text.getChars()
    if (bytes.isNull()) {
        return false
    }
    var offset: Int64 = 0
    while (true) {
        let byte = unsafe { bytes.read(offset) }
        if (byte == 0) {
            return false
        }
        if (byte >= EMOJI_UTF8_FOUR || byte == EMOJI_UTF8_SYMBOL || byte == EMOJI_UTF8_SELECTOR) {
            return true
        }
        offset += 1
    }
    false
}

private func shapeEmojiCluster(sample: String, fonts: ArrayList<CPointer<Unit>>, state: CangjieTextEngine): ?EmojiShape {
    let ordered = ArrayList<CPointer<Unit>>()
    if (sample.contains("\u{FE0F}")) {
        for (font in fonts) {
            if (let Some(source) <- state.sources.get(font.toUIntNative()) && source.color) {
                ordered.add(font)
            }
        }
        for (font in fonts) {
            if (let Some(source) <- state.sources.get(font.toUIntNative()) && !source.color) {
                ordered.add(font)
            }
        }
    } else {
        ordered.add(all: fonts)
    }
    let encoded = unsafe { LibC.mallocCString(sample) }
    try (resource = encoded.asResource()) {
        for (font in ordered) {
            let pointer = unsafe { TTF_CreateText(CPointer<Unit>(), font, resource.value, UIntNative(sample.size)) }
            if (pointer.isNull()) {
                throw NativeTextException("Cannot shape emoji cluster: ${lastNativeError()}")
            }
            try {
                if (!unsafe { TTF_UpdateText(pointer) }) {
                    throw NativeTextException("Cannot update emoji cluster: ${lastNativeError()}")
                }
                if (completeEmojiFace(pointer, font)) {
                    return Some(EmojiShape(font))
                }
            } finally {
                unsafe { TTF_DestroyText(pointer) }
            }
        }
    }
    None
}

private func completeEmojiFace(text: CPointer<Unit>, font: CPointer<Unit>): Bool {
    let header = unsafe { CPointer<EngineText>(text).read().data.read() }
    if (header.operationCount < 0 || header.operationCount > EMOJI_OPERATION_LIMIT || (header.operationCount > 0 &&
        header.operations.isNull())) {
        throw NativeTextException("Invalid emoji cluster layout")
    }
    if (header.operationCount == 0) {
        return false
    }
    for (i in 0..Int64(header.operationCount)) {
        let operation = unsafe { header.operations.read(i) }
        if (operation.command == 2 && (operation.glyph == 0 || operation.font.toUIntNative() != font.toUIntNative())) {
            return false
        }
    }
    true
}
