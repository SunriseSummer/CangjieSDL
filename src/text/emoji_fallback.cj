package sdl.text

import std.collection.HashMap

private let EMOJI_QUERY_LIMIT: Int64 = 256
private let EMOJI_QUERY_BYTES: Int64 = 128 * 1024
// A Unicode-based candidate filter precedes complete-cluster font selection.
// Ordinary UI strings never open an emoji font.
internal class EmojiFallback {
    private let queries = HashMap<String, Bool>()
    private var bytes: Int64 = 0
    private var loaded = false
    private var selected: ?NativeFontSource = None

    func needed(text: String): Bool {
        if (let Some(result) <- queries.get(text)) {
            return result
        }
        let result = hasEmojiCandidates(text)
        if (text.size <= EMOJI_QUERY_BYTES) {
            if (queries.size >= EMOJI_QUERY_LIMIT || bytes + text.size > EMOJI_QUERY_BYTES) {
                queries.clear();
                bytes = 0
            }
            queries[text] = result
            bytes += text.size
        }
        result
    }

    func source(): ?NativeFontSource {
        if (!loaded) {
            selected = findEmojiSource()
            loaded = true
        }
        selected
    }

    func reset(): Unit {
        queries.clear();
        bytes = 0
        loaded = false
        selected = None
    }
}

private func findEmojiSource(): ?NativeFontSource {
    for (record in nativeEmojiFonts()) {
        try {
            for (face in inspectNativeFontFile(record.path)) {
                if (face.source.faceIndex < 65536 && ((record.index >= 0 && face.source.faceIndex == record.index) || (record
                    .index < 0 && face.familyName.toAsciiLower() == record.family.toAsciiLower()))) {
                    return Some(face.source)
                }
            }
        } catch (_: NativeTextException) {
            // Optional platform font: explicit application fallbacks remain available.
            continue
        }
    }
    None
}

/** Targeted emoji-family discovery. Never enumerates the installed-font catalog. */
protected func nativeEmojiFonts(): Array<NativePlatformFont> {
    for (name in emojiFamilyCandidates()) {
        let records = nativePlatformNamedFonts(name)
        if (!records.isEmpty()) {
            return records
        }
    }
    []
}

@When[os == "Windows"]
private func emojiFamilyCandidates(): Array<String> {
    ["Segoe UI Emoji"]
}

@When[os == "Linux"]
private func emojiFamilyCandidates(): Array<String> {
    ["Noto Color Emoji", "Noto Emoji", "Twemoji Mozilla"]
}

@When[os == "macOS"]
private func emojiFamilyCandidates(): Array<String> {
    ["Apple Color Emoji"]
}
