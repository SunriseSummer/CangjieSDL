package sdl

import std.fs.{Directory, copy, exists, remove}

// The Windows trio reproduces the original Arabic fallback cache collision. Other supported
// desktops exercise the same lifetime invariant with their installed serif/sans faces.
private func regressionFont(candidates: Array<String>): String {
    for (path in candidates) {
        if (exists(path)) {
            return path
        }
    }
    throw IllegalStateException("Native font regressions require an installed test font")
}

internal func regressionSerif(): String {
    regressionFont(
        ["C:/Windows/Fonts/georgia.ttf", "/System/Library/Fonts/Times.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"])
}

private func regressionSans(): String {
    regressionFont(
        ["C:/Windows/Fonts/segoeui.ttf", "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"])
}

private func regressionItalic(): FontSource {
    for (face in Fonts.systemFonts()) {
        if (face.style.italic && !face.style.bold) {
            return face.source
        }
    }
    throw IllegalStateException("Native font regressions require an installed real italic face")
}

@Test
func fontFallbackSessionsRemainStableAcrossFamiliesAndRegistration(): Unit {
    let window = SdlWindow(WindowSpec("Font family isolation", 160, 100, supersample: 1))
    try {
        let serif = regressionSerif()
        let sans = regressionSans()
        let alternative = regressionFont(["C:/Windows/Fonts/arial.ttf", sans])
        Fonts.registerFamily("regression-A", serif, fallbackPaths: [sans])
        Fonts.registerFamily("regression-B", serif, fallbackPaths: [alternative])
        let renderer = window.renderer
        let text = "مرحبا بالعالم"
        try (session = renderer.textMeasureSession(text, pointSize: 32.0, font: "regression-A")) {
            let before = session.measure(0, session.byteLength)
            for (i in 0..32) {
                renderer.textWidth("${text}${i}", pointSize: 32.0, font: "regression-B")
            }
            @Expect(session.measure(0, session.byteLength), before)
            Fonts.registerFamily("regression-A", serif, fallbackPaths: [alternative])
            renderer.textWidth(text, pointSize: 32.0, font: "regression-A")
            @Expect(session.measure(0, session.byteLength), before)
            @Expect(session.hitTest(10.0).byteOffset <= text.size)
        }
    } finally {
        window.close()
        Fonts.unregister("regression-A")
        Fonts.unregister("regression-B")
    }
}

@Test
func fontRegistrationRecoversAfterMissingFileAppears(): Unit {
    let directory = Directory.createTemp(".").toString()
    let path = directory + "/font.ttf"
    let window = SdlWindow(WindowSpec("Font recovery", 160, 100, supersample: 1))
    try {
        let renderer = window.renderer
        let text = "iiiiWWWW AV office"
        Fonts.register("regression-reference", regressionSerif())
        Fonts.register("regression-recovery", path)
        let missing = renderer.textWidth(text, pointSize: 32.0, font: "regression-recovery")
        @Expect(missing, renderer.textWidth(text, pointSize: 32.0))
        copy(regressionSerif(), to: path)
        Fonts.register("regression-recovery", path)
        @Expect(renderer.textWidth(text, pointSize: 32.0, font: "regression-recovery"),
            renderer.textWidth(text, pointSize: 32.0, font: "regression-reference"))
    } finally {
        window.close()
        Fonts.unregister("regression-reference")
        Fonts.unregister("regression-recovery")
        if (exists(path)) {
            remove(path)
        }
        remove(directory)
    }
}

@Test
func fontResolutionReportsRealItalicAndCollectionFailure(): Unit {
    let window = SdlWindow(WindowSpec("Font face resolution", 240, 120, supersample: 1))
    try {
        let renderer = window.renderer
        Fonts.registerFamily("real-italic", FontFamily(FontSource(regressionSerif()), italic: regressionItalic()))
        let resolved = renderer.resolveFont(font: "real-italic", style: FontStyle(italic: true))
        @Expect(resolved.faces.size > 0)
        @Expect(!resolved.faces[0].synthesizedStyle.italic)
        @Expect(resolved.warnings.isEmpty())
        Fonts.registerFamily("bad-face-index", FontFamily(FontSource(regressionSerif(), faceIndex: 999999)))
        let invalid = renderer.resolveFont(font: "bad-face-index")
        @Expect(!invalid.warnings.isEmpty())
        @Expect(invalid.faces[0].source.faceIndex, renderer.resolveFont().faces[0].source.faceIndex)
        let metrics = renderer.fontMetrics(font: "real-italic", pointSize: 24.0)
        @Expect(metrics.ascent > 0.0)
        @Expect(metrics.descent >= 0.0)
        @Expect(metrics.lineHeight >= metrics.ascent)
    } finally {
        window.close()
        Fonts.unregister("real-italic")
        Fonts.unregister("bad-face-index")
    }
}

@Test
func fontCacheEvictionPreservesPinnedSession(): Unit {
    let window = SdlWindow(WindowSpec("Font cache lifetime", 160, 100, supersample: 1))
    try {
        let renderer = window.renderer
        try (session = renderer.textMeasureSession("Stable office 仓颉", pointSize: 15.0)) {
            let before = session.measure(0, session.byteLength)
            session.hitTest(5.0)
            for (i in 0..100) {
                renderer.textWidth("Cache size", pointSize: 10.0 + Float32(i) * 0.125)
            }
            @Expect(renderer.fontCacheStats().fontConfigurations <= Int64(64))
            @Expect(session.measure(0, session.byteLength), before)
            @Expect(session.hitTest(5.0).byteOffset <= session.byteLength)
            Fonts.reload()
            renderer.textWidth("reload")
            @Expect(session.measure(0, session.byteLength), before)
        }
    } finally {
        window.close()
    }
}

@Test
func installedFontCatalogResolvesNamesAndCollectionFaces(): Unit {
    let fonts = Fonts.systemFonts()
    @Expect(!fonts.isEmpty())
    @Expect(!Fonts.systemFamilyNames().isEmpty())
    let window = SdlWindow(WindowSpec("System font catalog", 180, 100, supersample: 1))
    try {
        let renderer = window.renderer
        let sample = "iiiiWWWW AV office"
        let name = fonts[0].familyName
        @Expect(Fonts.registerSystem("system-alias", name))
        @Expect(renderer.textWidth(sample, font: name), renderer.textWidth(sample, font: "system-alias"))
        @Expect(renderer.resolveFont(font: name).warnings.isEmpty())
        @Expect(!Fonts.registerSystem("missing-system-alias", "__font_that_does_not_exist__"))
        @Expect(!Fonts.isRegistered("missing-system-alias"))
        for (face in fonts) {
            if (face.source.faceIndex > 0) {
                Fonts.registerFamily("collection-face", FontFamily(face.source))
                let resolved = renderer.resolveFont(font: "collection-face", style: face.style)
                @Expect(resolved.faces[0].source.faceIndex, face.source.faceIndex)
                @Expect(resolved.warnings.isEmpty())
                break
            }
        }
    } finally {
        window.close()
        Fonts.unregister("system-alias")
        Fonts.unregister("collection-face")
    }
}

@Test
func reloadingFontsReleasesCachedFileBeforeReplacement(): Unit {
    let directory = Directory.createTemp(".").toString()
    let path = directory + "/replace.ttf"
    copy(regressionSerif(), to: path)
    let window = SdlWindow(WindowSpec("Font replacement", 160, 100, supersample: 1))
    try {
        let renderer = window.renderer
        Fonts.register("replace-font", path)
        renderer.textWidth("original", font: "replace-font")
        renderer.reloadFonts()
        @Expect(renderer.fontCacheStats().fontConfigurations, Int64(0))
        copy(regressionSans(), to: path, overwrite: true)
        Fonts.register("replacement-reference", regressionSans())
        @Expect(renderer.textWidth("iiiiWWWW AV office", font: "replace-font"),
            renderer.textWidth("iiiiWWWW AV office", font: "replacement-reference"))
    } finally {
        window.close()
        Fonts.unregister("replace-font")
        Fonts.unregister("replacement-reference")
        remove(path)
        remove(directory)
    }
}
