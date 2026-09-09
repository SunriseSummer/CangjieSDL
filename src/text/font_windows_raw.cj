package sdl.text

@When[os == "Windows"]
import std.collection.ArrayList

@When[os == "Windows"]
private let UTF16_SUPPLEMENTARY_BASE: UInt32 = 65536
@When[os == "Windows"]
private let UTF16_HIGH_SURROGATE: UInt32 = 0xD800
@When[os == "Windows"]
private let UTF16_LOW_SURROGATE: UInt32 = 0xDC00
@When[os == "Windows"]
private let UTF16_SURROGATE_MASK: UInt32 = 1023
@When[os == "Windows"]
private let NONCLIENT_METRICS_WORDS: Int64 = 126
@When[os == "Windows"]
private let NONCLIENT_METRICS_BYTES: UInt32 = 504
@When[os == "Windows"]
private let SPI_GET_NONCLIENT_METRICS: UInt32 = 0x29
@When[os == "Windows"]
private let NONCLIENT_MESSAGE_FACE_OFFSET: Int64 = 218

@When[os == "Windows"]
@C
internal struct FontGuid {
    var a: UInt32 = 0
    var b: UInt32 = 0
    var c: UInt32 = 0
    var d: UInt32 = 0
}

@When[os == "Windows"]
internal class WindowsFontApi {
    static let dwrite = FontPlatformLibrary(["dwrite.dll"])
    static let user = FontPlatformLibrary(["user32.dll"])
    static let registry = FontPlatformLibrary(["advapi32.dll"])
    static var checkForUpdates: Int32 = 1
}

// These slots belong to documented COM interfaces in dwrite.h; no TTF_Font private layout is used.
@When[os == "Windows"]
internal func fontComMethod(pointer: CPointer<Unit>, slot: Int64): CPointer<Unit> {
    if (pointer.isNull()) {
        throw NativeTextException("Null DirectWrite interface")
    }
    unsafe { CPointer<CPointer<Unit>>(CPointer<CPointer<Unit>>(pointer).read()).read(slot) }
}

@When[os == "Windows"]
internal class FontComScope {
    private let pointers = ArrayList<CPointer<Unit>>()
    func own(result: Int32, pointer: CPointer<Unit>): CPointer<Unit> {
        // Even an unusual failing provider may return a non-null, caller-owned pointer.
        if (pointer.isNotNull()) {
            pointers.add(pointer)
        }
        if (result < 0 || pointer.isNull()) {
            throw NativeTextException("DirectWrite font lookup failed: ${result}")
        }
        pointer
    }
    func close(): Unit {
        var index = pointers.size
        while (index > 0) {
            index -= 1
            let pointer = pointers[index]
            let _ = unsafe { CFunc<(CPointer<Unit>) -> UInt32>(fontComMethod(pointer, 2))(pointer) } // cjcheck-ignore: ignore-result # COM Release returns a diagnostic reference count, not a status
        }
        pointers.clear()
    }
}

@When[os == "Windows"]
internal func fontWide(value: String): CPointer<UInt16> {
    let words = ArrayList<UInt16>()
    for (rune in value.runes()) {
        let scalar = UInt32(rune)
        if (scalar < UTF16_SUPPLEMENTARY_BASE) {
            words.add(UInt16(scalar))
        } else {
            words.add(UInt16(UTF16_HIGH_SURROGATE + ((scalar - UTF16_SUPPLEMENTARY_BASE) >> 10)));
            words.add(UInt16(UTF16_LOW_SURROGATE + ((scalar - UTF16_SUPPLEMENTARY_BASE) & UTF16_SURROGATE_MASK)))
        }
    }
    words.add(0)
    let buffer = unsafe { LibC.malloc<UInt16>(count: words.size) }
    if (buffer.isNull()) {
        throw NativeTextException("Cannot allocate Windows font name")
    }
    for (i in 0..words.size) {
        unsafe { buffer.write(i, words[i]) }
    }
    buffer
}

@When[os == "Windows"]
internal func fontWideString(pointer: CPointer<UInt16>, count: Int64): String {
    let bytes = Array<UInt8>(count * 2) {
        i =>
            let word = unsafe { pointer.read(i / 2) }
            if (i % 2 == 0) {
                UInt8(word >> 8)
            } else {
                UInt8(word & 255)
            }
    }
    sfntUtf16(bytes)
}

@When[os == "Windows"]
internal func windowsUIFont(): String {
    // NONCLIENTMETRICSW from winuser.h: five LOGFONTW structures, padded border width (Vista+).
    let buffer = unsafe { LibC.malloc<UInt32>(count: NONCLIENT_METRICS_WORDS) }
    if (buffer.isNull()) {
        return "Segoe UI"
    }
    try {
        for (i in 0..126) {
            unsafe { buffer.write(i, 0) }
        }
        unsafe { buffer.write(0, NONCLIENT_METRICS_BYTES) }
        let function = WindowsFontApi.user.symbol("SystemParametersInfoW")
        let ok = unsafe { CFunc<(UInt32, UInt32, CPointer<Unit>, UInt32) -> Int32>(function)(SPI_GET_NONCLIENT_METRICS,
            NONCLIENT_METRICS_BYTES, CPointer<Unit>(buffer), 0) }
        if (ok != 0) {
            let name = unsafe { CPointer<UInt16>(buffer) + NONCLIENT_MESSAGE_FACE_OFFSET }
            var length: Int64 = 0
            while (length < 32 && unsafe { name.read(length) } != 0) {
                length += 1
            }
            if (length > 0) {
                return fontWideString(name, length)
            }
        }
    } finally {
        unsafe { LibC.free(buffer) }
    }
    "Segoe UI"
}
