package sdl.text

@When[os == "macOS"]
import std.collection.ArrayList

@When[os == "macOS"]
internal class MacFontApi {
    static let text = FontPlatformLibrary(["/System/Library/Frameworks/CoreText.framework/CoreText"])
    static let foundation = FontPlatformLibrary(["/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"])
}

@When[os == "macOS"]
internal class FontCfScope {
    private let values = ArrayList<CPointer<Unit>>()
    func own(value: CPointer<Unit>): CPointer<Unit> {
        if (value.isNull()) {
            throw NativeTextException("CoreText font query failed")
        }
        values.add(value);
        value
    }
    func close(): Unit {
        var index = values.size
        while (index > 0) {
            index -= 1
            unsafe { CFunc<(CPointer<Unit>) -> Unit>(MacFontApi.foundation.symbol("CFRelease"))(values[index]) }
        }
        values.clear()
    }
}

@When[os == "macOS"]
internal func fontCfString(value: String, scope: FontCfScope): CPointer<Unit> {
    let bytes = unsafe { LibC.mallocCString(value) }
    var result = CPointer<Unit>()
    try (resource = bytes.asResource()) {
        result = scope.own(
            unsafe { CFunc<(CPointer<Unit>, CString, UInt32) -> CPointer<Unit>>(
                MacFontApi.foundation.symbol("CFStringCreateWithCString"))(CPointer<Unit>(), resource.value, 0x08000100) })
    }
    result
}

@When[os == "macOS"]
internal func fontCfText(value: CPointer<Unit>): String {
    if (value.isNull()) {
        return ""
    }
    let api = MacFontApi.foundation
    let count = unsafe { CFunc<(CPointer<Unit>) -> IntNative>(api.symbol("CFStringGetLength"))(value) }
    if (count < 0 || count > 32768) {
        throw NativeTextException("Invalid CoreText font string length")
    }
    let bytes = unsafe { LibC.malloc<UInt8>(count: Int64(count) * 4 + 1) }
    if (bytes.isNull()) {
        throw NativeTextException("Cannot allocate CoreText font name")
    }
    try {
        let ok = unsafe { CFunc<(CPointer<Unit>, CPointer<UInt8>, IntNative, UInt32) -> Bool>(
            api.symbol("CFStringGetCString"))(value, bytes, count * 4 + 1, 0x08000100) }
        if (!ok) {
            throw NativeTextException("Cannot decode CoreText font name")
        }
        unsafe { CString(bytes).toString() }
    } finally {
        unsafe { LibC.free(bytes) }
    }
}

@When[os == "macOS"]
internal func fontCfAttribute(descriptor: CPointer<Unit>, name: String): CPointer<Unit> {
    let key = unsafe { CPointer<CPointer<Unit>>(MacFontApi.text.symbol(name)).read() }
    unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>) -> CPointer<Unit>>(
        MacFontApi.text.symbol("CTFontDescriptorCopyAttribute"))(descriptor, key) }
}

@When[os == "macOS"]
internal func fontCfRows(array: CPointer<Unit>): Array<NativePlatformFont> {
    let api = MacFontApi.foundation
    let count = unsafe { CFunc<(CPointer<Unit>) -> IntNative>(api.symbol("CFArrayGetCount"))(array) }
    if (count < 0 || count > 65536) {
        throw NativeTextException("CoreText font result is too large")
    }
    let output = ArrayList<NativePlatformFont>()
    for (i in 0..Int64(count)) {
        let descriptor = unsafe { CFunc<(CPointer<Unit>, IntNative) -> CPointer<Unit>>(
            api.symbol("CFArrayGetValueAtIndex"))(array, IntNative(i)) }
        let scope = FontCfScope()
        try {
            let url = scope.own(fontCfAttribute(descriptor, "kCTFontURLAttribute"))
            let name = scope.own(fontCfAttribute(descriptor, "kCTFontFamilyNameAttribute"))
            let path = scope.own(
                unsafe { CFunc<(CPointer<Unit>, Int32) -> CPointer<Unit>>(api.symbol("CFURLCopyFileSystemPath"))(url, 0) })
            output.add(NativePlatformFont(fontCfText(path), -1, fontCfText(name)))
        } catch (_: NativeTextException) {
            continue
        } finally {
            scope.close()
        }
    }
    output.toArray()
}
