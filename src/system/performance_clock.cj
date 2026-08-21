package sdl.system

/** Exposes SDL's monotonic tick counters, high-resolution performance counter, and delay helpers. */
public class PerformanceClock {
    /** Returns the milliseconds elapsed since SDL initialization. */
    public static func ticksMilliseconds(): UInt64 {
        unsafe { SDL_GetTicks() }
    }

    /** Returns the nanoseconds elapsed since SDL initialization. */
    public static func ticksNanoseconds(): UInt64 {
        unsafe { SDL_GetTicksNS() }
    }

    /** Returns the current value of the high-resolution performance counter. */
    public static func counter(): UInt64 {
        unsafe { SDL_GetPerformanceCounter() }
    }

    /** Returns the number of performance counter increments per second. */
    public static func frequency(): UInt64 {
        unsafe { SDL_GetPerformanceFrequency() }
    }

    /** Blocks the calling thread for at least the given number of nanoseconds. */
    public static func delayNanoseconds(ns: UInt64): Unit {
        unsafe { SDL_DelayNS(ns) }
    }

    /** Blocks the calling thread for the given number of nanoseconds, busy-waiting near the end for higher accuracy. */
    public static func delayPrecise(ns: UInt64): Unit {
        unsafe { SDL_DelayPrecise(ns) }
    }

    /** Converts a millisecond count to nanoseconds. */
    public static func millisecondsToNanoseconds(ms: UInt64): UInt64 {
        ms * SDL_NS_PER_MS
    }
}
