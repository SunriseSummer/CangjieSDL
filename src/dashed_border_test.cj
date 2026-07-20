package sdl

// Exercises the dashed rounded-rect stroke path (perimeter march + per-dash strokeSegment) on a window
// renderer across radii and the solid fallback. Pixel correctness is verified by example snapshots.
@Test
func strokesDashedRoundedRectWithoutError(): Unit {
    let window = SdlWindow(WindowSpec("Dashed border test", 220, 150))
    try {
        let renderer = window.renderer
        renderer.beginScene(220.0, 150.0, Color.rgb(255, 255, 255))
        let box = Rect(14.0, 14.0, 192.0, 122.0)
        let pen = Pen(width: 2.0, color: Color.rgb(80, 90, 110))
        renderer.strokeRoundedRectDashed(box, 16.0, pen, dash: 6.0, gap: 4.0)
        // Rectangular (radius 0) dashes.
        renderer.strokeRoundedRectDashed(box, 0.0, pen, dash: 5.0, gap: 5.0)
        // A non-positive dash falls back to a solid stroke (no exception).
        renderer.strokeRoundedRectDashed(box, 16.0, pen, dash: 0.0, gap: 4.0)
        // A degenerate zero-size rect is a safe no-op.
        renderer.strokeRoundedRectDashed(Rect(0.0, 0.0, 0.0, 0.0), 4.0, pen, dash: 4.0, gap: 4.0)
        renderer.endScene()
        renderer.present()
        @Expect(true) // reached here without a native draw exception
    } finally {
        window.close()
    }
}
