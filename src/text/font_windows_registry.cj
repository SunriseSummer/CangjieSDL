package sdl.text

@When[os == "Windows"]
import std.collection.{ArrayList, HashSet}
@When[os == "Windows"]
import std.env.getVariable

@When[os == "Windows"]
private let FONT_REGISTRY_NAME_CAPACITY: Int64 = 16384
@When[os == "Windows"]
private let FONT_REGISTRY_DATA_WORDS: Int64 = 32768
@When[os == "Windows"]
private let FONT_REGISTRY_DATA_BYTES: UInt32 = 65536
@When[os == "Windows"]
private let FONT_REGISTRY_END: Int32 = 259

@When[os == "Windows"]
internal func platformFontFiles(): Array<NativePlatformFont> {
    let result = ArrayList<NativePlatformFont>()
    let seen = HashSet<String>()
    let keyPath = fontWide("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts")
    let name = unsafe { LibC.malloc<UInt16>(count: FONT_REGISTRY_NAME_CAPACITY) }
    let data = unsafe { LibC.malloc<UInt16>(count: FONT_REGISTRY_DATA_WORDS) }
    try {
        if (name.isNull() || data.isNull()) {
            throw NativeTextException("Cannot allocate font registry buffer")
        }
        let api = WindowsFontApi.registry
        for (root in [IntNative(-2147483646), IntNative(-2147483647)]) {
            var key = CPointer<Unit>()
            let opened = unsafe { CFunc<(IntNative, CPointer<UInt16>, UInt32, UInt32, CPointer<CPointer<Unit>>) -> Int32>(
                api.symbol("RegOpenKeyExW"))(root, keyPath, 0, 0x20019, inout key) }
            if (opened != 0) {
                continue
            }
            try {
                windowsRegistryFonts(key, name, data, result, seen)
            } finally {
                let _ = unsafe { CFunc<(CPointer<Unit>) -> Int32>(api.symbol("RegCloseKey"))(key) } // cjcheck-ignore: ignore-result # best-effort release of a read-only registry handle during scope cleanup
            }
        }
    } finally {
        unsafe { LibC.free(keyPath) };
        unsafe { LibC.free(name) };
        unsafe { LibC.free(data) }
    }
    try {
        for (record in windowsCollectionFonts()) {
            if (seen.add(record.path.toAsciiLower())) {
                result.add(record)
            }
        }
    } catch (_: NativeTextException) {
        // The registry/directories remain usable when DirectWrite is unavailable.
        return result.toArray()
    }
    result.toArray()
}

@When[os == "Windows"]
internal func platformRoleFonts(role: Int32): Array<NativePlatformFont> {
    let name = match (role) {
        case 0 => windowsUIFont()
        case 1 => "Segoe UI"
        case 2 => "Times New Roman"
        case 3 => "Consolas"
        case _ => return []
    }
    platformNamedFonts(name)
}

@When[os == "Windows"]
private func windowsRegistryFonts(key: CPointer<Unit>, name: CPointer<UInt16>, data: CPointer<UInt16>,
    result: ArrayList<NativePlatformFont>, seen: HashSet<String>): Unit {
    let api = WindowsFontApi.registry
    for (index in 0..8192) {
        var nameLength = UInt32(FONT_REGISTRY_NAME_CAPACITY)
        var bytes = FONT_REGISTRY_DATA_BYTES
        var kind: UInt32 = 0
        let status = unsafe { CFunc<(CPointer<Unit>, UInt32, CPointer<UInt16>, CPointer<UInt32>, CPointer<UInt32>,
                CPointer<UInt32>, CPointer<UInt16>, CPointer<UInt32>) -> Int32>(api.symbol("RegEnumValueW"))(key,
            UInt32(index), name, inout nameLength, CPointer<UInt32>(), inout kind, data, inout bytes) }
        if (status == FONT_REGISTRY_END) {
            break
        }
        if (status != 0 || kind != 1 || bytes < 2 || bytes > FONT_REGISTRY_DATA_BYTES || bytes % 2 != 0) {
            continue
        }
        var path = fontWideString(data, Int64(bytes / 2))
        if (!path.contains(":") && !path.startsWith("\\")) {
            path = getVariable("WINDIR").getOrDefault({=> "C:/Windows"}) + "/Fonts/" + path
        }
        if (!path.isEmpty() && seen.add(path.toAsciiLower())) {
            result.add(NativePlatformFont(path, -1, ""))
        }
    }
}
