package sdl.text

import std.collection.ArrayList
import std.sort.sort

private let SFNT_DIRECTORY_HEADER: Int64 = 12
private let SFNT_DIRECTORY_RECORD: Int64 = 16
private let SFNT_SEARCH_RANGE_FIELD: Int64 = 6
private let SFNT_ENTRY_SELECTOR_FIELD: Int64 = 8
private let SFNT_RANGE_SHIFT_FIELD: Int64 = 10
private let SFNT_CHECKSUM_ADJUSTMENT_FIELD: Int64 = 8
private let SFNT_TABLE_OFFSET_FIELD: Int64 = 8
private let SFNT_TABLE_LENGTH_FIELD: Int64 = 12
private let SFNT_WORD_BYTES: Int64 = 4
private let FVAR_AXIS_COUNT_FIELD: Int64 = 8
private let FVAR_AXIS_SIZE_FIELD: Int64 = 10
private let FVAR_NAMED_INSTANCE_BASE_BYTES: Int64 = 6
private let FVAR_HEADER_BYTES: Int64 = 16
private let FVAR_AXIS_BYTES: Int64 = 20
private let FVAR_VERSION_ONE: UInt32 = 0x00010000
private let FVAR_INSTANCE_COUNT_FIELD: Int64 = 12
private let FVAR_INSTANCE_SIZE_FIELD: Int64 = 14
private let SFNT_FIXED_SCALE: Float64 = 65536.0
private let SFNT_FIXED_SIGN_LIMIT: Int64 = 2147483648
private let SFNT_FIXED_MAX: Int64 = 2147483647
private let SFNT_FIXED_MODULUS: Int64 = 0x100000000
private let SFNT_U16_MAX: Int64 = 65535
private let SFNT_U32_MASK: UInt64 = 0xFFFFFFFF
private let SFNT_DSIG: UInt32 = 0x44534947
private let SFNT_GSUB: UInt32 = 0x47535542
private let SFNT_GPOS: UInt32 = 0x47504f53
private let SFNT_KERN: UInt32 = 0x6b65726e
private let SFNT_FVAR: UInt32 = 0x66766172
private let SFNT_HEAD: UInt32 = 0x68656164
private let SFNT_CMAP: UInt32 = 0x636d6170

internal struct SfntPiece {
    let offset: Int64
    let length: Int64
    let sourceOffset: Int64
    let bytes: Array<UInt8>
    init(offset: Int64, length: Int64, sourceOffset!: Int64 = -1, bytes!: Array<UInt8> = []) {
        this.offset = offset
        this.length = length
        this.sourceOffset = sourceOffset
        this.bytes = bytes
    }
}

// An immutable virtual standalone face, not a whole-font copy. Only directory/head/fvar differ;
// all outlines, shaping tables and names are read directly from the original file.
internal class SfntView {
    let sourceIdentity: UInt64
    let pieces: Array<SfntPiece>
    let length: Int64
    let patchBytes: Int64
    init(source: NativeFontSource, metadata: NativeInstalledFont, glyphProbe!: Bool = false) {
        let file = sfntFile(source.path)
        this.sourceIdentity = file.identity
        let face = file.faces[source.faceIndex & SFNT_U16_MAX]
        let tables = ArrayList<SfntTable>()
        for (table in face.tables) {
            if (table.tagCode == SFNT_DSIG || (glyphProbe && (table.tagCode == SFNT_GSUB || table.tagCode == SFNT_GPOS ||
                table.tagCode == SFNT_KERN))) {
                continue
            }
            tables.add(table)
        }
        let ordered = tables.toArray()
        sort<SfntTable, UInt32>(ordered, key: {value => value.tagCode})
        let header = Array<UInt8>(SFNT_DIRECTORY_HEADER + ordered.size * SFNT_DIRECTORY_RECORD, repeat: 0)
        sfntPut32(header, 0, face.version);
        sfntPut16(header, SFNT_WORD_BYTES, ordered.size)
        var power: Int64 = 1
        var exponent: Int64 = 0
        while (power * 2 <= ordered.size) {
            power *= 2
            exponent += 1
        }
        sfntPut16(header, SFNT_SEARCH_RANGE_FIELD, power * SFNT_DIRECTORY_RECORD);
        sfntPut16(header, SFNT_ENTRY_SELECTOR_FIELD, exponent)
        sfntPut16(header, SFNT_RANGE_SHIFT_FIELD, ordered.size * SFNT_DIRECTORY_RECORD - power * SFNT_DIRECTORY_RECORD)
        let fvar: Array<UInt8> = if (face.variations.isEmpty()) {
            []
        } else {
            sfntInstanceTable(face.variations, metadata.coordinates)
        }
        let cmap: Array<UInt8> = if (glyphProbe) {
            sfntGlyphProbeCmap(face.glyphCount)
        } else {
            []
        }
        let head = face.head.clone()
        sfntRange(head.size, 0, 54)
        sfntPut32(head, SFNT_CHECKSUM_ADJUSTMENT_FIELD, 0)
        let pieces = ArrayList<SfntPiece>([SfntPiece(0, header.size, bytes: header)])
        var offset = header.size
        var totalChecksum: UInt64 = 0
        var patchBytes = header.size
        for (i in 0..ordered.size) {
            let table = ordered[i]
            let patch: Array<UInt8> = if (table.tagCode == SFNT_FVAR) {
                fvar
            } else if (table.tagCode == SFNT_HEAD) {
                head
            } else if (table.tagCode == SFNT_CMAP && glyphProbe) {
                cmap
            } else {
                []
            }
            let count = if (patch.isEmpty()) {
                table.length
            } else {
                patch.size
            }
            let checksum = if (patch.isEmpty()) {
                table.checksum
            } else {
                sfntChecksum(patch)
            }
            let entry = SFNT_DIRECTORY_HEADER + i * SFNT_DIRECTORY_RECORD
            sfntPut32(header, entry, table.tagCode)
            sfntPut32(header, entry + SFNT_WORD_BYTES, checksum)
            sfntPut32(header, entry + SFNT_TABLE_OFFSET_FIELD, UInt32(offset));
            sfntPut32(header, entry + SFNT_TABLE_LENGTH_FIELD, UInt32(count))
            pieces.add(SfntPiece(offset, count, sourceOffset: if (patch.isEmpty()) {
                table.offset
            } else {
                -1
            }, bytes: patch))
            totalChecksum = (totalChecksum + UInt64(checksum)) & SFNT_U32_MASK
            patchBytes += patch.size
            offset += count
            let padding = (SFNT_WORD_BYTES - offset % SFNT_WORD_BYTES) % SFNT_WORD_BYTES
            if (padding > 0) {
                pieces.add(SfntPiece(offset, padding));
                offset += padding
            }
            if (UInt64(offset) > SFNT_U32_MASK) {
                throw NativeTextException("Virtual font exceeds SFNT offset range")
            }
        }
        totalChecksum = (totalChecksum + UInt64(sfntChecksum(header))) & SFNT_U32_MASK
        sfntPut32(head, SFNT_CHECKSUM_ADJUSTMENT_FIELD, UInt32((0x1B1B0AFBA - totalChecksum) & SFNT_U32_MASK))
        this.pieces = pieces.toArray()
        this.length = offset
        this.patchBytes = patchBytes
    }
}

private func sfntInstanceTable(original: Array<UInt8>, coordinates: Array<NativeFontCoordinate>): Array<UInt8> {
    let axisOffset = sfntU16(original, SFNT_WORD_BYTES)
    let axisCount = sfntU16(original, FVAR_AXIS_COUNT_FIELD)
    let axisSize = sfntU16(original, FVAR_AXIS_SIZE_FIELD)
    let recordSize = FVAR_NAMED_INSTANCE_BASE_BYTES + axisCount * SFNT_WORD_BYTES
    if (axisCount != coordinates.size) {
        throw NativeTextException("Virtual font coordinates do not match axes")
    }
    let bytes = Array<UInt8>(FVAR_HEADER_BYTES + axisCount * FVAR_AXIS_BYTES + recordSize, repeat: 0)
    sfntPut32(bytes, 0, FVAR_VERSION_ONE);
    sfntPut16(bytes, SFNT_WORD_BYTES, FVAR_HEADER_BYTES);
    sfntPut16(bytes, FVAR_NAMED_INSTANCE_BASE_BYTES, 2)
    sfntPut16(bytes, FVAR_AXIS_COUNT_FIELD, axisCount);
    sfntPut16(bytes, FVAR_AXIS_SIZE_FIELD, FVAR_AXIS_BYTES);
    sfntPut16(bytes, FVAR_INSTANCE_COUNT_FIELD, 1)
    sfntPut16(bytes, FVAR_INSTANCE_SIZE_FIELD, recordSize)
    for (i in 0..axisCount) {
        original.copyTo(bytes, axisOffset + i * axisSize, FVAR_HEADER_BYTES + i * FVAR_AXIS_BYTES, FVAR_AXIS_BYTES)
    }
    let instance = FVAR_HEADER_BYTES + axisCount * FVAR_AXIS_BYTES
    // The original subfamily name is retained. Public diagnostics report the original source and
    // precise coordinates; this private instance is never offered as an installed font.
    sfntPut16(bytes, instance, 2)
    for (i in 0..axisCount) {
        let value = Float64(coordinates[i].value) * SFNT_FIXED_SCALE
        let fixed = Int64(if (value < 0.0) {
            value - 0.5
        } else {
            value + 0.5
        })
        if (fixed < -SFNT_FIXED_SIGN_LIMIT || fixed > SFNT_FIXED_MAX) {
            throw IllegalArgumentException("Font axis exceeds Fixed range")
        }
        sfntPut32(bytes, instance + SFNT_WORD_BYTES + i * SFNT_WORD_BYTES, UInt32(if (fixed < 0) {
            fixed + SFNT_FIXED_MODULUS
        } else {
            fixed
        }))
    }
    sfntPut16(bytes, instance + recordSize - 2, SFNT_U16_MAX)
    bytes
}

internal func sfntPut16(bytes: Array<UInt8>, offset: Int64, value: Int64): Unit {
    sfntRange(bytes.size, offset, 2)
    if (value < 0 || value > SFNT_U16_MAX) {
        throw NativeTextException("SFNT UInt16 overflow")
    }
    bytes[offset] = UInt8(value >> FVAR_AXIS_COUNT_FIELD)
    bytes[offset + 1] = UInt8(value & 255)
}

internal func sfntPut32(bytes: Array<UInt8>, offset: Int64, value: UInt32): Unit {
    sfntRange(bytes.size, offset, SFNT_WORD_BYTES)
    for (i in 0..4) {
        bytes[offset + i] = UInt8((value >> UInt32((3 - i) * FVAR_AXIS_COUNT_FIELD)) & 255)
    }
}

internal func sfntChecksum(bytes: Array<UInt8>): UInt32 {
    var total: UInt64 = 0
    var offset: Int64 = 0
    while (offset < bytes.size) {
        var word: UInt32 = 0
        for (i in 0..4) {
            word = (word << FVAR_AXIS_COUNT_FIELD) | if (offset + i < bytes.size) {
                UInt32(bytes[offset + i])
            } else {
                0
            }
        }
        total = (total + UInt64(word)) & SFNT_U32_MASK
        offset += SFNT_WORD_BYTES
    }
    UInt32(total)
}
