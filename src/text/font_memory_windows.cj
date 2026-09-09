package sdl.text

@When[os == "Windows"]
private struct FontViewAddresses {
    let prefix: CPointer<Unit>
    let content: CPointer<Unit>
    let tail: CPointer<Unit>
    init(prefix: CPointer<Unit>, content: CPointer<Unit>, tail: CPointer<Unit>) {
        this.prefix = prefix
        this.content = content
        this.tail = tail
    }
}

@When[os == "Windows"]
internal class FontMemoryView {
    let bytes: CPointer<UInt8>
    let length: Int64
    private let addresses: FontViewAddresses
    init(source: FontFileMapping, plan: SfntMemoryPlan) {
        let addresses = allocateFontAddresses(source, plan)
        let bytes = unsafe { CPointer<UInt8>(addresses.prefix) }
        try {
            fillMappedFontView(bytes, source, plan)
        } catch (error: Exception) {
            releaseFontAddresses(addresses);
            throw error
        }
        this.bytes = bytes
        this.length = plan.length
        this.addresses = addresses
    }
    func close(): Unit {
        releaseFontAddresses(addresses)
    }
}

@When[os == "Windows"]
private func allocateFontAddresses(source: FontFileMapping, plan: SfntMemoryPlan): FontViewAddresses {
    let tailLength = if (source.length > plan.filePrefixLength) {
        FONT_VIEW_GRANULARITY
    } else {
        Int64(0)
    }
    let total = plan.fileOffset + plan.filePrefixLength + tailLength
    let api = FontMappingApi.library
    // A transient reservation chooses a suitably aligned hole. Each subsequent operation requires
    // its exact address; another thread taking part of the hole causes rollback and a bounded retry.
    for (_ in 0..8) {
        let base = allocateFontPages(CPointer<Unit>(), total, commit: false)
        if (base.isNull()) {
            break
        }
        releaseFontPages(base)
        let prefix = allocateFontPages(base, plan.fileOffset, commit: true)
        if (prefix.isNull()) {
            continue
        }
        var content = CPointer<Unit>();
        var tail = CPointer<Unit>()
        var valid = true
        try {
            if (plan.filePrefixLength > 0) {
                let target = unsafe { CPointer<Unit>(CPointer<UInt8>(base) + plan.fileOffset) }
                content = unsafe { CFunc<(CPointer<Unit>, UInt32, UInt32, UInt32, UIntNative, CPointer<Unit>) -> CPointer<Unit>>(
                    api.symbol("MapViewOfFileEx"))(source.handle, 4, 0, 0, UIntNative(plan.filePrefixLength), target) }
                valid = content.isNotNull()
            }
            if (valid && tailLength > 0) {
                let target = unsafe { CPointer<Unit>(CPointer<UInt8>(base) + plan.fileOffset + plan.filePrefixLength) }
                tail = allocateFontPages(target, tailLength, commit: true)
                valid = tail.isNotNull()
            }
        } catch (error: Exception) {
            releaseFontAddresses(FontViewAddresses(prefix, content, tail));
            throw error
        }
        if (valid) {
            return FontViewAddresses(prefix, content, tail)
        }
        releaseFontAddresses(FontViewAddresses(prefix, content, tail))
    }
    throw NativeTextException("Cannot reserve a contiguous font memory view")
}

@When[os == "Windows"]
private func allocateFontPages(address: CPointer<Unit>, length: Int64, commit!: Bool): CPointer<Unit> {
    unsafe { CFunc<(CPointer<Unit>, UIntNative, UInt32, UInt32) -> CPointer<Unit>>(
        FontMappingApi.library.symbol("VirtualAlloc"))(address, UIntNative(length), if (commit) {
        UInt32(0x3000)
    } else {
        UInt32(0x2000)
    }, 4) }
}

@When[os == "Windows"]
private func releaseFontPages(address: CPointer<Unit>): Unit {
    if (address.isNotNull()) {
        // cjcheck-ignore: ignore-result # release the exact region owned by this view; no data needs flushing
        let _ = unsafe { CFunc<(CPointer<Unit>, UIntNative, UInt32) -> Int32>(
            FontMappingApi.library.symbol("VirtualFree"))(address, 0, 0x8000) }
    }
}

@When[os == "Windows"]
private func releaseFontAddresses(addresses: FontViewAddresses): Unit {
    if (addresses.content.isNotNull()) {
        // cjcheck-ignore: ignore-result # final release of an owned read-only view
        let _ = unsafe { CFunc<(CPointer<Unit>) -> Int32>(FontMappingApi.library.symbol("UnmapViewOfFile"))(
            addresses.content) }
    }
    releaseFontPages(addresses.tail);
    releaseFontPages(addresses.prefix)
}
