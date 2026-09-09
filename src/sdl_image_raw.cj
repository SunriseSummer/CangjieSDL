package sdl

foreign {
    func IMG_Version(): Int32

    func IMG_Load(file: CString): CPointer<Unit>

    func IMG_LoadTyped_IO(stream: CPointer<Unit>, closeio: Bool, kind: CString): CPointer<Unit>

    func IMG_isSVG(stream: CPointer<Unit>): Bool

    func IMG_LoadSizedSVG_IO(stream: CPointer<Unit>, width: Int32, height: Int32): CPointer<Unit>

    func IMG_SaveJPG(surface: CPointer<Unit>, file: CString, quality: Int32): Bool

    func SDL_IOFromFile(file: CString, mode: CString): CPointer<Unit>

    func SDL_IOFromConstMem(bytes: CPointer<Unit>, length: UIntNative): CPointer<Unit>

    func SDL_CloseIO(stream: CPointer<Unit>): Bool

    func SDL_SavePNG(surface: CPointer<Unit>, file: CString): Bool

    func SDL_ScaleSurface(surface: CPointer<Unit>, width: Int32, height: Int32, mode: Int32): CPointer<Unit>

    func SDL_ReadSurfacePixel(surface: CPointer<Unit>, x: Int32, y: Int32, r: CPointer<UInt8>, g: CPointer<UInt8>,
        b: CPointer<UInt8>, a: CPointer<UInt8>): Bool

    func SDL_GetTextureBlendMode(texture: CPointer<Unit>, mode: CPointer<UInt32>): Bool

    func SDL_GetTextureScaleMode(texture: CPointer<Unit>, mode: CPointer<Int32>): Bool

    func memcpy(destination: CPointer<UInt8>, source: CPointer<UInt8>, count: UIntNative): CPointer<UInt8>
}
