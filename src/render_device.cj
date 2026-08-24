package sdl

/*
 * Shared identity and lifetime for one SDL_Renderer and every Texture/TextMeasureSession created
 * from it. SDL rendering APIs are main-thread operations; retaining the creating Cangjie thread id
 * turns accidental cross-thread access and use-after-renderer-close into deterministic exceptions.
 */
internal class RenderDeviceToken {
    private let ownerThreadId: Int64 = Thread.currentThread.id
    private var active: Bool = true
    private var generation: UInt64 = UInt64(0)

    func ensureAccess(operation: String): Unit {
        if (!active) {
            throw IllegalStateException("${operation} cannot use a closed Renderer")
        }
        if (Thread.currentThread.id != ownerThreadId) {
            throw IllegalStateException("${operation} must run on the Renderer owner thread")
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
