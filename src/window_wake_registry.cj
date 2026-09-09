package sdl

import std.sync.Mutex

// Process-wide SDL event registration shared by window creation and cross-thread wake calls.
internal class WindowWakeEventRegistry {
    private static let lock = Mutex()
    private static var registeredType: UInt32 = UInt32(0)

    static func eventType(): UInt32 {
        var result: UInt32 = UInt32(0)
        synchronized(lock) {
            if (registeredType == UInt32(0)) {
                // SDL3 returns zero when the finite user-event range cannot satisfy a request.
                registeredType = unsafe { SDL_RegisterEvents(1) }
            }
            result = registeredType
        }
        result
    }
}
