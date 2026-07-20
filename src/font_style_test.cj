package sdl

@Test
func fontStyleRegularHasNoFlags(): Unit {
    @Expect(FontStyle.regular.isRegular)
    @Expect(FontStyle.regular.ttfFlags(), 0)
    @Expect(!FontStyle().bold)
    @Expect(!FontStyle().italic)
    @Expect(!FontStyle().underline)
    @Expect(!FontStyle().strikethrough)
}

@Test
func fontStylePacksTtfBitmask(): Unit {
    // The individual flags match the SDL_ttf TTF_STYLE_* ABI values.
    @Expect(FontStyle(bold: true).ttfFlags(), 0x01)
    @Expect(FontStyle(italic: true).ttfFlags(), 0x02)
    @Expect(FontStyle(underline: true).ttfFlags(), 0x04)
    @Expect(FontStyle(strikethrough: true).ttfFlags(), 0x08)
    // Combined styles OR their flags together.
    @Expect(FontStyle(bold: true, italic: true).ttfFlags(), 0x03)
    @Expect(FontStyle(bold: true, italic: true, underline: true, strikethrough: true).ttfFlags(), 0x0F)
}

@Test
func fontStyleWithHelpersToggleOneFlag(): Unit {
    let base = FontStyle.regular
    @Expect(base.withBold().bold)
    @Expect(base.withItalic().italic)
    @Expect(base.withUnderline().underline)
    @Expect(base.withStrikethrough().strikethrough)
    @Expect(base.withBold().withItalic().ttfFlags(), 0x03)
    // Passing false clears a flag.
    @Expect(!FontStyle(bold: true).withBold(value: false).bold)
    // A with-helper leaves the other flags untouched.
    let mixed = FontStyle(bold: true, underline: true)
    @Expect(mixed.withItalic().bold)
    @Expect(mixed.withItalic().underline)
    @Expect(mixed.withItalic().italic)
}

@Test
func fontStyleEquality(): Unit {
    @Expect(FontStyle(bold: true) == FontStyle(bold: true))
    @Expect(FontStyle(bold: true) != FontStyle(italic: true))
    @Expect(FontStyle.regular == FontStyle())
    @Expect(!(FontStyle.regular != FontStyle()))
    @Expect(!FontStyle(underline: true).isRegular)
}

@Test
func headlessRendererWidensBoldText(): Unit {
    let renderer = Renderer.headless()
    let plain = renderer.textWidth("Hello World", pointSize: 15.0)
    let bold = renderer.textWidth("Hello World", pointSize: 15.0, style: FontStyle(bold: true))
    // Bold widens the advance (faux-bold), so styled measurement is strictly wider.
    @Expect(bold > plain)
    // Underline and strikethrough are decorations only; they leave the advance width unchanged.
    let underlined = renderer.textWidth("Hello", pointSize: 15.0, style: FontStyle(underline: true))
    @Expect(underlined == renderer.textWidth("Hello", pointSize: 15.0))
    // Line height is independent of style.
    @Expect(renderer.textHeight(pointSize: 15.0, style: FontStyle(bold: true)) == renderer.textHeight(pointSize: 15.0))
}
