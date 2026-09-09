package sdl

import std.fs.{Directory, File, exists, remove}

@Test
func editorEmojiDefaultMatchesExplicitFallbackWithoutLoadingCatalog(): Unit {
    let emoji = "C:/Windows/Fonts/seguiemj.ttf"
    if (!exists(emoji)) { return }
    let directory = Directory.createTemp(".").toString()
    try (window = SdlWindow(WindowSpec("Editor emoji fallback", 420, 150, supersample: 1), hidden: true)) {
        let renderer = window.renderer
        let primary = renderer.resolveFont().faces[0].source
        Fonts.registerFamily("editor-emoji-reference", FontFamily(primary, fallbacks: [FontSource(emoji)]))
        let sample = "A🎉B 👩🏽‍💻 🇨🇳"
        for (reference in [false, true]) {
            renderer.beginScene(420.0, 150.0, Color.rgb(255, 255, 255))
            try {
                renderer.text(sample, 8.0, 8.0, Color.rgb(30, 60, 90), pointSize: 25.0,
                    font: if (reference) { Some("editor-emoji-reference") } else { None })
                renderer.captureBmp(directory + if (reference) { "/reference.bmp" } else { "/actual.bmp" })
            } finally { renderer.endScene() }
        }
        @Expect(File.readFrom(directory + "/actual.bmp"), File.readFrom(directory + "/reference.bmp"))
        @Expect(!Fonts.hasSystemCatalog())
    } finally {
        Fonts.unregister("editor-emoji-reference")
        for (name in ["actual.bmp", "reference.bmp"]) { if (exists(directory + "/" + name)) { remove(directory + "/" + name) } }
        remove(directory)
    }
}

@Test
func editorEmojiGroupsStayBoundedAndLiveSessionsSurviveEvictionAndReload(): Unit {
    try (window = SdlWindow(WindowSpec("Emoji session lifetime", 180, 100), hidden: true)) {
        let renderer = window.renderer
        let plain = renderer.textMeasureSession("ordinary office 仓颉", pointSize: 18.0)
        let emoji = renderer.textMeasureSession("A🎉👩🏽‍💻B", pointSize: 18.0)
        try {
            let plainWidth = plain.measure(0, plain.byteLength)
            let emojiWidth = emoji.measure(0, emoji.byteLength)
            for (size in 12..70) {
                let _ = renderer.textWidth("ordinary", pointSize: Float32(size))
                let _ = renderer.textWidth("🎉", pointSize: Float32(size))
            }
            @Expect(renderer.fontCacheStats().fontConfigurations <= 24)
            @Expect(plain.measure(0, plain.byteLength), plainWidth)
            @Expect(emoji.measure(0, emoji.byteLength), emojiWidth)
            renderer.reloadFonts()
            @Expect(plain.measure(0, plain.byteLength), plainWidth)
            @Expect(emoji.measure(0, emoji.byteLength), emojiWidth)
            @Expect(renderer.textWidth("A🎉👩🏽‍💻B", pointSize: 18.0), emojiWidth)
            @Expect(!Fonts.hasSystemCatalog())
        } finally { emoji.close(); plain.close() }
    }
}

@Test
func editorEmojiRoleFindsPlatformFontWithoutCatalog(): Unit {
    if (!exists("C:/Windows/Fonts/seguiemj.ttf")) { return }
    try (window = SdlWindow(WindowSpec("Emoji role", 180, 100), hidden: true)) {
        let info = window.renderer.resolveFont(font: FontRole.emoji)
        @Expect(info.faces[0].familyName, "Segoe UI Emoji")
        @Expect(!Fonts.hasSystemCatalog())
    }
}
