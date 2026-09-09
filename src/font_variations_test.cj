package sdl

import std.env.getVariable
import std.fs.{File, exists}

@Test
func fontVariationCoordinatesAreCanonicalAndCopied(): Unit {
    let source = [FontVariation("wght", 625.0), FontVariation("wdth", 90.0)]
    let first = FontVariations(source)
    let second = FontVariations([source[1], source[0]])
    @Expect(first, second)
    source[0] = FontVariation("wght", 700.0)
    @Expect(first.values()[1].value, Float32(625.0))
    @Expect(FontStyle(variations: first).withItalic().variations, first)
    @Expect(FontStyle(variations: first).weight.value, Int64(625))
    @Expect(FontStyle(variations: first).bold)
    @Expect(FontStyle(variations: first).withWeight(FontWeight(600)).variations.values().size, Int64(1))
    var rejected = 0
    try { let _ = FontVariations([FontVariation("wght", 400.0), FontVariation("wght", 500.0)]) }
    catch (_: IllegalArgumentException) { rejected += 1 }
    try { let _ = FontVariation("weight", 400.0) } catch (_: IllegalArgumentException) { rejected += 1 }
    @Expect(rejected, 2)
}

@Test
func continuousWeightsMatchIndependentStaticFontOutlines(): Unit {
    let directory = match (getVariable("CSDL_FONT_TEST_ROOT")) { case Some(value) => value; case None => return }
    @Expect(Fonts.supportsVariations())
    @Expect(exists(directory + "/625-regular.ttf"))
    let window = SdlWindow(WindowSpec("Variable weight oracle", 480, 160, supersample: 1))
    try {
        let renderer = window.renderer
        for (weight in [200, 350, 400, 600, 625, 700]) {
            Fonts.registerFamily("axis-oracle", FontFamily(FontSource("${directory}/${weight}-regular.ttf"),
                italic: FontSource("${directory}/${weight}-italic.ttf")))
            for (italic in [false, true]) {
                let style = FontStyle(weight: FontWeight(weight), italic: italic)
                let resolved = renderer.resolveFont(font: "Cascadia Code", style: style)
                @Expect(resolved.faces[0].weight.value, weight)
                @Expect(!resolved.faces[0].synthesizedStyle.bold && !resolved.faces[0].synthesizedStyle.italic)
                compareWeightOutlines(renderer, directory, style)
            }
        }
        let session = renderer.textMeasureSession("AV office ffi", font: "Cascadia Code",
            style: FontStyle(weight: FontWeight(625)))
        try {
            let before = session.measure(0, session.byteLength)
            for (weight in 200..700) {
                renderer.textWidth("cache eviction", font: "Cascadia Code", style: FontStyle(weight: FontWeight(weight)))
            }
            @Expect(session.measure(0, session.byteLength), before)
            @Expect(renderer.fontCacheStats().fontConfigurations <= 24)
        } finally { session.close() }
        var rejected = 0
        for (coordinate in [FontVariation("nope", 1.0), FontVariation("wght", 800.0)]) {
            try {
                renderer.textWidth("invalid", font: "Cascadia Code", style: FontStyle(variations: FontVariations([coordinate])))
            } catch (_: IllegalArgumentException) { rejected += 1 }
        }
        @Expect(rejected, 2)
        let clamped = renderer.resolveFont(font: "Cascadia Code", style: FontStyle(weight: FontWeight(900)))
        @Expect(clamped.faces[0].weight.value, Int64(700))
        @Expect(!clamped.faces[0].synthesizedStyle.bold)
        @Expect(!clamped.warnings.isEmpty())
    } finally { window.close(); Fonts.unregister("axis-oracle") }
}

private func compareWeightOutlines(renderer: Renderer, directory: String, style: FontStyle): Unit {
                for (scale in [Float32(1.0), Float32(1.5), Float32(2.0)]) {
                    for (name in ["Cascadia Code", "axis-oracle"]) {
                        renderer.beginScene(480.0, 160.0, Color.rgb(255, 255, 255))
                        renderer.setScale(scale)
                        renderer.text("AV office ffi 012345", 12.0, 12.0, Color.rgb(12, 40, 80), pointSize: 25.0,
                            font: name, style: style)
                        renderer.captureBmp(directory + "/" + name + ".bmp")
                        renderer.endScene()
                    }
                    let actual = File.readFrom(directory + "/Cascadia Code.bmp")
                    let expected = File.readFrom(directory + "/axis-oracle.bmp")
                    @Expect(actual.size, expected.size)
                    var different: Int64 = 0
                    var maximum: Int64 = 0
                    var total: Int64 = 0
                    for (i in 0..min(actual.size, expected.size)) {
                        let delta = max(Int64(actual[i]), Int64(expected[i])) - min(Int64(actual[i]), Int64(expected[i]))
                        if (delta != 0) { different += 1 }
                        maximum = max(maximum, delta); total += delta
                    }
                    println("ORACLE weight=${style.weight.value} italic=${style.italic} scale=${scale} different=${different} max=${maximum} total=${total}")
                    // fontTools rounds instanced TrueType points to whole design units; FreeType retains
                    // fractional variable points. Bound antialiasing error, and separately require equal advances.
                    var ink: Int64 = 0
                    for (i in 128..expected.size) { ink += 255 - Int64(expected[i]) }
                    @Expect(maximum <= 16)
                    @Expect(Float64(total) <= max(1.0, Float64(ink) * 0.005))
                    @Expect(renderer.textWidth("AV office ffi 012345", font: "Cascadia Code", style: style, pointSize: 25.0),
                        renderer.textWidth("AV office ffi 012345", font: "axis-oracle", style: style, pointSize: 25.0))
                }
}
