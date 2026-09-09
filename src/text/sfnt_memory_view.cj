package sdl.text

internal let FONT_VIEW_GRANULARITY: Int64 = 64 * 1024
private let FONT_VIEW_PATCH_LIMIT: Int64 = 256 * 1024
private let FONT_CHECKSUM_MASK: UInt64 = 0xFFFFFFFF
private let FONT_CHECKSUM_ADJUSTMENT: UInt64 = 0x1B1B0AFBA
private let FONT_DIRECTORY_BYTES: Int64 = 12
private let FONT_DIRECTORY_RECORD: Int64 = 16
private let FONT_TABLE_OFFSET_FIELD: Int64 = 8
private let FONT_HEAD_TAG: UInt32 = 0x68656164

// A contiguous address space can be handed to stock SDL_IOFromConstMem without Cangjie
// callbacks. Only a small header and the final partial mapping page are private memory.
internal class SfntMemoryPlan {
    let prefix: Array<UInt8>
    let fileOffset: Int64
    let filePrefixLength: Int64
    let length: Int64
    init(view: SfntView, source: FontFileMapping) {
        let original = view.pieces[0].bytes
        let tableCount = sfntU16(original, 4)
        var patchLength = original.size
        for (i in 1..view.pieces.size) {
            if (!view.pieces[i].bytes.isEmpty()) {
                patchLength += (view.pieces[i].bytes.size + 3) / 4 * 4
            }
        }
        let prefix = Array<UInt8>(patchLength, repeat: 0)
        original.copyTo(prefix, 0, 0, original.size)
        let fileOffset = (patchLength + FONT_VIEW_GRANULARITY - 1) / FONT_VIEW_GRANULARITY * FONT_VIEW_GRANULARITY
        if (fileOffset > FONT_VIEW_PATCH_LIMIT) {
            throw NativeTextException("Font view patches exceed 256 KiB")
        }
        var cursor = original.size
        var headOffset: Int64 = -1
        for (i in 0..tableCount) {
            let record = FONT_DIRECTORY_BYTES + i * FONT_DIRECTORY_RECORD
            let oldOffset = Int64(sfntU32(original, record + FONT_TABLE_OFFSET_FIELD))
            var found = false
            for (piece in view.pieces) {
                if (piece.offset != oldOffset) {
                    continue
                }
                found = true
                let offset = if (piece.bytes.isEmpty()) {
                    fileOffset + piece.sourceOffset
                } else {
                    cursor
                }
                if (offset < 0 || offset > Int64(UInt32.Max)) {
                    throw NativeTextException("Font view table offset overflow")
                }
                sfntPut32(prefix, record + FONT_TABLE_OFFSET_FIELD, UInt32(offset))
                if (!piece.bytes.isEmpty()) {
                    piece.bytes.copyTo(prefix, 0, cursor, piece.bytes.size)
                    if (sfntU32(prefix, record) == FONT_HEAD_TAG) {
                        headOffset = cursor
                    }
                    cursor += (piece.bytes.size + 3) / 4 * 4
                }
                break
            }
            if (!found) {
                throw NativeTextException("Font view table segment is missing")
            }
        }
        if (headOffset < 0) {
            throw NativeTextException("Font view requires a private head table")
        }
        sfntPut32(prefix, headOffset + FONT_TABLE_OFFSET_FIELD, 0)
        let sum = (UInt64(sfntChecksum(prefix)) + UInt64(source.checksum)) & FONT_CHECKSUM_MASK
        sfntPut32(prefix, headOffset + FONT_TABLE_OFFSET_FIELD,
            UInt32((FONT_CHECKSUM_ADJUSTMENT - sum) & FONT_CHECKSUM_MASK))
        this.prefix = prefix
        this.fileOffset = fileOffset
        this.filePrefixLength = source.length / FONT_VIEW_GRANULARITY * FONT_VIEW_GRANULARITY
        this.length = fileOffset + (source.length + 3) / 4 * 4
    }
}

internal func mappedFontChecksum(bytes: CPointer<UInt8>, length: Int64): UInt32 {
    var sum: UInt64 = 0
    var offset: Int64 = 0
    while (offset < length) {
        var word: UInt32 = 0
        for (i in 0..4) {
            word = word << 8
            if (offset + i < length) {
                word |= UInt32(unsafe { bytes.read(offset + i) })
            }
        }
        sum = (sum + UInt64(word)) & FONT_CHECKSUM_MASK
        offset += 4
    }
    UInt32(sum)
}

internal func fillMappedFontView(destination: CPointer<UInt8>, source: FontFileMapping, plan: SfntMemoryPlan): Unit {
    for (i in 0..plan.prefix.size) {
        unsafe { destination.write(i, plan.prefix[i]) }
    }
    let tail = source.length - plan.filePrefixLength
    if (tail > 0) {
        let target = unsafe { destination + plan.fileOffset + plan.filePrefixLength }
        let input = unsafe { source.bytes + plan.filePrefixLength }
        let _ = unsafe { memcpy(target, input, UIntNative(tail)) } // cjcheck-ignore: ignore-result # the destination is already known; the final partial page is smaller than 64 KiB
    }
}
