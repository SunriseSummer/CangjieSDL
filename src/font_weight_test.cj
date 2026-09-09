package sdl

import sdl.text.fontWeightMatchRank

@Test
func numericWeightPreservesStyleAndValidatesBounds(): Unit {
    let style = FontStyle(italic: true, underline: true).withWeight(FontWeight(350))
    @Expect(style.weight.value, Int64(350))
    @Expect(style.italic && style.underline && !style.bold)
    @Expect(style.withBold().weight, FontWeight.bold)
    @Expect(style.withItalic(value: false).weight.value, Int64(350))
    @Expect(FontStyle(weight: FontWeight(350)) != FontStyle.regular)
    @Expect(fontWeightMatchRank(400, 500) < fontWeightMatchRank(400, 300))
    @Expect(fontWeightMatchRank(500, 400) < fontWeightMatchRank(500, 600))
    @Expect(fontWeightMatchRank(600, 700) < fontWeightMatchRank(600, 500))
    var rejected = 0
    for (value in [0, 1001]) {
        try { let _ = FontWeight(value) } catch (_: IllegalArgumentException) { rejected += 1 }
    }
    @Expect(rejected, 2)
}

@Test
func cascadianNamedWeightsUseRealOutlinesAndStableSessions(): Unit {
    let faces = Fonts.systemFonts()
    var available = false
    for (face in faces) {
        if (face.familyName == "Cascadia Code" && face.source.instanceIndex > 0) {
            available = true
            @Expect(!face.axes().isEmpty())
            @Expect(face.variations.values()[0].tag, "wght")
            @Expect(face.variations.values()[0].value, Float32(face.weight.value))
        }
    }
    if (!available) { return }
    let window = SdlWindow(WindowSpec("Named variable weights", 180, 100, supersample: 1))
    try {
        for (italic in [false, true]) {
            for (weight in [200, 300, 350, 400, 600, 700]) {
                let style = FontStyle(weight: FontWeight(weight), italic: italic)
                let resolution = window.renderer.resolveFont(font: "Cascadia Code", style: style)
                @Expect(!resolution.faces[0].synthesizedStyle.bold)
                @Expect(!resolution.faces[0].synthesizedStyle.italic)
                @Expect(resolution.faces[0].source.instanceIndex > 0 || weight == 400)
                let session = window.renderer.textMeasureSession("AV office", style: style, font: "Cascadia Code")
                try {
                    let before = session.measure(0, session.byteLength)
                    window.renderer.textWidth("Other weight", style: FontStyle(weight: FontWeight(1000)), font: "Cascadia Code")
                    @Expect(session.measure(0, session.byteLength), before)
                } finally { session.close() }
            }
        }
    } finally { window.close() }
}

