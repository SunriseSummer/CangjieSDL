package sdl

import std.collection.ArrayList
import std.fs.{Directory, File, copy, exists, remove}
import sdl.text.discoverNativeFonts

@Test
func fontHardeningMonochromeRasterReusesRgbAndOpacity(): Unit {
    try (window = SdlWindow(WindowSpec("Text raster cache", 220, 120), hidden: true)) {
        let renderer = window.renderer
        renderer.beginScene(220.0, 120.0, Color.rgb(255, 255, 255))
        try {
            renderer.textRotated("AV 仓颉", 100.0, 50.0, 25.0, Color.rgba(200, 30, 20, 255))
            let first = renderer.fontCacheStats()
            for (alpha in [Int64(0), Int64(80), Int64(170), Int64(255)]) {
                renderer.textRotated("AV 仓颉", 100.0, 50.0, 25.0, Color.rgba(200, 30, 20, alpha))
                @Expect(renderer.fontCacheStats().textRasterizations, first.textRasterizations)
                @Expect(renderer.fontCacheStats().textTextureBytes, first.textTextureBytes)
            }
            renderer.textRotated("AV 仓颉", 100.0, 50.0, 25.0, Color.rgb(20, 30, 200))
            // Monochrome strings keep a color-independent raster, even after the color-glyph fix.
            @Expect(renderer.fontCacheStats().textRasterizations, first.textRasterizations)
            @Expect(renderer.fontCacheStats().textTextureBytes <= Int64(16 * 1024 * 1024))
        } finally { renderer.endScene() }
    }
}

@Test
func fontHardeningSessionCloseRejectsAnotherThreadWithoutClosing(): Unit {
    let renderer = Renderer.headless()
    let session = renderer.textMeasureSession("Owner thread")
    try {
        let rejected = spawn {
            try { session.close(); false } catch (_: IllegalStateException) { true }
        }
        @Expect(rejected.get())
        @Expect(!session.isClosed())
        @Expect(session.measure(0, session.byteLength) > 0.0)
    } finally { session.close(); renderer.releaseResources() }
}

@Test
func fontHardeningZeroAreaItalicAndRotatedTextIsANoOp(): Unit {
    try (window = SdlWindow(WindowSpec("Empty text raster", 160, 100, supersample: 1), hidden: true)) {
        let renderer = window.renderer
        renderer.beginScene(160.0, 100.0, Color.rgb(255, 255, 255))
        try {
            for (text in ["\n", "\u{200B}", "\u{200D}"]) {
                renderer.text(text, 10.0, 10.0, Color.rgb(0, 0, 0), style: FontStyle(italic: true))
                renderer.textRotated(text, 50.0, 50.0, 25.0, Color.rgb(0, 0, 0))
            }
        } finally { renderer.endScene() }
        @Expect(renderer.fontCacheStats().textTextureBytes, Int64(0))
    }
}

@Test
func fontHardeningColorGlyphsKeepTheirColorInRasterPaths(): Unit {
    let path = "C:/Windows/Fonts/seguiemj.ttf"
    if (!exists(path)) { return }
    let directory = Directory.createTemp(".").toString()
    Fonts.register("hardening-color", path)
    try (window = SdlWindow(WindowSpec("Color glyphs", 220, 120, supersample: 1), hidden: true)) {
        for (rotated in [false, true]) {
            for (sample in ["😀", "AV", "AV 😀"]) {
                for (blue in [false, true]) {
                    captureHardeningColor(window.renderer, directory, sample, blue, rotated)
                }
                let a = File.readFrom(directory + "/red.bmp")
                let b = File.readFrom(directory + "/blue.bmp")
                if (sample == "😀") { @Expect(a, b) } else { @Expect(a != b) }
            }
        }
    } finally {
        Fonts.unregister("hardening-color")
        for (name in ["red.bmp", "blue.bmp"]) { if (exists(directory + "/" + name)) { remove(directory + "/" + name) } }
        remove(directory)
    }
}

private func captureHardeningColor(renderer: Renderer, directory: String, text: String, blue: Bool, rotated: Bool): Unit {
    let color = if (blue) { Color.rgba(20, 40, 230, 170) } else { Color.rgba(230, 40, 20, 170) }
    renderer.beginScene(220.0, 120.0, Color.rgb(255, 255, 255))
    try {
        if (rotated) {
            renderer.textRotated(text, 90.0, 60.0, 25.0, color, pointSize: 32.0, font: "hardening-color")
        } else {
            renderer.text(text, 10.0, 10.0, color, pointSize: 32.0, font: "hardening-color", style: FontStyle(italic: true))
        }
        renderer.captureBmp(directory + if (blue) { "/blue.bmp" } else { "/red.bmp" })
    } finally { renderer.endScene() }
}

@Test
func fontHardeningResetRebuildsAtlasAndPreservesLiveSessions(): Unit {
    let directory = Directory.createTemp(".").toString()
    try (window = SdlWindow(WindowSpec("Font reset recovery", 280, 180, supersample: 2), hidden: true)) {
        let renderer = window.renderer
        paintHardeningText(renderer, directory + "/before.bmp")
        @Expect(renderer.fontCacheStats().glyphAtlasBytes > 0)
        try (session = renderer.textMeasureSession("AV office 仓颉", pointSize: 25.0)) {
            let width = session.measure(0, session.byteLength)
            for (_ in 0..3) {
                renderer.noteRenderReset()
                @Expect(renderer.fontCacheStats().glyphAtlasBytes, Int64(0))
                @Expect(renderer.fontCacheStats().cachedGlyphs, Int64(0))
                @Expect(session.measure(0, session.byteLength), width)
                paintHardeningText(renderer, directory + "/after.bmp")
                @Expect(File.readFrom(directory + "/before.bmp"), File.readFrom(directory + "/after.bmp"))
            }
        }
    } finally {
        for (name in ["before.bmp", "after.bmp"]) { if (exists(directory + "/" + name)) { remove(directory + "/" + name) } }
        remove(directory)
    }
}

private func paintHardeningText(renderer: Renderer, path: String): Unit {
    renderer.beginScene(280.0, 180.0, Color.rgb(255, 255, 255))
    try {
        renderer.text("AV office 仓颉", 8.0, 12.0, Color.rgb(20, 50, 80), pointSize: 25.0)
        renderer.text("Italic 保存", 8.0, 60.0, Color.rgb(80, 50, 20), pointSize: 25.0, style: FontStyle(italic: true))
        renderer.captureBmp(path)
    } finally { renderer.endScene() }
}

@Test
func fontHardeningReloadRefreshesRegisteredDiscoveryMetadata(): Unit {
    let directory = Directory.createTemp(".").toString()
    let path = directory + "/font.ttf"
    let second = "C:/Windows/Fonts/segoeui.ttf"
    if (!exists(second)) { remove(directory); return }
    try {
        copy(regressionSerif(), to: path)
        let family = familyFromInstalledFaces(ArrayList(discoverNativeFonts([path]).faces))
        Fonts.registerFamily("hardening-discovered", family)
        let before = Fonts.familyFaces("hardening-discovered")[0].familyName
        remove(path); copy(second, to: path)
        Fonts.reload()
        let after = Fonts.familyFaces("hardening-discovered")
        @Expect(!after.isEmpty())
        @Expect(after[0].familyName != before)
        @Expect(after[0].familyName, "Segoe UI")
        @Expect(!Fonts.hasSystemCatalog())
        remove(path)
        Fonts.reload()
        @Expect(Fonts.familyFaces("hardening-discovered").isEmpty())
        copy(second, to: path)
        Fonts.reload()
        @Expect(Fonts.familyFaces("hardening-discovered")[0].familyName, "Segoe UI")
        @Expect(!Fonts.hasSystemCatalog())
    } finally {
        Fonts.unregister("hardening-discovered")
        if (exists(path)) { remove(path) }; remove(directory)
    }
}
