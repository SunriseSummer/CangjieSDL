package sdl

internal let SDL_PIXELFORMAT_RGBA32: UInt32 = UInt32(0x16762004)

// Public SDL_Surface prefix; read-only metadata, never used to allocate a native surface.
@C
internal struct SdlSurfaceHeader {
    var flags: UInt32 = UInt32(0)
    var format: UInt32 = UInt32(0)
    var width: Int32 = 0
    var height: Int32 = 0
    var pitch: Int32 = 0
    var pixels = CPointer<UInt8>()
}

foreign {
    func SDL_ConvertSurface(surface: CPointer<Unit>, format: UInt32): CPointer<Unit>

    func SDL_LockSurface(surface: CPointer<Unit>): Bool

    func SDL_UnlockSurface(surface: CPointer<Unit>): Unit

    func SDL_CreateSurface(width: Int32, height: Int32, format: UInt32): CPointer<Unit>

    func SDL_DestroySurface(surface: CPointer<Unit>): Unit

    func SDL_SetSurfaceBlendMode(surface: CPointer<Unit>, blendMode: UInt32): Bool

    func SDL_BlitSurface(source: CPointer<Unit>, sourceRect: CPointer<SdlRect>, destination: CPointer<Unit>,
        destinationRect: CPointer<SdlRect>): Bool

    func SDL_LoadBMP(file: CString): CPointer<Unit>

    func SDL_LoadPNG(file: CString): CPointer<Unit>

    func SDL_SaveBMP(surface: CPointer<Unit>, file: CString): Bool

    func SDL_WriteSurfacePixel(
        surface: CPointer<Unit>,
        x: Int32,
        y: Int32,
        r: UInt8,
        g: UInt8,
        b: UInt8,
        a: UInt8
    ): Bool

    func SDL_ClearSurface(surface: CPointer<Unit>, r: Float32, g: Float32, b: Float32, a: Float32): Bool
}
