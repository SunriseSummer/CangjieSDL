package sdl

import std.collection.HashMap
import std.sync.Mutex

/** A window-owned reference to the current Cangjie thread's native-thread binding. */
internal class NativeThreadBinding {
    private let owner: Int64
    private var released = false

    init() {
        this.owner = Thread.currentThread.id
        NativeThreadBindings.acquire(owner)
    }

    /** Throws IllegalStateException for a wrong owner or an inconsistent runtime binding. */
    func release(): Unit {
        if (Thread.currentThread.id != owner) {
            throw IllegalStateException("Native thread binding must be released by its owner")
        }
        if (!released) {
            NativeThreadBindings.release(owner)
            released = true
        }
    }
}

// A separate count per Cangjie thread lets windows share one runtime binding. Only this
// registry binds/unbinds; ownership of a binding installed by another host is never guessed.
private class NativeThreadBindings {
    private static let lock = Mutex()
    private static let references = HashMap<Int64, Int64>()

    /** Throws IllegalStateException if the runtime cannot establish a new binding. */
    static func acquire(owner: Int64): Unit {
        synchronized(lock) {
            if (let Some(count) <- references.get(owner)) {
                references[owner] = count + 1
            } else {
                if (unsafe { CJ_BindOSThread() } != 0) {
                    throw IllegalStateException("Cannot bind the UI thread; a host may already own its binding")
                }
                references[owner] = 1
            }
        }
    }

    /** Throws IllegalStateException if a live reference or its matching runtime binding is missing. */
    static func release(owner: Int64): Unit {
        synchronized(lock) {
            match (references.get(owner)) {
                case Some(count) where count > 1 => references[owner] = count - 1
                case Some(_) =>
                    if (unsafe { CJ_UnbindOSThread() } != 0) {
                        throw IllegalStateException("Cannot release the UI thread's native binding")
                    }
                    if (references.remove(owner).isNone()) {
                        throw IllegalStateException("Native thread binding reference disappeared")
                    }
                case None => throw IllegalStateException("Native thread binding reference is missing")
            }
        }
    }
}
