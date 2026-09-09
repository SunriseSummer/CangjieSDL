package sdl

@Test
func preparedTextureCannotPreserveUninitializedPixels(): Unit {
    try (window = SdlWindow(WindowSpec("Initial damage", 160, 100, supersample: 2), hidden: true)) {
        let renderer = window.renderer
        let clear = Color.rgb(20, 40, 60)
        renderer.prepareTextLayout(160.0, 100.0)
        @Expect(!renderer.beginSceneDamage(160.0, 100.0, clear, Rect(5.0, 5.0, 20.0, 20.0)))
        renderer.endScene()
        renderer.prepareTextLayout(160.0, 100.0)
        @Expect(renderer.beginSceneDamage(160.0, 100.0, clear, Rect(5.0, 5.0, 20.0, 20.0)))
        renderer.endScene()
        window.setSize(190, 110)
        window.sync()
        renderer.prepareTextLayout(190.0, 110.0)
        @Expect(!renderer.beginSceneDamage(190.0, 110.0, clear, Rect(5.0, 5.0, 20.0, 20.0)))
        renderer.endScene()
    }
}
