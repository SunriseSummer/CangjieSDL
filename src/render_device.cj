package sdl

/*
 * Shared identity and lifetime for one SDL_Renderer and every Texture/TextMeasureSession created
 * from it. SDL rendering APIs are main-thread operations; retaining the creating Cangjie thread id
 * turns accidental cross-thread access and use-after-renderer-close into deterministic exceptions.
 */
internal class RenderDeviceToken {
    private let ownerThreadId: Int64 = Thread.currentThread.id
    private let nativeOwner: UInt64
    private var active: Bool = true
    private var generation: UInt64 = UInt64(0)

    init(native!: Bool = false) {
        this.nativeOwner = if (native) {
            unsafe { SDL_GetCurrentThreadID() }
        } else {
            UInt64(0)
        }
    }

    /** Throws IllegalStateException when the caller is not the owner or resources are closed. */
    func ensureAccess(operation: String): Unit {
        ensureOwner(operation)
        if (!active) {
            throw IllegalStateException("${operation} cannot use a closed Renderer")
        }
    }

    /** Throws IllegalStateException on a different Cangjie or native thread, even after resource release. */
    func ensureOwner(operation: String): Unit {
        if (Thread.currentThread.id != ownerThreadId) {
            throw IllegalStateException("${operation} must run on the Renderer owner thread")
        }
        if (nativeOwner != UInt64(0) && unsafe { SDL_GetCurrentThreadID() } != nativeOwner) {
            throw IllegalStateException(
                "${operation} must stay on the creating native thread; avoid suspending the UI thread")
        }
    }

    func isActive(): Bool {
        active
    }

    func currentGeneration(): UInt64 {
        generation
    }

    func advanceGeneration(): Unit {
        ensureAccess("reset Renderer resources")
        generation = if (generation == UInt64.Max) {
            UInt64(0)
        } else {
            generation + UInt64(1)
        }
    }

    func invalidate(): Unit {
        ensureAccess("Renderer resource release")
        active = false
    }
}
