package sdl.text

@When[os == "macOS"]
internal func platformNamedFonts(name: String): Array<NativePlatformFont> {
    let scope = FontCfScope()
    let cf = MacFontApi.foundation
    let ct = MacFontApi.text
    try {
        var key = unsafe { CPointer<CPointer<Unit>>(ct.symbol("kCTFontFamilyNameAttribute")).read() }
        var value = fontCfString(name, scope)
        let attributes = scope.own(
            unsafe { CFunc<(CPointer<Unit>, CPointer<CPointer<Unit>>, CPointer<CPointer<Unit>>, IntNative, CPointer<Unit>,
                    CPointer<Unit>) -> CPointer<Unit>>(cf.symbol("CFDictionaryCreate"))(CPointer<Unit>(), inout key,
                inout value, 1, cf.symbol("kCFTypeDictionaryKeyCallBacks"), cf.symbol("kCFTypeDictionaryValueCallBacks")) })
        let required = scope.own(
            unsafe { CFunc<(CPointer<Unit>, CPointer<CPointer<Unit>>, IntNative, CPointer<Unit>) -> CPointer<Unit>>(
                cf.symbol("CFSetCreate"))(CPointer<Unit>(), inout key, 1, cf.symbol("kCFTypeSetCallBacks")) })
        let descriptor = scope.own(
            unsafe { CFunc<(CPointer<Unit>) -> CPointer<Unit>>(ct.symbol("CTFontDescriptorCreateWithAttributes"))(
                attributes) })
        let matches = unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>) -> CPointer<Unit>>(
            ct.symbol("CTFontDescriptorCreateMatchingFontDescriptors"))(descriptor, required) }
        if (matches.isNull()) {
            return []
        }
        fontCfRows(scope.own(matches))
    } finally {
        scope.close()
    }
}

@When[os == "macOS"]
internal func platformFontFiles(): Array<NativePlatformFont> {
    let scope = FontCfScope()
    let ct = MacFontApi.text
    try {
        let collection = scope.own(
            unsafe { CFunc<(CPointer<Unit>) -> CPointer<Unit>>(ct.symbol("CTFontCollectionCreateFromAvailableFonts"))(
                CPointer<Unit>()) })
        let fonts = scope.own(
            unsafe { CFunc<(CPointer<Unit>) -> CPointer<Unit>>(
                ct.symbol("CTFontCollectionCreateMatchingFontDescriptors"))(collection) })
        fontCfRows(fonts)
    } finally {
        scope.close()
    }
}

@When[os == "macOS"]
internal func platformRoleFonts(role: Int32): Array<NativePlatformFont> {
    if (role < 0 || role > 3) {
        return []
    }
    if (role != 0) {
        return platformNamedFonts(if (role == 2) {
            "Times"
        } else if (role == 3) {
            "Menlo"
        } else {
            "Helvetica"
        })
    }
    let scope = FontCfScope()
    let ct = MacFontApi.text
    try {
        // kCTFontUIFontSystem = 2, CGFloat is double on supported 64-bit macOS targets.
        let font = scope.own(
            unsafe { CFunc<(Int32, Float64, CPointer<Unit>) -> CPointer<Unit>>(
                ct.symbol("CTFontCreateUIFontForLanguage"))(2, 15.0, CPointer<Unit>()) })
        let descriptor = scope.own(
            unsafe { CFunc<(CPointer<Unit>) -> CPointer<Unit>>(ct.symbol("CTFontCopyFontDescriptor"))(font) })
        let family = scope.own(fontCfAttribute(descriptor, "kCTFontFamilyNameAttribute"))
        let records = platformNamedFonts(fontCfText(family))
        if (!records.isEmpty()) {
            return records
        }
        let url = scope.own(fontCfAttribute(descriptor, "kCTFontURLAttribute"))
        let path = scope.own(
            unsafe { CFunc<(CPointer<Unit>, Int32) -> CPointer<Unit>>(
                MacFontApi.foundation.symbol("CFURLCopyFileSystemPath"))(url, 0) })
        [NativePlatformFont(fontCfText(path), -1, fontCfText(family))]
    } finally {
        scope.close()
    }
}
