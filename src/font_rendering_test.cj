package sdl

import std.fs.{Directory, File, copy, exists, remove}
import sdl.text.{NativeFontFamily, NativeFontSource, NativeTextRenderer}

private let FONT_PIXEL_SAMPLE = "AV office ffi 仓颉"

private func captureItalic(renderer: Renderer, path: String, scale: Float32, style: FontStyle): Unit {
    renderer.beginScene(640.0, 192.0, Color.rgb(255, 255, 255))
    if (scale > 0.0) {
        renderer.setScale(scale)
    }
    renderer.pushClip(Rect(48.0, 0.0, 200.0, 190.0))
    let color = Color.rgb(24, 65, 130).withAlpha(170)
    let commands = renderer.recordCommands {
        renderer.text(FONT_PIXEL_SAMPLE, 48.0, 48.0, color, pointSize: 24.0, style: style, font: "pixel-italic")
    }
    @Expect(commands.replay(renderer))
    renderer.captureBmp(path)
    renderer.popClip()
    renderer.endScene()
}

private func captureFontSurface(renderer: Renderer, backend: NativeTextRenderer, family: NativeFontFamily, path: String,
    scale: Float32, style: FontStyle): Unit {
    renderer.beginScene(640.0, 192.0, Color.rgb(255, 255, 255))
    if (scale > 0.0) {
        renderer.setScale(scale)
    }
    let actualScale = renderer.textMeasurementScale().h
    renderer.pushClip(Rect(48.0, 0.0, 200.0, 190.0))
    let pointer = backend.renderSurface(FONT_PIXEL_SAMPLE, 24.0 * actualScale, style.ttfFlags(), family)
    @Expect(pointer.isNotNull())
    try (surface = Surface(pointer), texture = renderer.textureFromSurface(surface)) {
        texture.setColorMod(Color.rgb(24, 65, 130))
        texture.setAlpha(170)
        renderer.texture(texture, Rect(48.0, 48.0, texture.width / actualScale, texture.height / actualScale))
    }
    renderer.captureBmp(path)
    renderer.popClip()
    renderer.endScene()
}

private func differingFontBytes(left: String, right: String): Int64 {
    let a = File.readFrom(left)
    let b = File.readFrom(right)
    @Expect(a.size, b.size)
    var different: Int64 = 0
    for (i in 0..min(a.size, b.size)) {
        if (a[i] != b[i]) {
            different += 1
        }
    }
    different
}

@Test
func italicRenderingMatchesIndependentSurfaceWithScaleClipAlphaAndReplay(): Unit {
    let directory = Directory.createTemp(".").toString()
    let fontPath = directory + "/plain.ttf"
    let actualPath = directory + "/actual.bmp"
    let expectedPath = directory + "/expected.bmp"
    copy(regressionSerif(), to: fontPath)
    Fonts.register("pixel-italic", fontPath)
    try {
        var comparisons: Int64 = 0
        for (sampling in [Int32(0), Int32(1), Int32(2), Int32(4)]) {
            comparisons += verifyItalicSampling(fontPath, actualPath, expectedPath, sampling)
        }
        @Expect(comparisons, Int64(60))
    } finally {
        Fonts.unregister("pixel-italic")
        if (exists(actualPath)) {
            remove(actualPath)
        }
        if (exists(expectedPath)) {
            remove(expectedPath)
        }
        remove(fontPath)
        remove(directory)
    }
}

private func verifyItalicSampling(fontPath: String, actualPath: String, expectedPath: String, sampling: Int32): Int64 {
    let window = SdlWindow(WindowSpec("Italic pixel regression", 640, 192, supersample: sampling))
    let renderer = window.renderer
    let system = renderer.resolveFont().faces[0].source
    let reference = NativeTextRenderer(renderer.ptr,
        bootstrapSources: [NativeFontSource(system.path, system.faceIndex)])
    var comparisons: Int64 = 0
    try {
        let family = NativeFontFamily(fontPath, [], "independent-reference")
        for (scale in [Float32(0.0), Float32(1.0), Float32(1.25), Float32(1.5), Float32(2.0)]) {
            for (style in [FontStyle(italic: true), FontStyle(bold: true, italic: true),
                    FontStyle(italic: true, underline: true, strikethrough: true)]) {
                captureItalic(renderer, actualPath, scale, style)
                captureFontSurface(renderer, reference, family, expectedPath, scale, style)
                @Expect(differingFontBytes(actualPath, expectedPath), Int64(0))
                comparisons += 1
                let before = renderer.fontCacheStats().textRasterizations
                captureItalic(renderer, actualPath, scale, style)
                @Expect(renderer.fontCacheStats().textRasterizations, before)
            }
        }
        @Expect(renderer.fontCacheStats().textTextureBytes <= Int64(16 * 1024 * 1024))
    } finally {
        reference.close()
        window.close()
    }
    comparisons
}
