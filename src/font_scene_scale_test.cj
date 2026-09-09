package sdl

@Test
func preparedFontMetricsMatchSceneRasterGrid(): Unit {
    for (sampling in [Int32(1), Int32(2)]) {
        let window = SdlWindow(WindowSpec("Font layout raster grid", 260, 140, supersample: sampling))
        try {
            let renderer = window.renderer
            for (scale in [Float32(1.0), Float32(1.25), Float32(1.5)]) {
                renderer.updateContentScale(scale)
                for (size in [Float32(13.0), Float32(15.0), Float32(20.0), Float32(32.0)]) {
                    for (style in [FontStyle.regular, FontStyle(bold: true), FontStyle(italic: true)]) {
                        let text = "Title · 20fp 永远滚烫 The quick brown fox"
                        renderer.prepareTextLayout(260.0, 140.0)
                        let grid = renderer.textMeasurementScale()
                        let width = renderer.textWidth(text, pointSize: size, style: style)
                        let height = renderer.textHeight(pointSize: size, style: style)
                        let session = renderer.textMeasureSession(text, pointSize: size, style: style)
                        try {
                            renderer.beginScene(260.0, 140.0, Color.rgb(255, 255, 255))
                            @Expect(renderer.textMeasurementScale().w, grid.w)
                            @Expect(renderer.textMeasurementScale().h, grid.h)
                            @Expect(renderer.textWidth(text, pointSize: size, style: style), width)
                            @Expect(renderer.textHeight(pointSize: size, style: style), height)
                            @Expect(session.measure(0, text.size), width)
                            renderer.endScene()
                            @Expect(session.measure(0, text.size), width)
                        } finally { session.close() }
                    }
                }
            }
        } finally { window.close() }
    }
    let headless = Renderer.headless()
    headless.setScale(1.25)
    headless.prepareTextLayout(100.0, 100.0)
    @Expect(headless.textMeasurementScale().w, Float32(1.25))
    var rejected = false
    try { headless.prepareTextLayout(0.0, 100.0) } catch (_: IllegalArgumentException) { rejected = true }
    @Expect(rejected)
    rejected = false
    try { let _ = headless.recordCommands({=> headless.prepareTextLayout(100.0, 100.0)}) }
    catch (_: IllegalStateException) { rejected = true }
    @Expect(rejected)
}
