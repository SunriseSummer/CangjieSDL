package sdl.input

internal let SDL_KMOD_LSHIFT: UInt16 = UInt16(0x0001)
internal let SDL_KMOD_RSHIFT: UInt16 = UInt16(0x0002)
internal let SDL_KMOD_LEVEL5: UInt16 = UInt16(0x0004)
internal let SDL_KMOD_LCTRL: UInt16 = UInt16(0x0040)
internal let SDL_KMOD_RCTRL: UInt16 = UInt16(0x0080)
internal let SDL_KMOD_LALT: UInt16 = UInt16(0x0100)
internal let SDL_KMOD_RALT: UInt16 = UInt16(0x0200)
internal let SDL_KMOD_LGUI: UInt16 = UInt16(0x0400)
internal let SDL_KMOD_RGUI: UInt16 = UInt16(0x0800)
internal let SDL_KMOD_NUM: UInt16 = UInt16(0x1000)
internal let SDL_KMOD_CAPS: UInt16 = UInt16(0x2000)
internal let SDL_KMOD_MODE: UInt16 = UInt16(0x4000)
internal let SDL_KMOD_SCROLL: UInt16 = UInt16(0x8000)

foreign func SDL_GetModState(): UInt16
