package sdl

@Test
func systemUiFontMeasuresChineseAndLatinText(): Unit {
    let window = SdlWindow(WindowSpec("Font test", 320, 120))
    try {
        @Expect(window.renderer.textWidth("仓颉 GUI", pointSize: FontSizes.BODY) > 0.0)
        @Expect(window.renderer.textHeight(pointSize: FontSizes.BODY) > 0.0)
    } finally {
        window.close()
    }
}

@Test
func namedFontsLoadAndFallBack(): Unit {
    // Exercises the FontFace lazy-open path and its fallback: a registered, openable font measures
    // positively; an unopenable path and an unregistered name both degrade to the system UI font
    // (identical metrics) instead of throwing during a frame.
    let window = SdlWindow(WindowSpec("Named font test", 320, 120))
    try {
        let renderer = window.renderer
        let sample = "Sample Text 123"
        let base = renderer.textWidth(sample)
        // A registered path (present on Windows; harmlessly falls back elsewhere) loads and measures.
        Fonts.register("iter2-sys", "C:\\Windows\\Fonts\\segoeui.ttf")
        @Expect(renderer.textWidth(sample, font: "iter2-sys") > 0.0)
        // A registered but unopenable path falls back to the system font — same metrics as no font.
        Fonts.register("iter2-bad", "Z:\\no\\such\\font.ttf")
        @Expect(renderer.textWidth(sample, font: "iter2-bad") == base)
        // An unregistered name also falls back to the system font.
        @Expect(renderer.textWidth(sample, font: "iter2-unregistered") == base)
    } finally {
        Fonts.unregister("iter2-sys")
        Fonts.unregister("iter2-bad")
        window.close()
    }
}

@Test
func cjkFontFileLoadsWithOwnMetrics(): Unit {
    // A real CJK font file (LXGW WenKai under the repo's .todo/testfonts, machine-local) exercises the
    // loaded-face pipeline with non-Latin glyphs. Presence is detected through the registry's own
    // fallback semantics — an unopenable registration measures identically to the system font — so the
    // test needs no filesystem access and stays green on machines without the fonts.
    let window = SdlWindow(WindowSpec("CJK font test", 320, 120))
    try {
        let renderer = window.renderer
        let sample = "永字八法，仓颉造字。The quick brown fox 0123."
        let base = renderer.textWidth(sample, pointSize: 18.0)
        var loadedWidth: Float32 = -1.0
        for (candidate in [
            "..\\.todo\\testfonts\\LXGWWenKai-Regular.ttf",
            ".todo\\testfonts\\LXGWWenKai-Regular.ttf",
            "..\\..\\.todo\\testfonts\\LXGWWenKai-Regular.ttf"
        ]) {
            Fonts.register("wenkai-test", candidate)
            let width = renderer.textWidth(sample, pointSize: 18.0, font: "wenkai-test")
            if (width != base) {
                loadedWidth = width
                break
            }
            Fonts.unregister("wenkai-test")
        }
        if (loadedWidth < 0.0) {
            return // fonts not present on this machine (every candidate fell back); nothing to verify
        }
        // The loaded face shapes CJK with its own metrics: positive, distinct width and line height.
        @Expect(loadedWidth > 0.0)
        @Expect(renderer.textHeight(pointSize: 18.0, font: "wenkai-test") > 0.0)
        // Style variants open on the loaded face too; faux bold is at least as wide as regular.
        @Expect(renderer.textWidth(sample, pointSize: 18.0, style: FontStyle(bold: true), font: "wenkai-test") >=
            loadedWidth)
    } finally {
        Fonts.unregister("wenkai-test")
        window.close()
    }
}

@Test
func systemUiFontMeasuresStyledText(): Unit {
    // Exercises the real TTF_SetFontStyle path: each style variant opens and styles its own font
    // handle, and its metrics must stay positive. Faux-bold embolden widens the run, so a bold
    // measurement is at least as wide as the plain one.
    let window = SdlWindow(WindowSpec("Styled font test", 320, 120))
    try {
        let renderer = window.renderer
        let sample = "Styled Sample 12345"
        let plain = renderer.textWidth(sample, pointSize: FontSizes.BODY)
        let bold = renderer.textWidth(sample, pointSize: FontSizes.BODY, style: FontStyle(bold: true))
        let italic = renderer.textWidth(sample, pointSize: FontSizes.BODY, style: FontStyle(italic: true))
        @Expect(plain > 0.0)
        @Expect(bold >= plain)
        @Expect(italic > 0.0)
        // A fully decorated style still measures and does not disturb the line height.
        let decorated = FontStyle(bold: true, italic: true, underline: true, strikethrough: true)
        @Expect(renderer.textWidth(sample, pointSize: FontSizes.BODY, style: decorated) > 0.0)
        @Expect(renderer.textHeight(pointSize: FontSizes.BODY, style: decorated) > 0.0)
    } finally {
        window.close()
    }
}
