package sdl.system

internal let SDL_NS_PER_MS: UInt64 = UInt64(1000000)

foreign {
    func SDL_GetTicks(): UInt64

    func SDL_GetTicksNS(): UInt64

    func SDL_GetPerformanceCounter(): UInt64

    func SDL_GetPerformanceFrequency(): UInt64

    func SDL_DelayNS(ns: UInt64): Unit

    func SDL_DelayPrecise(ns: UInt64): Unit
}
