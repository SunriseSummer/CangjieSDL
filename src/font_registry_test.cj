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
