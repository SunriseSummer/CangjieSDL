package sdl.input

import sdl.{SdlException, ensureSdl, lastSdlError}

/**
 * Binary clipboard payload paired with the MIME type offered to other desktop apps.
 */
public struct ClipboardData {
    public let mimeType: String
    public let bytes: Array<UInt8>

    public init(mimeType: String, bytes: Array<UInt8>) {
        this.mimeType = mimeType
        this.bytes = bytes
    }
}

/**
 * Main-thread access to SDL3 clipboard text, primary selection text, and MIME data.
 */
public class Clipboard {
    /**
     * Throws `SdlException` when SDL cannot update the system clipboard text.
     */
    public static func setText(text: String): Unit {
        let cText = unsafe { LibC.mallocCString(text) }
        try (textResource = cText.asResource()) {
            ensureSdl(unsafe { SDL_SetClipboardText(textResource.value) }, "SDL_SetClipboardText")
        }
    }

    /** Whether the system clipboard currently holds non-empty text. */
    public static func hasText(): Bool {
        unsafe { SDL_HasClipboardText() }
    }

    /** The system clipboard text, or the empty string when no text is available. */
    public static func getText(): String {
        if (!hasText()) {
            return ""
        }
        clipboardStringFromOwnedCString(unsafe { SDL_GetClipboardText() })
    }

    /**
     * Throws `SdlException` when SDL cannot update primary selection text.
     */
    public static func setPrimarySelectionText(text: String): Unit {
        let cText = unsafe { LibC.mallocCString(text) }
        try (textResource = cText.asResource()) {
            ensureSdl(unsafe { SDL_SetPrimarySelectionText(textResource.value) }, "SDL_SetPrimarySelectionText")
        }
    }

    /** Whether the primary selection (X11-style middle-click buffer) currently holds non-empty text. */
    public static func hasPrimarySelectionText(): Bool {
        unsafe { SDL_HasPrimarySelectionText() }
    }

    /** The primary selection text, or the empty string when no text is available. */
    public static func getPrimarySelectionText(): String {
        if (!hasPrimarySelectionText()) {
            return ""
        }
        clipboardStringFromOwnedCString(unsafe { SDL_GetPrimarySelectionText() })
    }

    /**
     * Throws `SdlException` when MIME types are invalid or SDL rejects the offered data.
     */
    public static func setData(items: Array<ClipboardData>): Unit {
        ensureClipboardDataItems(items)
        let offer = createClipboardOffer(items)
        registerClipboardOffer(offer)
        try {
            ensureSdl(unsafe {
                SDL_SetClipboardData(
                    cuiClipboardDataCallback,
                    cuiClipboardCleanupCallback,
                    offer.userdata(),
                    offer.rawMimeTypes,
                    UIntNative(offer.mimeCount())
                )
            }, "SDL_SetClipboardData")
        } catch (e: Exception) {
            unregisterClipboardOffer(offer.id)
            offer.close()
            throw e
        }
    }

    /**
     * Throws `SdlException` when SDL cannot clear non-text clipboard data.
     */
    public static func clearData(): Unit {
        ensureSdl(unsafe { SDL_ClearClipboardData() }, "SDL_ClearClipboardData")
    }

    /**
     * Throws `SdlException` when `mimeType` is empty.
     */
    public static func hasData(mimeType: String): Bool {
        ensureClipboardMimeType(mimeType)
        let cMimeType = unsafe { LibC.mallocCString(mimeType) }
        var found = false
        try (mimeTypeResource = cMimeType.asResource()) {
            found = unsafe { SDL_HasClipboardData(mimeTypeResource.value) }
        }
        found
    }

    /**
     * Throws `SdlException` when `mimeType` is empty or SDL cannot copy data that it reported as available.
     */
    public static func getData(mimeType: String): ?Array<UInt8> {
        if (!hasData(mimeType)) {
            return None<Array<UInt8>>
        }
        let cMimeType = unsafe { LibC.mallocCString(mimeType) }
        var size: UIntNative = UIntNative(0)
        var data = CPointer<UInt8>()
        try (mimeTypeResource = cMimeType.asResource()) {
            data = unsafe { SDL_GetClipboardData(mimeTypeResource.value, inout size) }
        }
        if (data.isNull() && size == UIntNative(0)) {
            return Some(Array<UInt8>(0, {_ => UInt8(0)}))
        }
        if (data.isNull()) {
            throw SdlException("SDL_GetClipboardData failed: ${lastSdlError()}")
        }
        try {
            Some(clipboardBytesFromPointer(data, size))
        } finally {
            unsafe { SDL_free(data) }
        }
    }

    /** The MIME types currently offered on the clipboard; empty when nothing is offered. */
    public static func mimeTypes(): Array<String> {
        var count: UIntNative = UIntNative(0)
        let mimeTypes = unsafe { SDL_GetClipboardMimeTypes(inout count) }
        if (mimeTypes.isNull()) {
            return []
        }
        try {
            clipboardMimeTypesFromPointer(mimeTypes, count)
        } finally {
            unsafe { SDL_free(CPointer<UInt8>(mimeTypes)) }
        }
    }
}
