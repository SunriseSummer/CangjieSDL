package sdl

import std.fs.exists

@Test
func emojiLeafIsSharedAcrossFamiliesAndSurvivesSiblingEviction(): Unit {
    if (!exists("C:/Windows/Fonts/seguiemj.ttf")) { return }
    try (window = SdlWindow(WindowSpec("Shared emoji leaves", 220, 100, supersample: 1), hidden: true)) {
        let renderer = window.renderer
        let source = renderer.resolveFont().faces[0].source
        let baseline = renderer.fontCacheStats().cachedGlyphs
        try {
            for (i in 0..48) {
                Fonts.registerFamily("emoji-resource-${i}", FontFamily(source))
            }
            // Register everything before drawing: registry updates intentionally invalidate fonts.
            let session = renderer.textMeasureSession("A🎉B", font: "emoji-resource-0", pointSize: 22.0)
            try {
                let width = session.measure(0, session.byteLength)
                for (i in 0..48) {
                    renderer.renderFrame(220.0, 100.0, Color.rgb(255, 255, 255)) {
                        renderer.text("🎉", 8.0, 8.0, Color.rgb(20, 20, 20), pointSize: 22.0,
                            font: "emoji-resource-${i}")
                    }
                    @Expect(renderer.fontCacheStats().cachedGlyphs, baseline + 1)
                    @Expect(renderer.fontCacheStats().fontConfigurations <= 24)
                    @Expect(session.measure(0, session.byteLength), width)
                }
                renderer.reloadFonts()
                @Expect(session.measure(0, session.byteLength), width)
                renderer.renderFrame(220.0, 100.0, Color.rgb(255, 255, 255)) {
                    renderer.text("🎉", 8.0, 8.0, Color.rgb(20, 20, 20), pointSize: 22.0, font: "emoji-resource-47")
                }
                @Expect(session.measure(0, session.byteLength), width)
            } finally { session.close() }
        } finally {
            for (i in 0..48) { Fonts.unregister("emoji-resource-${i}") }
        }
    }
}
