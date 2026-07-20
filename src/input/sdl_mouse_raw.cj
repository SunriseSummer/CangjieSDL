package sdl.input

foreign {
    func SDL_GetMouseState(x: CPointer<Float32>, y: CPointer<Float32>): UInt32

    func SDL_CaptureMouse(enabled: Bool): Bool
}
