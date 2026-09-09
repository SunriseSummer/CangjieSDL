package sdl

@Test
func nativeClipRejectsIntegerEdgeOverflowBeforeChangingState(): Unit {
    try (window = SdlWindow(WindowSpec("Clip integer boundary", 100, 80), hidden: true)) {
        let renderer = window.renderer
        let invalid = [Rect(2147483520.0, 0.0, 256.0, 10.0), Rect(0.0, 2147483520.0, 10.0, 256.0)]
        for (rect in invalid) {
            var rejected = false
            try { renderer.pushClip(rect) }
            catch (_: IllegalArgumentException) { rejected = true }
            @Expect(rejected)
            @Expect(renderer.currentClip().isNone())
            // Also restore the old implementation so both axes are independently exercised.
            if (renderer.currentClip().isSome()) { renderer.popClip() }
        }
        renderer.beginScene(100.0, 80.0, Color.rgb(20, 40, 60))
        renderer.endScene()
    }
}
