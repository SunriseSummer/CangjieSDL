package sdl

import sdl.text.{NativeTextRenderer, NativeFontFamily, NativeFontSource, NativeTextException}

@Test
func defaultFontDoesNotBuildTheSystemCatalog(): Unit {
    Fonts.clear()
    let window = SdlWindow(WindowSpec("Lazy default font", 160, 100, supersample: 1), hidden: true)
    try {
        @Expect(!Fonts.hasSystemCatalog())
        let family = window.renderer.resolveFont().faces[0].familyName
        @Expect(!Fonts.familyFaces(family).isEmpty())
        @Expect(!Fonts.hasSystemCatalog())
        @Expect(Fonts.familyFaces("__absent_lazy_font_family__").isEmpty())
        @Expect(!Fonts.hasSystemCatalog())
        @Expect(window.renderer.textWidth("Default 仓颉") > 0.0)
        @Expect(!Fonts.hasSystemCatalog())
        @Expect(window.renderer.textWidth("Mono", font: FontRole.monospace) > 0.0)
        @Expect(!Fonts.hasSystemCatalog())
    } finally { window.close(); Fonts.clear() }
}

@Test
func fontBootstrapUsesConfiguredFontWithoutPlatformCandidates(): Unit {
    let window = SdlWindow(WindowSpec("Font bootstrap", 160, 100, supersample: 1))
    try {
        let source = NativeFontSource(regressionSerif(), 0)
        let backend = NativeTextRenderer(window.renderer.ptr, bootstrapSources: [source])
        try {
            let resolved = backend.resolve(15.0, 0, NativeFontFamily("", [], "bootstrap"))
            @Expect(resolved.faces[0].source.path, source.path)
            @Expect(backend.measure("Bootstrap", 15.0, 0, NativeFontFamily("", [], "bootstrap")).width > 0.0)
        } finally { backend.close() }
        var failed = false
        try {
            let missing = NativeTextRenderer(window.renderer.ptr, bootstrapSources: [])
            missing.close()
        } catch (error: NativeTextException) { failed = error.message.contains("No usable font") }
        @Expect(failed)
    } finally { window.close() }
}

@Test
func configuredFontFallbacksAreCopiedAndVersioned(): Unit {
    let revision = Fonts.revision()
    let sources = [FontSource("first.ttf")]
    Fonts.setFallbacks(sources)
    try {
        sources[0] = FontSource("changed.ttf")
        @Expect(Fonts.fallbacks()[0].path, "first.ttf")
        @Expect(Fonts.revision() > revision)
        let copy = Fonts.fallbacks()
        copy[0] = FontSource("changed-again.ttf")
        @Expect(Fonts.fallbacks()[0].path, "first.ttf")
    } finally { Fonts.setFallbacks([]) }
}

@Test
func applicationDefaultBootstrapsBeforeSystemDiscovery(): Unit {
    Fonts.register("bootstrap-default", regressionSerif())
    Fonts.setDefault("bootstrap-default")
    Fonts.setFallbacks([FontSource(regressionSerif())])
    try {
        let sources = fontBootstrapSources()
        @Expect(sources[0].path, regressionSerif())
        @Expect(sources.size, Int64(2))
        let window = SdlWindow(WindowSpec("Application font bootstrap", 160, 100, supersample: 1))
        try { @Expect(window.renderer.resolveFont().faces[0].source.path, regressionSerif()) }
        finally { window.close() }
    } finally {
        Fonts.setDefault(Option<String>.None)
        Fonts.setFallbacks([])
        Fonts.unregister("bootstrap-default")
    }
}
