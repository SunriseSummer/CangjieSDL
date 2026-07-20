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
