package sdl.text

foreign {
    func SDL_LoadObject(path: CString): CPointer<Unit>

    func SDL_LoadFunction(handle: CPointer<Unit>, name: CString): CPointer<Unit>

    func SDL_UnloadObject(handle: CPointer<Unit>): Unit
}
