package sdl.text

import std.collection.HashMap
import std.sync.Mutex

private class FontStreamOwners {
    static let lock = Mutex()
    static let owners = HashMap<UIntNative, FontStreamOwner>()
}

private class FontStreamOwner {
    let identity: UInt64
    let view: FontMemoryView
    init(identity: UInt64, view: FontMemoryView) {
        this.identity = identity
        this.view = view
    }
}

// Official SDL's memory stream owns all native callbacks. The underlying contiguous virtual view
// shares read-only outline pages and owns only its small header and final partial page.
internal func openFontView(path: String, view: SfntView): CPointer<Unit> {
    let source = acquireFontMapping(path, view.sourceIdentity)
    var created: ?FontMemoryView = None
    var stream = CPointer<Unit>()
    try {
        let memory = FontMemoryView(source, SfntMemoryPlan(view, source))
        created = Some(memory)
        stream = unsafe { SDL_IOFromConstMem(CPointer<Unit>(memory.bytes), UIntNative(memory.length)) }
        if (stream.isNull()) {
            throw NativeTextException("Cannot open font memory stream")
        }
        synchronized(FontStreamOwners.lock) {
            FontStreamOwners.owners[stream.toUIntNative()] = FontStreamOwner(view.sourceIdentity, memory)
        }
        stream
    } catch (error: Exception) {
        if (stream.isNotNull()) {
            let _ = unsafe { SDL_CloseIO(stream) } // cjcheck-ignore: ignore-result # failure cleanup of a read-only memory stream preserves the original exception
        }
        if (let Some(memory) <- created) {
            memory.close()
        }
        releaseFontMapping(view.sourceIdentity)
        throw error
    }
}

protected func activeFontStreams(): Int64 {
    synchronized(FontStreamOwners.lock) {
        FontStreamOwners.owners.size
    }
}

internal func closeFontView(stream: CPointer<Unit>): Bool {
    if (stream.isNull()) {
        return true
    }
    let owner = synchronized(FontStreamOwners.lock) {
        FontStreamOwners.owners.remove(stream.toUIntNative())
    }
    match (owner) {
        case Some(value) =>
            let result = unsafe { SDL_CloseIO(stream) }
            value.view.close()
            releaseFontMapping(value.identity)
            result
        case None => false
    }
}
