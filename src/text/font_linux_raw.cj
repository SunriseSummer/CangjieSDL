package sdl.text

@When[os == "Linux"]
import std.collection.ArrayList
@When[os == "Linux"]
import std.sync.Mutex

@When[os == "Linux"]
@C
internal struct FontconfigSet {
    var count: Int32 = 0
    var capacity: Int32 = 0
    var fonts = CPointer<CPointer<Unit>>()
}

@When[os == "Linux"]
internal class LinuxFontApi {
    static let library = FontPlatformLibrary(["libfontconfig.so.1", "libfontconfig.so"])
    static let lock = Mutex()
    static var config = CPointer<Unit>()
}

@When[os == "Linux"]
internal func fontconfig(): CPointer<Unit> {
    if (LinuxFontApi.config.isNull()) {
        LinuxFontApi.config = unsafe { CFunc<() -> CPointer<Unit>>(
            LinuxFontApi.library.symbol("FcInitLoadConfigAndFonts"))() }
        if (LinuxFontApi.config.isNull()) {
            throw NativeTextException("Fontconfig initialization failed")
        }
    }
    LinuxFontApi.config
}

@When[os == "Linux"]
internal func fontconfigDestroy(name: String, pointer: CPointer<Unit>): Unit {
    if (pointer.isNotNull()) {
        unsafe { CFunc<(CPointer<Unit>) -> Unit>(LinuxFontApi.library.symbol(name))(pointer) }
    }
}

@When[os == "Linux"]
internal func fontconfigPattern(name: String): CPointer<Unit> {
    let api = LinuxFontApi.library
    let pattern = unsafe { CFunc<() -> CPointer<Unit>>(api.symbol("FcPatternCreate"))() }
    if (pattern.isNull()) {
        throw NativeTextException("Cannot allocate Fontconfig pattern")
    }
    try {
        if (!name.isEmpty()) {
            let key = unsafe { LibC.mallocCString("family") }
            let value = unsafe { LibC.mallocCString(name) }
            try (keyResource = key.asResource(), valueResource = value.asResource()) {
                if (unsafe { CFunc<(CPointer<Unit>, CString, CString) -> Int32>(api.symbol("FcPatternAddString"))(
                    pattern, keyResource.value, valueResource.value) } == 0) {
                    throw NativeTextException("Cannot set Fontconfig family")
                }
            }
        }
        pattern
    } catch (error: Exception) {
        fontconfigDestroy("FcPatternDestroy", pattern);
        throw error
    }
}

@When[os == "Linux"]
internal func fontconfigString(pattern: CPointer<Unit>, field: String, index!: Int32 = 0): String {
    let key = unsafe { LibC.mallocCString(field) }
    var value = CString(CPointer<UInt8>())
    try (resource = key.asResource()) {
        let status = unsafe { CFunc<(CPointer<Unit>, CString, Int32, CPointer<CString>) -> Int32>(
            LinuxFontApi.library.symbol("FcPatternGetString"))(pattern, resource.value, index, inout value) }
        if (status != 0 || value.isNull()) {
            return ""
        }
        return value.toString()
    }
    ""
}

@When[os == "Linux"]
internal func fontconfigRows(pattern: CPointer<Unit>, output: ArrayList<NativePlatformFont>): Unit {
    let path = fontconfigString(pattern, "file")
    if (path.isEmpty()) {
        return
    }
    let key = unsafe { LibC.mallocCString("index") }
    var index: Int32 = 0
    try (resource = key.asResource()) {
        let status = unsafe { CFunc<(CPointer<Unit>, CString, Int32, CPointer<Int32>) -> Int32>(
            LinuxFontApi.library.symbol("FcPatternGetInteger"))(pattern, resource.value, 0, inout index) }
        if (status != 0) {
            index = 0
        }
    }
    for (i in 0..256) {
        let family = fontconfigString(pattern, "family", index: Int32(i))
        if (family.isEmpty()) {
            break
        }
        if (index >= 0) {
            output.add(NativePlatformFont(path, Int64(index), family))
        }
    }
}
