package sdl

@Test
func textInkBoundsExcludeLineWhitespaceAndReuseMetricsCache(): Unit {
    let window = SdlWindow(WindowSpec("Font ink bounds", 260, 140, supersample: 1))
    try {
        let renderer = window.renderer
        for (scale in [Float32(1.0), Float32(1.25), Float32(2.0)]) {
            renderer.setScale(scale)
            for (style in [FontStyle.regular, FontStyle(italic: true), FontStyle(underline: true)]) {
                let bounds = renderer.textInkBounds("保存 Ag", pointSize: 40.0, style: style)
                let raster = renderer.textBounds("保存 Ag", pointSize: 40.0, style: style)
                @Expect(bounds.w > 0.0 && bounds.h > 0.0)
                @Expect(bounds.x >= 0.0 && bounds.y >= 0.0)
                @Expect(bounds.right() <= raster.w + 1.0 / scale)
                @Expect(bounds.bottom() <= raster.h + 1.0 / scale)
                let computes = renderer.textComputeCount()
                renderer.textInkBounds("保存 Ag", pointSize: 40.0, style: style)
                @Expect(renderer.textComputeCount(), computes)
            }
        }
        let whitespace = renderer.textInkBounds("   ")
        @Expect(whitespace.w, Float32(0.0))
        @Expect(whitespace.h, Float32(0.0))
        @Expect(renderer.textInkBounds("").h, Float32(0.0))
        @Expect(renderer.textInkBounds("Ag", pointSize: 40.0).h < renderer.textBounds("Ag", pointSize: 40.0).h)
    } finally { window.close() }
}
