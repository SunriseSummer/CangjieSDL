package sdl.text

foreign {
    func TTF_Init(): Bool

    func TTF_OpenFont(file: CString, pointSize: Float32): CPointer<Unit>

    func TTF_SetFontStyle(font: CPointer<Unit>, style: Int32): Unit

    func TTF_GetFontFamilyName(font: CPointer<Unit>): CString

    func TTF_GetStringSize(
        font: CPointer<Unit>,
        text: CString,
        length: UIntNative,
        width: CPointer<Int32>,
        height: CPointer<Int32>
    ): Bool

    func TTF_CreateRendererTextEngine(renderer: CPointer<Unit>): CPointer<Unit>

    func TTF_DestroyRendererTextEngine(engine: CPointer<Unit>): Unit

    func TTF_CreateText(
        engine: CPointer<Unit>,
        font: CPointer<Unit>,
        text: CString,
        length: UIntNative
    ): CPointer<Unit>

    func TTF_SetTextString(text: CPointer<Unit>, value: CString, length: UIntNative): Bool

    func TTF_SetTextColor(text: CPointer<Unit>, red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8): Bool

    func TTF_DrawRendererText(text: CPointer<Unit>, x: Float32, y: Float32): Bool

    /*
     * The C parameter is SDL_Color passed BY VALUE. A 4-byte plain struct travels exactly like a
     * 32-bit integer on every ABI this module targets (Win64, SysV x86-64, AArch64), so the
     * binding declares UInt32; byte order r | g<<8 | b<<16 | a<<24 matches SDL_Color's layout.
     */
    func TTF_RenderText_Blended(
        font: CPointer<Unit>,
        text: CString,
        length: UIntNative,
        color: UInt32
    ): CPointer<Unit>

    func TTF_DestroyText(text: CPointer<Unit>): Unit

    func TTF_CloseFont(font: CPointer<Unit>): Unit

    func TTF_Quit(): Unit

    func SDL_GetError(): CString
}
