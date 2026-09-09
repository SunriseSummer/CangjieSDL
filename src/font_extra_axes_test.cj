package sdl

import std.env.getVariable
import std.fs.exists

@Test
func widthAndOpticalAxesHaveIndependentMetricsAndDiagnostics(): Unit {
    let windows = getVariable("WINDIR").getOrDefault({=> "C:/Windows"})
    let widthFont = windows + "/Fonts/bahnschrift.ttf"
    let opticalFont = windows + "/Fonts/SegUIVar.ttf"
    if (!Fonts.supportsVariations() || !exists(widthFont) || !exists(opticalFont)) { return }
    Fonts.register("width-axis", widthFont)
    Fonts.register("optical-axis", opticalFont)
    let window = SdlWindow(WindowSpec("Width and optical axes", 240, 120, supersample: 1))
    try {
        let renderer = window.renderer
        let narrow = FontStyle(variations: FontVariations([FontVariation("wdth", 75.0), FontVariation("wght", 625.0)]))
        let wide = FontStyle(weight: FontWeight(625), variations: FontVariations([FontVariation("wdth", 100.0)]))
        let text = "MMMM WWWW 012345"
        @Expect(renderer.textWidth(text, font: "width-axis", style: narrow) < renderer.textWidth(text, font: "width-axis", style: wide))
        let session = renderer.textMeasureSession(text, font: "width-axis", style: narrow)
        try {
            let before = session.measure(0, session.byteLength)
            for (size in [Float32(5.0), Float32(12.0), Float32(36.0)]) {
                let style = FontStyle(variations: FontVariations([FontVariation("opsz", size)]))
                let resolution = renderer.resolveFont(font: "optical-axis", style: style)
                @Expect(resolution.faces[0].source.variations.values()[0].tag, "opsz")
                @Expect(resolution.faces[0].source.variations.values()[0].value, size)
            }
            @Expect(session.measure(0, session.byteLength), before)
        } finally { session.close() }
        let resolution = renderer.resolveFont(font: "width-axis", style: narrow)
        @Expect(resolution.requestedWeight.value, Int64(625))
        @Expect(resolution.faces[0].weight.value, Int64(625))
        @Expect(resolution.warnings.isEmpty())
        let reversed = FontStyle(variations: FontVariations([FontVariation("wght", 625.0), FontVariation("wdth", 75.0)]))
        @Expect(narrow, reversed)
        let before = renderer.fontCacheStats().fontConfigurations
        renderer.resolveFont(font: "width-axis", style: reversed)
        @Expect(renderer.fontCacheStats().fontConfigurations, before)
    } finally { window.close(); Fonts.unregister("width-axis"); Fonts.unregister("optical-axis") }
}
