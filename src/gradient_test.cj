package sdl

// Exercises the real gradient geometry path (emitMeshGradient + SDL_RenderGeometry) on a window
// renderer: both axes must draw without throwing. Pixel correctness is verified by example snapshots.
@Test
func fillsRoundedRectGradientWithoutError(): Unit {
    let window = SdlWindow(WindowSpec("Gradient test", 220, 140))
    try {
        let renderer = window.renderer
        renderer.beginScene(220.0, 140.0, Color.rgb(20, 20, 24))
        let box = Rect(12.0, 12.0, 196.0, 116.0)
        renderer.fillRoundedRectGradient(box, 14.0, Color.rgb(80, 120, 240), Color.rgb(200, 80, 160))
        renderer.fillRoundedRectGradient(box, 14.0, Color.rgb(240, 200, 90), Color.rgb(60, 180, 160), vertical: false)
        // A degenerate zero-size rect is a safe no-op.
        renderer.fillRoundedRectGradient(Rect(0.0, 0.0, 0.0, 0.0), 4.0, Color.rgb(0, 0, 0), Color.rgb(255, 255, 255))
        renderer.endScene()
        renderer.present()
        @Expect(true) // reached here without an exception from the native draw
    } finally {
        window.close()
    }
}
