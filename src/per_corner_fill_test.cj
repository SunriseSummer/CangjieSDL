package sdl

// Exercises the per-corner rounded-rect fill path (independent corner arcs + fillPath) on a window
// renderer across corner mixes and degenerate inputs. Pixel correctness is verified by example snapshots.
@Test
func fillsPerCornerRoundedRectWithoutError(): Unit {
    let window = SdlWindow(WindowSpec("Per-corner fill test", 220, 150))
    try {
        let renderer = window.renderer
        renderer.beginScene(220.0, 150.0, Color.rgb(255, 255, 255))
        let box = Rect(14.0, 14.0, 192.0, 122.0)
        let fill = Color.rgb(90, 130, 240)
        // A chat-bubble mix: three rounded corners, one squared tail.
        renderer.fillPerCornerRoundedRect(box, fill, topLeft: 18.0, topRight: 18.0, bottomRight: 18.0, bottomLeft: 3.0)
        // Top-only rounding (a tab).
        renderer.fillPerCornerRoundedRect(box, fill, topLeft: 16.0, topRight: 16.0, bottomRight: 0.0, bottomLeft: 0.0)
        // All corners sharp — a plain rectangle.
        renderer.fillPerCornerRoundedRect(box, fill, topLeft: 0.0, topRight: 0.0, bottomRight: 0.0, bottomLeft: 0.0)
        // Oversized radii clamp to the short half-side (no overflow, no exception).
        renderer.fillPerCornerRoundedRect(box, fill, topLeft: 999.0, topRight: 999.0, bottomRight: 999.0,
            bottomLeft: 999.0)
        // A degenerate zero-size rect is a safe no-op.
        renderer.fillPerCornerRoundedRect(Rect(0.0, 0.0, 0.0, 0.0), fill, topLeft: 4.0, topRight: 4.0,
            bottomRight: 4.0, bottomLeft: 4.0)
        renderer.endScene()
        renderer.present()
        @Expect(true) // reached here without a native draw exception
    } finally {
        window.close()
    }
}
