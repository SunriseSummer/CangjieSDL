package sdl.text

@When[os == "Windows"]
internal class FontMappingApi {
    static let library = FontPlatformLibrary(["kernel32.dll"])
}

@When[os == "Windows"]
internal class FontFileMapping {
    let bytes: CPointer<UInt8>
    let length: Int64
    let handle: CPointer<Unit>
    let checksum: UInt32
    var references: Int64 = 1
    init(path: String, length: Int64, knownChecksum!: ?UInt32 = None) {
        this.length = length
        let api = FontMappingApi.library
        let name = fontWide(path)
        var file = CPointer<Unit>()
        var mapping = CPointer<Unit>()
        var address = CPointer<Unit>()
        try {
            file = unsafe { CFunc<(CPointer<UInt16>, UInt32, UInt32, CPointer<Unit>, UInt32, UInt32, CPointer<Unit>) -> CPointer<Unit>>(
                api.symbol("CreateFileW"))(name, 0x80000000, 5, CPointer<Unit>(), 3, 0x80, CPointer<Unit>()) }
            if (file.toUIntNative() == UIntNative.Max) {
                file = CPointer<Unit>()
                throw NativeTextException("Cannot open mapped font file")
            }
            mapping = unsafe { CFunc<(CPointer<Unit>, CPointer<Unit>, UInt32, UInt32, UInt32, CPointer<UInt16>) -> CPointer<Unit>>(
                api.symbol("CreateFileMappingW"))(file, CPointer<Unit>(), 2, 0, 0, CPointer<UInt16>()) }
            if (mapping.isNull()) {
                throw NativeTextException("Cannot map font file")
            }
            address = unsafe { CFunc<(CPointer<Unit>, UInt32, UInt32, UInt32, UIntNative) -> CPointer<Unit>>(
                api.symbol("MapViewOfFile"))(mapping, 4, 0, 0, UIntNative(length)) }
            if (address.isNull()) {
                throw NativeTextException("Cannot map font file view")
            }
        } finally {
            unsafe { LibC.free(name) }
            if (address.isNull() && mapping.isNotNull()) {
                closeMappingHandle(mapping)
            }
            if (file.isNotNull()) {
                closeMappingHandle(file)
            }
        }
        let bytes = unsafe { CPointer<UInt8>(address) }
        this.bytes = bytes
        this.handle = mapping
        this.checksum = knownChecksum.getOrDefault({=> mappedFontChecksum(bytes, length)})
    }
    func close(): Unit {
        closeMappingHandle(handle)
        let _ = unsafe { CFunc<(CPointer<UInt8>) -> Int32>(FontMappingApi.library.symbol("UnmapViewOfFile"))(bytes) } // cjcheck-ignore: ignore-result # final release of an immutable view; no buffered writes to recover
    }
}

@When[os == "Windows"]
private func closeMappingHandle(handle: CPointer<Unit>): Unit {
    let _ = unsafe { CFunc<(CPointer<Unit>) -> Int32>(FontMappingApi.library.symbol("CloseHandle"))(handle) } // cjcheck-ignore: ignore-result # final release of an owned read-only mapping handle
}
