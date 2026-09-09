package sdl.text

@When[os == "Windows"]
import std.collection.{ArrayList, HashSet}

@When[os == "Windows"]
private let DWRITE_FACTORY_IID_A: UInt32 = 0xb859ee5a
@When[os == "Windows"]
private let DWRITE_FACTORY_IID_B: UInt32 = 0x4b5bd838
@When[os == "Windows"]
private let DWRITE_FACTORY_IID_C: UInt32 = 0xdc1ae8a2
@When[os == "Windows"]
private let DWRITE_FACTORY_IID_D: UInt32 = 0x48db937d
@When[os == "Windows"]
private let DWRITE_LOCAL_LOADER_IID_A: UInt32 = 0xb2d9f3ec
@When[os == "Windows"]
private let DWRITE_LOCAL_LOADER_IID_B: UInt32 = 0x4a11c9fe
@When[os == "Windows"]
private let DWRITE_LOCAL_LOADER_IID_C: UInt32 = 0x62d8eca2
@When[os == "Windows"]
private let DWRITE_LOCAL_LOADER_IID_D: UInt32 = 0xa2c0f708

@When[os == "Windows"]
internal func platformNamedFonts(name: String): Array<NativePlatformFont> {
    let scope = FontComScope()
    let wide = fontWide(name)
    try {
        let collection = windowsFontCollection(scope)
        var index: UInt32 = 0
        var exists: Int32 = 0
        let found = unsafe { CFunc<(CPointer<Unit>, CPointer<UInt16>, CPointer<UInt32>, CPointer<Int32>) -> Int32>(
            fontComMethod(collection, 5))(collection, wide, inout index, inout exists) }
        if (found < 0 || exists == 0) {
            return []
        }
        var family = CPointer<Unit>()
        let gotFamily = unsafe { CFunc<(CPointer<Unit>, UInt32, CPointer<CPointer<Unit>>) -> Int32>(
            fontComMethod(collection, 4))(collection, index, inout family) }
        scope.own(gotFamily, family)
        windowsFamilyFonts(family, name)
    } finally {
        scope.close();
        unsafe { LibC.free(wide) }
    }
}

@When[os == "Windows"]
private func windowsFontCollection(scope: FontComScope): CPointer<Unit> {
    var iid = FontGuid()
    iid.a = DWRITE_FACTORY_IID_A
    iid.b = DWRITE_FACTORY_IID_B
    iid.c = DWRITE_FACTORY_IID_C
    iid.d = DWRITE_FACTORY_IID_D
    var factory = CPointer<Unit>()
    let create = WindowsFontApi.dwrite.symbol("DWriteCreateFactory")
    let status = unsafe { CFunc<(Int32, CPointer<FontGuid>, CPointer<CPointer<Unit>>) -> Int32>(create)(0, inout iid,
        inout factory) }
    scope.own(status, factory)
    var collection = CPointer<Unit>()
    let gotCollection = unsafe { CFunc<(CPointer<Unit>, CPointer<CPointer<Unit>>, Int32) -> Int32>(
        fontComMethod(factory, 3))(factory, inout collection, WindowsFontApi.checkForUpdates) }
    scope.own(gotCollection, collection)
    WindowsFontApi.checkForUpdates = 0
    collection
}

// Explicit catalog enumeration also includes file-backed fonts supplied by app packages,
// which need not appear in the legacy machine/user Fonts registry keys.
@When[os == "Windows"]
internal func windowsCollectionFonts(): Array<NativePlatformFont> {
    let scope = FontComScope()
    let result = ArrayList<NativePlatformFont>()
    let seen = HashSet<String>()
    try {
        let collection = windowsFontCollection(scope)
        let count = unsafe { CFunc<(CPointer<Unit>) -> UInt32>(fontComMethod(collection, 3))(collection) }
        for (i in 0..min(Int64(count), 4096)) {
            for (record in windowsCollectionFamily(collection, UInt32(i))) {
                if (seen.add(record.path.toAsciiLower())) {
                    result.add(record)
                }
            }
        }
    } finally {
        scope.close()
    }
    result.toArray()
}

@When[os == "Windows"]
private func windowsCollectionFamily(collection: CPointer<Unit>, index: UInt32): Array<NativePlatformFont> {
    let scope = FontComScope()
    try {
        var family = CPointer<Unit>()
        let status = unsafe { CFunc<(CPointer<Unit>, UInt32, CPointer<CPointer<Unit>>) -> Int32>(
            fontComMethod(collection, 4))(collection, index, inout family) }
        scope.own(status, family)
        windowsFamilyFonts(family, "")
    } catch (_: NativeTextException) {
        []
    } finally {
        scope.close()
    }
}

@When[os == "Windows"]
private func windowsFontFaceFile(face: CPointer<Unit>, name: String, scope: FontComScope): ?NativePlatformFont {
    var count: UInt32 = 0
    let files = fontComMethod(face, 4)
    let status = unsafe { CFunc<(CPointer<Unit>, CPointer<UInt32>, CPointer<CPointer<Unit>>) -> Int32>(files)(face,
        inout count, CPointer<CPointer<Unit>>()) }
    if (status < 0 || count != 1) {
        return None
    }
    var file = CPointer<Unit>()
    let gotFile = unsafe { CFunc<(CPointer<Unit>, CPointer<UInt32>, CPointer<CPointer<Unit>>) -> Int32>(files)(face,
        inout count, inout file) }
    scope.own(gotFile, file)
    var loader = CPointer<Unit>()
    let gotLoader = unsafe { CFunc<(CPointer<Unit>, CPointer<CPointer<Unit>>) -> Int32>(fontComMethod(file, 4))(file,
        inout loader) }
    scope.own(gotLoader, loader)
    var iid = FontGuid()
    iid.a = DWRITE_LOCAL_LOADER_IID_A
    iid.b = DWRITE_LOCAL_LOADER_IID_B
    iid.c = DWRITE_LOCAL_LOADER_IID_C
    iid.d = DWRITE_LOCAL_LOADER_IID_D
    var local = CPointer<Unit>()
    let gotLocal = unsafe { CFunc<(CPointer<Unit>, CPointer<FontGuid>, CPointer<CPointer<Unit>>) -> Int32>(
        fontComMethod(loader, 0))(loader, inout iid, inout local) }
    scope.own(gotLocal, local)
    var key = CPointer<Unit>()
    var size: UInt32 = 0
    let gotKey = unsafe { CFunc<(CPointer<Unit>, CPointer<CPointer<Unit>>, CPointer<UInt32>) -> Int32>(
        fontComMethod(file, 3))(file, inout key, inout size) }
    if (gotKey < 0) {
        return None
    }
    match (windowsFontFilePath(local, key, size)) {
        case Some(path) =>
            let index = unsafe { CFunc<(CPointer<Unit>) -> UInt32>(fontComMethod(face, 5))(face) }
            Some(NativePlatformFont(path, Int64(index), name))
        case None => None
    }
}

@When[os == "Windows"]
private func windowsFamilyFonts(family: CPointer<Unit>, name: String): Array<NativePlatformFont> {
    let count = unsafe { CFunc<(CPointer<Unit>) -> UInt32>(fontComMethod(family, 4))(family) }
    let result = ArrayList<NativePlatformFont>()
    let seen = HashSet<String>()
    for (i in 0..min(Int64(count), 4096)) {
        let one = FontComScope()
        try {
            var font = CPointer<Unit>()
            let gotFont = unsafe { CFunc<(CPointer<Unit>, UInt32, CPointer<CPointer<Unit>>) -> Int32>(
                fontComMethod(family, 5))(family, UInt32(i), inout font) }
            one.own(gotFont, font)
            var face = CPointer<Unit>()
            let gotFace = unsafe { CFunc<(CPointer<Unit>, CPointer<CPointer<Unit>>) -> Int32>(fontComMethod(font, 13))(
                font, inout face) }
            one.own(gotFace, face)
            if (let Some(record) <- windowsFontFaceFile(face, name, one)) {
                if (seen.add("${record.path}:${record.index}")) {
                    result.add(record)
                }
            }
        } catch (_: NativeTextException) {
            continue
        } finally {
            one.close()
        }
    }
    result.toArray()
}

@When[os == "Windows"]
private func windowsFontFilePath(local: CPointer<Unit>, key: CPointer<Unit>, size: UInt32): ?String {
    var length: UInt32 = 0
    let gotLength = unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>, UInt32, CPointer<UInt32>) -> Int32>(
        fontComMethod(local, 4))(local, key, size, inout length) }
    if (gotLength < 0 || length == 0 || length > 32767) {
        return None
    }
    let buffer = unsafe { LibC.malloc<UInt16>(count: Int64(length) + 1) }
    if (buffer.isNull()) {
        throw NativeTextException("Cannot allocate font filename")
    }
    try {
        let gotPath = unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>, UInt32, CPointer<UInt16>, UInt32) -> Int32>(
            fontComMethod(local, 5))(local, key, size, buffer, length + 1) }
        if (gotPath < 0) {
            return None
        }
        Some(fontWideString(buffer, Int64(length)))
    } finally {
        unsafe { LibC.free(buffer) }
    }
}
