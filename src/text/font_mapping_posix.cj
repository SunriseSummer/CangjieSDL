package sdl.text

@When[os == "Linux"]
internal class FontMappingApi {
    static let library = FontPlatformLibrary(["libc.so.6", "libc.so"])
}

@When[os == "macOS"]
internal class FontMappingApi {
    static let library = FontPlatformLibrary(["/usr/lib/libSystem.B.dylib"])
}

@When[os != "Windows"]
internal class FontFileMapping {
    let bytes: CPointer<UInt8>
    let length: Int64
    let descriptor: Int32
    let checksum: UInt32
    var references: Int64 = 1
    init(path: String, length: Int64, knownChecksum!: ?UInt32 = None) {
        this.length = length
        let api = FontMappingApi.library
        let name = unsafe { LibC.mallocCString(path) }
        var file: Int32 = -1
        var address = CPointer<Unit>()
        try (resource = name.asResource()) {
            file = unsafe { CFunc<(CString, Int32) -> Int32>(api.symbol("open"))(resource.value, 0) }
            if (file < 0) {
                throw NativeTextException("Cannot open mapped font file")
            }
            try {
                address = unsafe { CFunc<(CPointer<Unit>, UIntNative, Int32, Int32, Int32, Int64) -> CPointer<Unit>>(
                    api.symbol("mmap"))(CPointer<Unit>(), UIntNative(length), 1, 2, file, 0) }
                if (address.toUIntNative() == UIntNative.Max) {
                    throw NativeTextException("Cannot map font file")
                }
            } catch (error: Exception) {
                let _ = unsafe { CFunc<(Int32) -> Int32>(api.symbol("close"))(file) } // cjcheck-ignore: ignore-result # failure cleanup releases the read-only descriptor before propagating the original error
                throw error
            }
        }
        let bytes = unsafe { CPointer<UInt8>(address) }
        this.bytes = bytes
        this.descriptor = file
        this.checksum = knownChecksum.getOrDefault({=> mappedFontChecksum(bytes, length)})
    }
    func close(): Unit {
        let _ = unsafe { CFunc<(Int32) -> Int32>(FontMappingApi.library.symbol("close"))(descriptor) } // cjcheck-ignore: ignore-result # final release of the shared read-only descriptor

        // cjcheck-ignore: ignore-result # final release of an immutable mapping; no buffered writes to recover
        let _ = unsafe { CFunc<(CPointer<UInt8>, UIntNative) -> Int32>(FontMappingApi.library.symbol("munmap"))(bytes,
            UIntNative(length)) }
    }
}
