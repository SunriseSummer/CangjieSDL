package sdl

@Test
func fontRegistryRecordsAndResolves(): Unit {
    Fonts.clear()
    @Expect(!Fonts.isRegistered("Serif"))
    @Expect(Fonts.pathFor("Serif").isNone())

    Fonts.register("Serif", "/fonts/serif.ttf")
    @Expect(Fonts.isRegistered("Serif"))
    @Expect(Fonts.pathFor("Serif").getOrThrow(), "/fonts/serif.ttf")

    // Re-registering a name replaces its path.
    Fonts.register("Serif", "/fonts/other.otf")
    @Expect(Fonts.pathFor("Serif").getOrThrow(), "/fonts/other.otf")
    Fonts.clear()
}

@Test
func fontRegistryUnregisterAndClear(): Unit {
    Fonts.clear()
    Fonts.register("A", "/a.ttf")
    Fonts.register("B", "/b.ttf")
    @Expect(Fonts.names().size, 2)

    Fonts.unregister("A")
    @Expect(!Fonts.isRegistered("A"))
    @Expect(Fonts.isRegistered("B"))
    // Unregistering an unknown name is a no-op.
    Fonts.unregister("missing")
    @Expect(Fonts.names().size, 1)

    Fonts.clear()
    @Expect(Fonts.names().size, 0)
}

@Test
func fontRegistryPreservesOrderedFallbackChain(): Unit {
    Fonts.clear()
    Fonts.registerFamily("UI", "/primary.ttf", fallbackPaths: ["/cjk.ttf", "/emoji.ttf"])

    @Expect(Fonts.pathFor("UI").getOrThrow(), "/primary.ttf")
    @Expect(Fonts.fallbackPathsFor("UI"), ["/cjk.ttf", "/emoji.ttf"])
    @Expect(Fonts.fallbackPathsFor("UI").size, 2)
    Fonts.clear()
}

@Test
func fontRegistryRevisionInvalidatesRendererMetricsForChangedChain(): Unit {
    Fonts.clear()
    let renderer = Renderer.headless()
    Fonts.registerFamily("UI", "/primary.ttf", fallbackPaths: ["/first.ttf"])
    renderer.resetTextMeasureCount()
    let _ = renderer.textWidth("mixed 仓颉", font: "UI")
    @Expect(renderer.textComputeCount(), UInt64(1))
    renderer.resetTextMeasureCount()
    let _ = renderer.textWidth("mixed 仓颉", font: "UI")
    @Expect(renderer.textComputeCount(), UInt64(0))

    Fonts.registerFamily("UI", "/primary.ttf", fallbackPaths: ["/second.ttf"])
    renderer.resetTextMeasureCount()
    let _ = renderer.textWidth("mixed 仓颉", font: "UI")
    @Expect(renderer.textComputeCount(), UInt64(1))
    Fonts.clear()
}

@Test
func fontFamilyDefinitionCopiesFallbacksAndSupportsCollectionFaces(): Unit {
    let fallbacks = [FontSource("/fallback.ttc", faceIndex: 1)]
    let family = FontFamily(FontSource("/regular.ttc", faceIndex: 2), italic: FontSource("/italic.ttf"),
        fallbacks: fallbacks, synthesize: false)
    fallbacks[0] = FontSource("/changed.ttf")
    Fonts.registerFamily("definition", family)
    @Expect(Fonts.pathFor("definition").getOrThrow(), "/regular.ttc")
    @Expect(family.regular.faceIndex, Int64(2))
    @Expect(family.fallbacks()[0].path, "/fallback.ttc")
    @Expect(family.fallbacks()[0].faceIndex, Int64(1))
    @Expect(!family.synthesize)
    Fonts.unregister("definition")
}

@Test
func fontDefaultAndNestedScopesRestoreAfterExceptions(): Unit {
    Fonts.setDefault("app-font")
    let renderer = Renderer.headless()
    @Expect(renderer.effectiveFontFamily().getOrThrow(), "app-font")
    try {
        renderer.withFontFamily("outer") {
            @Expect(renderer.effectiveFontFamily().getOrThrow(), "outer")
            renderer.withFontFamily("inner") {
                @Expect(renderer.effectiveFontFamily().getOrThrow(), "inner")
                @Expect(renderer.effectiveFontFamily(font: "explicit").getOrThrow(), "explicit")
            }
            @Expect(renderer.effectiveFontFamily().getOrThrow(), "outer")
            throw IllegalStateException("test scope cleanup")
        }
    } catch (error: IllegalStateException) {
        @Expect(error.message, "test scope cleanup")
    } finally {
        @Expect(renderer.effectiveFontFamily().getOrThrow(), "app-font")
        Fonts.setDefault(Option<String>.None)
    }
}

@Test
func fontSourceRejectsInvalidCollectionIndex(): Unit {
    for (index in [Int64(-1), Int64(Int32.Max) + 1]) {
        var rejected = false
        try {
            let source = FontSource("/collection.ttc", faceIndex: index)
            @Fail("Invalid index was accepted: ${source.faceIndex}")
        } catch (_: IllegalArgumentException) {
            rejected = true
        }
        @Expect(rejected)
    }
}
