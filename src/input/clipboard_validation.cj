package sdl.input

import sdl.{SdlException}

internal let CLIPBOARD_MAX_MIME_TYPES: Int64 = 64

/**
 * Throws `SdlException` when clipboard data cannot be safely offered to SDL.
 */
internal func ensureClipboardDataItems(items: Array<ClipboardData>): Unit {
    if (items.size <= 0) {
        throw SdlException("Clipboard data must include at least one MIME item.")
    }
    if (items.size > CLIPBOARD_MAX_MIME_TYPES) {
        throw SdlException("Clipboard data cannot include more than ${CLIPBOARD_MAX_MIME_TYPES} MIME items.")
    }
    for (i in 0..items.size) {
        ensureClipboardMimeType(items[i].mimeType)
        ensureClipboardMimeTypeUnique(items, i)
    }
}

/**
 * Throws `SdlException` when a MIME type is empty or contains unsafe control bytes.
 */
internal func ensureClipboardMimeType(mimeType: String): Unit {
    if (mimeType.size <= 0) {
        throw SdlException("Clipboard MIME type cannot be empty.")
    }
    for (byte in mimeType) {
        if (!isClipboardMimeTypeByte(byte)) {
            throw SdlException("Clipboard MIME type contains an invalid byte.")
        }
    }
}

/**
 * Throws `SdlException` when the current item repeats an earlier MIME type.
 */
private func ensureClipboardMimeTypeUnique(items: Array<ClipboardData>, index: Int64): Unit {
    let mimeType = items[index].mimeType
    for (i in 0..index) {
        if (items[i].mimeType == mimeType) {
            throw SdlException("Clipboard MIME types must be unique.")
        }
    }
}

private func isClipboardMimeTypeByte(byte: UInt8): Bool {
    byte > UInt8(32) && byte < UInt8(127)
}
