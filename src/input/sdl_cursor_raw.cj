package sdl.input

foreign {
    func SDL_CreateSystemCursor(id: Int32): CPointer<Unit>

    func SDL_SetCursor(cursor: CPointer<Unit>): Bool

    func SDL_GetDefaultCursor(): CPointer<Unit>

    func SDL_DestroyCursor(cursor: CPointer<Unit>): Unit

    func SDL_ShowCursor(): Bool

    func SDL_HideCursor(): Bool

    func SDL_CursorVisible(): Bool
}
