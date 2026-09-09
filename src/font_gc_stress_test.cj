package sdl

import std.fs.exists

@Test
func mixedEmojiRasterCacheSurvivesAllocationAndRepeatedFontReplacement(): Unit {
    let emoji = "C:/Windows/Fonts/seguiemj.ttf"
    let ui = "C:/Windows/Fonts/msyh.ttc"
    if (!exists(emoji) || !exists(ui)) { return }
    let window = SdlWindow(WindowSpec("Font GC regression", 800, 240, highDpi: false, supersample: 1,
        vsync: false), hidden: true)
    let retained = Array<Array<UInt8>>(8, { _ => [] })
    try {
        let renderer = window.renderer
        for (cycle in 0..30) {
            Fonts.registerFamily("gc-specimen", FontFamily(FontSource(emoji), fallbacks: [FontSource(ui)]))
            var sample = "AV 仓颉 🎉 "
            for (i in 0..24) { sample += Rune(UInt32(0x1F300 + (cycle * 13 + i) % 160)).toString() }
            let text = sample
            for (index in 0..9) {
                // Allocate between frames so automatic concurrent collection overlaps native work.
                retained[index % retained.size] = Array<UInt8>(64 * 1024, repeat: UInt8(cycle))
                let style = FontStyle(bold: index >= 6, italic: index >= 3, underline: index >= 6)
                let scale: Float32 = [Float32(1.0), Float32(1.25), Float32(2.0)][index % 3]
                renderer.renderFrame(800.0, 240.0, Color.rgb(255, 255, 255)) {
                    renderer.setScale(scale)
                    let bounds = renderer.textBounds(text, font: "gc-specimen", pointSize: 24.0, style: style)
                    @Expect(bounds.w > 0.0 && bounds.h > 0.0)
                    let ink = renderer.textInkBounds(text, font: "gc-specimen", pointSize: 24.0, style: style)
                    @Expect(ink.w > 0.0)
                    let color = Color.rgb(24, 65, 130).withAlpha(170)
                    renderer.text(text, 10.0, 10.0, color, font: "gc-specimen", pointSize: 24.0, style: style)
                    renderer.textRotated(text, 250.0, 110.0, 0.0, color, font: "gc-specimen",
                        pointSize: 24.0, style: style)
                }
            }
        }
        @Expect(renderer.fontCacheStats().glyphAtlasBytes <= 16 * 1024 * 1024)
    } finally { window.close(); Fonts.clear() }
    for (buffer in retained) { @Expect(buffer.size, Int64(64 * 1024)) }
}
