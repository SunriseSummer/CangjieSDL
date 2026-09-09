package sdl.text

import std.collection.HashMap
import std.fs.{File, FileInfo, OpenMode}
import std.io.SeekPosition

private let SFNT_HEADER_BYTES: Int64 = 12
private let SFNT_COLLECTION_SIGNATURE: UInt32 = 0x74746366
private let SFNT_MAX_COLLECTION_FACES: Int64 = 256
private let SFNT_MAX_TABLES: Int64 = 4096
private let SFNT_WORD_BYTES: Int64 = 4
private let SFNT_TRUETYPE_SIGNATURE: UInt32 = 0x00010000
private let SFNT_OPENTYPE_SIGNATURE: UInt32 = 0x4F54544F
private let SFNT_APPLE_TRUETYPE_SIGNATURE: UInt32 = 0x74727565
private let SFNT_FIXED_SIGN_BIT: Int64 = 0x80000000
private let SFNT_FIXED_MODULUS: Int64 = 0x100000000
private let SFNT_FIXED_SCALE: Float32 = 65536.0
private let SFNT_TAG_ASCII_MIN: UInt8 = 32
private let SFNT_TAG_ASCII_MAX: UInt8 = 126

// Only metadata tables are read. Large glyf/CFF/CJK outlines stay in the source file.
internal let SFNT_TABLE_LIMIT: Int64 = 2 * 1024 * 1024
internal let SFNT_COLOR_LAYERS: UInt32 = 0x434F4C52
internal let SFNT_COLOR_PALETTE: UInt32 = 0x4350414C
internal let SFNT_COLOR_BITMAP: UInt32 = 0x43424454
internal let SFNT_APPLE_BITMAP: UInt32 = 0x73626978
internal let SFNT_SVG_OUTLINES: UInt32 = 0x53564720

// A table tag is exactly four ASCII bytes. Keep the directory value-only: repeated sorting
// and copying need neither boxed strings nor interior managed references in each table record.
internal struct SfntTable {
    let tagCode: UInt32
    let checksum: UInt32
    let offset: Int64
    let length: Int64
    init(tagCode: UInt32, checksum: UInt32, offset: Int64, length: Int64) {
        this.tagCode = tagCode
        this.checksum = checksum
        this.offset = offset
        this.length = length
    }
}

internal class SfntReader {
    let file: File
    let length: Int64
    init(path: String) {
        this.length = FileInfo(path).size
        this.file = File(path, OpenMode.Read)
    }

    func read(offset: Int64, count: Int64): Array<UInt8> {
        sfntRange(length, offset, count)
        if (count > SFNT_TABLE_LIMIT) {
            throw NativeTextException("Font metadata table exceeds 2 MiB")
        }
        let bytes = Array<UInt8>(count, repeat: 0)
        if (count == 0) {
            return bytes
        }
        if (file.seek(SeekPosition.Begin(offset)) != offset) {
            throw NativeTextException("Font metadata seek failed")
        }
        var filled: Int64 = 0
        while (filled < count) {
            let received = file.read(bytes[filled..count])
            if (received <= 0) {
                throw NativeTextException("Truncated font table")
            }
            filled += received
        }
        bytes
    }

    func offsets(): Array<Int64> {
        let header = read(0, SFNT_HEADER_BYTES)
        if (sfntU32(header, 0) != SFNT_COLLECTION_SIGNATURE) {
            return [0]
        }
        let count = Int64(sfntU32(header, 8))
        if (count < 1 || count > SFNT_MAX_COLLECTION_FACES) {
            throw NativeTextException("Invalid font collection count")
        }
        let values = read(SFNT_HEADER_BYTES, count * SFNT_WORD_BYTES)
        Array<Int64>(count) {i => Int64(sfntU32(values, i * SFNT_WORD_BYTES))}
    }

    func tables(offset: Int64): (UInt32, Array<SfntTable>) {
        let header = read(offset, SFNT_HEADER_BYTES)
        let version = sfntU32(header, 0)
        if (version != SFNT_TRUETYPE_SIGNATURE && version != SFNT_OPENTYPE_SIGNATURE && version !=
            SFNT_APPLE_TRUETYPE_SIGNATURE) {
            throw NativeTextException("Unsupported SFNT signature")
        }
        let count = sfntU16(header, SFNT_WORD_BYTES)
        if (count < 1 || count > SFNT_MAX_TABLES) {
            throw NativeTextException("Invalid SFNT table count")
        }
        let entries = read(offset + SFNT_HEADER_BYTES, count * 16)
        let seen = HashMap<UInt32, Bool>()
        let tables = Array<SfntTable>(count) {
            i =>
                let start = i * 16
                let tag = sfntTagCode(entries, start)
                let position = Int64(sfntU32(entries, start + 8))
                let size = Int64(sfntU32(entries, start + SFNT_HEADER_BYTES))
                sfntRange(length, position, size)
                if (seen.contains(tag)) {
                    throw NativeTextException("Duplicate SFNT table: ${tag}")
                }
                seen[tag] = true
                SfntTable(tag, sfntU32(entries, start + SFNT_WORD_BYTES), position, size)
        }
        (version, tables)
    }

    func table(tables: Array<SfntTable>, tag: String): Array<UInt8> {
        let code = fontAxisTagCode(tag)
        for (table in tables) {
            if (table.tagCode == code) {
                return read(table.offset, table.length)
            }
        }
        []
    }
}

internal func sfntRange(size: Int64, offset: Int64, count: Int64): Unit {
    if (offset < 0 || count < 0 || offset > size || count > size - offset) {
        throw NativeTextException("Font table offset/length is out of bounds")
    }
}

internal func sfntU16(bytes: Array<UInt8>, offset: Int64): Int64 {
    sfntRange(bytes.size, offset, 2)
    (Int64(bytes[offset]) << 8) | Int64(bytes[offset + 1])
}

internal func sfntU32(bytes: Array<UInt8>, offset: Int64): UInt32 {
    sfntRange(bytes.size, offset, SFNT_WORD_BYTES)
    (UInt32(bytes[offset]) << 24) | (UInt32(bytes[offset + 1]) << 16) | (UInt32(bytes[offset + 2]) << 8) | UInt32(bytes[offset +
            3])
}

internal func sfntFixed(bytes: Array<UInt8>, offset: Int64): Float32 {
    let bits = Int64(sfntU32(bytes, offset))
    Float32(if (bits >= SFNT_FIXED_SIGN_BIT) {
        bits - SFNT_FIXED_MODULUS
    } else {
        bits
    }) / SFNT_FIXED_SCALE
}

internal func sfntTag(bytes: Array<UInt8>, offset: Int64): String {
    let _ = sfntTagCode(bytes, offset) // cjcheck-ignore: ignore-result # validate the same four ASCII bytes before decoding an axis or name tag
    String.fromUtf8(bytes[offset..offset + SFNT_WORD_BYTES])
}

internal func sfntTagCode(bytes: Array<UInt8>, offset: Int64): UInt32 {
    sfntRange(bytes.size, offset, SFNT_WORD_BYTES)
    for (i in offset..offset + SFNT_WORD_BYTES) {
        if (bytes[i] < SFNT_TAG_ASCII_MIN || bytes[i] > SFNT_TAG_ASCII_MAX) {
            throw NativeTextException("Invalid SFNT tag")
        }
    }
    sfntU32(bytes, offset)
}
