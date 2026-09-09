package sdl.text

@When[os == "Linux"]
import std.collection.ArrayList

@When[os == "Linux"]
internal func platformNamedFonts(name: String): Array<NativePlatformFont> {
    synchronized(LinuxFontApi.lock) {
        fontconfigList(name)
    }
}

@When[os == "Linux"]
internal func platformFontFiles(): Array<NativePlatformFont> {
    synchronized(LinuxFontApi.lock) {
        fontconfigList("")
    }
}

@When[os == "Linux"]
internal func platformRoleFonts(role: Int32): Array<NativePlatformFont> {
    if (role < 0 || role > 3) {
        return []
    }
    synchronized(LinuxFontApi.lock) {
        let name = if (role == 2) {
            "serif"
        } else if (role == 3) {
            "monospace"
        } else {
            "sans-serif"
        }
        let api = LinuxFontApi.library
        let config = fontconfig()
        let pattern = fontconfigPattern(name)
        var matched = CPointer<Unit>()
        try {
            if (unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>, Int32) -> Int32>(api.symbol("FcConfigSubstitute"))(
                config, pattern, 0) } == 0) {
                return []
            }
            unsafe { CFunc<(CPointer<Unit>) -> Unit>(api.symbol("FcDefaultSubstitute"))(pattern) }
            var status: Int32 = 0
            matched = unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>, CPointer<Int32>) -> CPointer<Unit>>(
                api.symbol("FcFontMatch"))(config, pattern, inout status) }
            if (matched.isNull()) {
                return []
            }
            let family = fontconfigString(matched, "family")
            if (!family.isEmpty()) {
                let members = fontconfigList(family)
                if (!members.isEmpty()) {
                    return members
                }
            }
            let result = ArrayList<NativePlatformFont>()
            fontconfigRows(matched, result)
            result.toArray()
        } finally {
            fontconfigDestroy("FcPatternDestroy", matched);
            fontconfigDestroy("FcPatternDestroy", pattern)
        }
    }
}

@When[os == "Linux"]
private func fontconfigList(name: String): Array<NativePlatformFont> {
    let api = LinuxFontApi.library
    let config = fontconfig()
    let pattern = fontconfigPattern(name)
    var objects = CPointer<Unit>()
    var fonts = CPointer<Unit>()
    try {
        objects = unsafe { CFunc<() -> CPointer<Unit>>(api.symbol("FcObjectSetCreate"))() }
        if (objects.isNull()) {
            throw NativeTextException("Cannot allocate Fontconfig object set")
        }
        for (field in ["file", "index", "family"]) {
            let key = unsafe { LibC.mallocCString(field) }
            try (resource = key.asResource()) {
                if (unsafe { CFunc<(CPointer<Unit>, CString) -> Int32>(api.symbol("FcObjectSetAdd"))(objects,
                    resource.value) } == 0) {
                    throw NativeTextException("Cannot add Fontconfig property")
                }
            }
        }
        fonts = unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>, CPointer<Unit>) -> CPointer<Unit>>(
            api.symbol("FcFontList"))(config, pattern, objects) }
        let result = ArrayList<NativePlatformFont>()
        if (fonts.isNotNull()) {
            let set = unsafe { CPointer<FontconfigSet>(fonts).read() }
            if (set.count < 0 || set.count > 65536 || set.count > set.capacity || (set.count > 0 && set.fonts.isNull())) {
                throw NativeTextException("Invalid Fontconfig result")
            }
            for (i in 0..Int64(set.count)) {
                fontconfigRows(unsafe { set.fonts.read(i) }, result)
            }
        }
        result.toArray()
    } finally {
        fontconfigDestroy("FcFontSetDestroy", fonts);
        fontconfigDestroy("FcObjectSetDestroy", objects)
        fontconfigDestroy("FcPatternDestroy", pattern)
    }
}
