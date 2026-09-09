package sdl

foreign func SDL_GetCurrentThreadID(): UInt64

// Cangjie runtime 1.0.5 scheduler exports: 0 succeeds, -1 reports an invalid binding state.
foreign func CJ_BindOSThread(): Int32

foreign func CJ_UnbindOSThread(): Int32
