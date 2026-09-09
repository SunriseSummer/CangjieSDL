package sdl.text

@C
struct TtfSubstringRect {
    var x: Int32 = 0
    var y: Int32 = 0
    var w: Int32 = 0
    var h: Int32 = 0
}

@C
struct TtfSubstring {
    var flags: UInt32 = UInt32(0)
    var offset: Int32 = 0
    var length: Int32 = 0
    var lineIndex: Int32 = 0
    var clusterIndex: Int32 = 0
    var rect = TtfSubstringRect()
}

foreign {
    func TTF_Init(): Bool

    func TTF_OpenFont(file: CString, pointSize: Float32): CPointer<Unit>

    func TTF_OpenFontWithProperties(props: UInt32): CPointer<Unit>

    func SDL_CreateProperties(): UInt32

    func SDL_DestroyProperties(props: UInt32): Unit

    func SDL_SetStringProperty(props: UInt32, name: CString, value: CString): Bool

    func SDL_SetNumberProperty(props: UInt32, name: CString, value: Int64): Bool

    func SDL_SetFloatProperty(props: UInt32, name: CString, value: Float32): Bool

    func TTF_GetFontStyle(font: CPointer<Unit>): Int32

    func TTF_GetNumFontFaces(font: CPointer<Unit>): Int32

    func TTF_GetFontStyleName(font: CPointer<Unit>): CString

    func TTF_GetFontAscent(font: CPointer<Unit>): Int32

    func TTF_GetFontDescent(font: CPointer<Unit>): Int32

    func TTF_GetFontHeight(font: CPointer<Unit>): Int32

    func TTF_GetFontLineSkip(font: CPointer<Unit>): Int32

    func TTF_SetFontStyle(font: CPointer<Unit>, style: Int32): Unit

    func TTF_AddFallbackFont(font: CPointer<Unit>, fallback: CPointer<Unit>): Bool

    func TTF_ClearFallbackFonts(font: CPointer<Unit>): Unit

    func TTF_GetFontFamilyName(font: CPointer<Unit>): CString

    func TTF_GetStringSize(
        font: CPointer<Unit>,
        text: CString,
        length: UIntNative,
        width: CPointer<Int32>,
        height: CPointer<Int32>
    ): Bool

    func TTF_MeasureString(
        font: CPointer<Unit>,
        text: CString,
        length: UIntNative,
        maxWidth: Int32,
        measuredWidth: CPointer<Int32>,
        measuredLength: CPointer<UIntNative>
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

    func TTF_GetTextSubStringForPoint(
        text: CPointer<Unit>,
        x: Int32,
        y: Int32,
        substring: CPointer<TtfSubstring>
    ): Bool

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
