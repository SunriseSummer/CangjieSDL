package sdl.text

import std.collection.{ArrayList, HashMap, HashSet}

private let UTF16_SURROGATE_RADIX: Int64 = 1024
private let SFNT_NAME_RECORD_LIMIT: Int64 = 4096
private let SFNT_NAME_STRING_LIMIT: Int64 = 4096
private let SFNT_NAME_DECODE_BUDGET: Int64 = 1024 * 1024

internal class SfntNames {
    private let values = HashMap<Int64, String>()
    private let ranks = HashMap<Int64, Int64>()
    let aliases = ArrayList<String>()

    init(bytes: Array<UInt8>) {
        if (bytes.isEmpty()) {
            return
        }
        let format = sfntU16(bytes, 0)
        if (format > 1) {
            throw NativeTextException("Unsupported SFNT name format")
        }
        let count = sfntU16(bytes, 2)
        let strings = sfntU16(bytes, 4)
        if (count > SFNT_NAME_RECORD_LIMIT) {
            throw NativeTextException("Too many font name records")
        }
        var decoded: Int64 = 0
        sfntRange(bytes.size, 6, count * 12)
        if (strings < 6 + count * 12) {
            throw NativeTextException("Invalid SFNT name storage")
        }
        let seen = HashSet<String>()
        for (i in 0..count) {
            let base = 6 + i * 12
            let platform = sfntU16(bytes, base)
            let encoding = sfntU16(bytes, base + 2)
            let language = sfntU16(bytes, base + 4)
            let id = sfntU16(bytes, base + 6)
            let size = sfntU16(bytes, base + 8)
            let offset = strings + sfntU16(bytes, base + 10)
            sfntRange(bytes.size, offset, size)
            if (id != 1 && id != 2 && id != 16 && id != 17 && id < 256) {
                continue
            }
            decoded += size
            if (size > SFNT_NAME_STRING_LIMIT || decoded > SFNT_NAME_DECODE_BUDGET) {
                throw NativeTextException("Font names exceed the decode budget")
            }
            var text = ""
            var rank: Int64 = 0
            if (platform == 0 || (platform == 3 && (encoding == 0 || encoding == 1 || encoding == 10))) {
                text = sfntUtf16(bytes[offset..offset + size])
                rank = if (platform == 3 && language == 0x409) {
                    40
                } else if (platform == 0) {
                    30
                } else {
                    20
                }
            } else if (platform == 1 && encoding == 0) {
                // Macintosh Roman ASCII names are unambiguous; non-ASCII is not UTF-8.
                var ascii = true
                for (j in offset..offset + size) {
                    if (bytes[j] < 32 || bytes[j] > 126) {
                        ascii = false
                    }
                }
                if (ascii) {
                    text = String.fromUtf8(bytes[offset..offset + size])
                    rank = 10
                }
            }
            if (text.isEmpty()) {
                continue
            }
            if (rank > ranks.get(id).getOrDefault({=> Int64(-1)})) {
                ranks[id] = rank
                values[id] = text
            }
            if ((id == 1 || id == 16) && !seen.contains(text)) {
                seen.add(text);
                aliases.add(text)
            }
        }
    }

    func get(id: Int64, fallback!: String = ""): String {
        values.get(id).getOrDefault({=> fallback})
    }
}

internal func sfntUtf16(bytes: Array<UInt8>): String {
    if (bytes.size % 2 != 0) {
        throw NativeTextException("Odd UTF-16 font name length")
    }
    let output = ArrayList<Rune>()
    var index: Int64 = 0
    while (index < bytes.size) {
        var scalar = sfntU16(bytes, index)
        index += 2
        if (scalar >= 0xD800 && scalar <= 0xDBFF) {
            let low = sfntU16(bytes, index)
            if (low < 0xDC00 || low > 0xDFFF) {
                throw NativeTextException("Invalid font name surrogate")
            }
            scalar = 0x10000 + (scalar - 0xD800) * UTF16_SURROGATE_RADIX + low - 0xDC00
            index += 2
        } else if (scalar >= 0xDC00 && scalar <= 0xDFFF) {
            throw NativeTextException("Unpaired font name surrogate")
        }
        if (scalar == 0) {
            continue
        }
        output.add(Rune(UInt32(scalar)))
    }
    String(output)
}
