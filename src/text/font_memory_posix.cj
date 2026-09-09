package sdl.text

@When[os == "Linux"]
private let FONT_MAP_ANONYMOUS: Int32 = 0x20
@When[os == "macOS"]
private let FONT_MAP_ANONYMOUS: Int32 = 0x1000

@When[os != "Windows"]
internal class FontMemoryView {
    let bytes: CPointer<UInt8>
    let length: Int64
    private let allocationLength: UIntNative
    init(source: FontFileMapping, plan: SfntMemoryPlan) {
        let size = UIntNative(plan.fileOffset + plan.filePrefixLength + FONT_VIEW_GRANULARITY)
        let api = FontMappingApi.library
        let map = unsafe { CFunc<(CPointer<Unit>, UIntNative, Int32, Int32, Int32, Int64) -> CPointer<Unit>>(
            api.symbol("mmap")) }
        let base = unsafe { map(CPointer<Unit>(), size, 3, 2 | FONT_MAP_ANONYMOUS, -1, 0) }
        if (base.toUIntNative() == UIntNative.Max) {
            throw NativeTextException("Cannot reserve font memory")
        }
        let bytes = unsafe { CPointer<UInt8>(base) }
        try {
            if (plan.filePrefixLength > 0) {
                let target = unsafe { CPointer<Unit>(bytes + plan.fileOffset) }
                // MAP_FIXED only replaces pages in the anonymous reservation owned by this view.
                let content = unsafe { map(target, UIntNative(plan.filePrefixLength), 1, 2 | 0x10, source.descriptor, 0) }
                if (content.toUIntNative() == UIntNative.Max) {
                    throw NativeTextException("Cannot map font outline pages")
                }
            }
            fillMappedFontView(bytes, source, plan)
        } catch (error: Exception) {
            releaseFontMemory(bytes, size);
            throw error
        }
        this.bytes = bytes
        this.length = plan.length
        this.allocationLength = size
    }
    func close(): Unit {
        releaseFontMemory(bytes, allocationLength)
    }
}

@When[os != "Windows"]
private func releaseFontMemory(bytes: CPointer<UInt8>, length: UIntNative): Unit {
    // cjcheck-ignore: ignore-result # the complete range is owned by this view and has no pending writes
    let _ = unsafe { CFunc<(CPointer<UInt8>, UIntNative) -> Int32>(FontMappingApi.library.symbol("munmap"))(bytes,
        length) }
}
