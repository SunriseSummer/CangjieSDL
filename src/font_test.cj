package sdl

@Test
func textMeasureSessionRejectsUseAfterRendererClose(): Unit {
    let window = SdlWindow(WindowSpec("Text session lifetime", 120, 80, supersample: 1))
    let session = window.renderer.textMeasureSession("lifetime")
    window.close()

    var rejected = false
    try {
        let _ = session.measure(0, session.byteLength)
    } catch (_: IllegalStateException) {
        rejected = true
    } finally {
        session.close()
    }
    @Expect(rejected)
}

@Test
func directRenderPassRestoresLogicalTextMetricsCacheBetweenFrames(): Unit {
    let window = SdlWindow(WindowSpec("Direct text metrics cache", 160, 100, supersample: 1))
    try {
        let renderer = window.renderer
        let pass = renderer.beginRenderPass(160.0, 100.0, Color.rgb(18, 22, 28))
        renderer.text("prime draw scale", 8.0, 8.0, Color.rgb(240, 240, 240))
        pass.close()

        renderer.resetTextMeasureCount()
        let first = renderer.textWidth("stable direct-frame measurement")
        let second = renderer.textWidth("stable direct-frame measurement")

        @Expect(first, second)
        @Expect(renderer.textMeasureCount(), UInt64(2))
        @Expect(renderer.textComputeCount(), UInt64(1))
    } finally {
        window.close()
    }
}

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
func headlessTextMeasureSessionUsesUtf8ByteBoundaries(): Unit {
    let renderer = Renderer.headless()
    let session = renderer.textMeasureSession("A中B")
    try (resource = session) {
        let ascii = resource.fit(0, 20.0)
        @Expect(ascii.byteLength, 1)
        @Expect(ascii.width, renderer.textWidth("A"))
        let cjk = resource.fit(1, 25.0)
        @Expect(cjk.byteLength, 3)
        @Expect(cjk.width, renderer.textWidth("中"))
        @Expect(resource.measure(1, 3), renderer.textWidth("中"))
        let beforeCjk = resource.hitTest(renderer.textWidth("A") + 1.0)
        @Expect(beforeCjk.byteOffset, Int64(1))
        let afterCjk = resource.hitTest(renderer.textWidth("A中") - 1.0)
        @Expect(afterCjk.byteOffset, Int64(4))
    }
    @Expect(session.isClosed())
}

@Test
func nativeTextMeasureSessionFitsWithoutSubstringAllocation(): Unit {
    let window = SdlWindow(WindowSpec("Text fit test", 320, 120))
    try {
        let renderer = window.renderer
        let text = "Hello 世界 and more"
        let maxWidth = renderer.textWidth("Hello 世界")
        let session = renderer.textMeasureSession(text)
        try (resource = session) {
            let fit = resource.fit(0, maxWidth)
            @Expect(fit.byteLength > 0)
            @Expect(fit.byteLength < text.size)
            @Expect(fit.width <= maxWidth)
            @Expect(resource.measure(0, fit.byteLength) <= maxWidth)
        }
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
func nativeFontFamilyShapesThroughOrderedFallbacks(): Unit {
    let window = SdlWindow(WindowSpec("Native fallback font test", 320, 120, supersample: 1))
    try {
        Fonts.registerFamily("fallback-chain", "C:\\Windows\\Fonts\\segoeui.ttf",
            fallbackPaths: ["C:\\Windows\\Fonts\\msyh.ttc"])
        let renderer = window.renderer
        @Expect(renderer.textWidth("Latin 仓颉 😀", pointSize: 18.0, font: "fallback-chain") > 0.0)
        renderer.renderFrame(320.0, 120.0, Color.rgb(255, 255, 255)) {
            renderer.text("Latin 仓颉 😀", 8.0, 8.0, Color.rgb(20, 30, 40), pointSize: 18.0,
                font: "fallback-chain")
        }
    } finally {
        Fonts.unregister("fallback-chain")
        window.close()
    }
}

@Test
func nativeTextHitTestReturnsUtf8ClusterBoundary(): Unit {
    let window = SdlWindow(WindowSpec("Native text hit test", 240, 100, supersample: 1))
    try {
        let text = "office 仓颉"
        let session = window.renderer.textMeasureSession(text, pointSize: 18.0)
        try (resource = session) {
            let hit = resource.hitTest(window.renderer.textWidth("office ", pointSize: 18.0) + 2.0)
            @Expect(hit.byteOffset >= Int64(7))
            @Expect(hit.byteOffset <= text.size)
            @Expect(hit.bounds.h >= 0.0)
        }
    } finally {
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
