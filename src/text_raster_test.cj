package sdl

import std.fs.{Directory, File, exists, remove}
import sdl.text.{NativeTextRenderer, NativeFontFamily}

@Test
func italicLongLineExceedingGpuTextureLimitStillDraws(): Unit {
    let window = SdlWindow(WindowSpec("Long italic text", 640, 192, supersample: 1))
    try {
        let renderer = window.renderer
        renderer.setScale(1.0)
        let limit = max(Int32(4096), renderer.renderSamplingStats().maxTextureSize)
        let text = StringBuilder()
        let sample = "AV office ffi "
        let width = renderer.textWidth(sample, pointSize: 24.0, style: FontStyle(italic: true))
        for (_ in 0..(Int64(Float32(limit) / width) + 8)) {
            text.append(sample)
        }
        let longText = text.toString()
        @Expect(renderer.textWidth(longText, pointSize: 24.0, style: FontStyle(italic: true)) > Float32(limit))
        renderer.beginScene(640.0, 192.0, Color.rgb(255, 255, 255))
        renderer.setScale(1.0)
        renderer.text(longText, 128.0 - Float32(limit), 48.0, Color.rgb(20, 40, 60), pointSize: 24.0,
            style: FontStyle(italic: true))
        renderer.endScene()
        @Expect(renderer.fontCacheStats().textTextures >= Int64(2))
        @Expect(renderer.fontCacheStats().textTextureBytes <= Int64(16 * 1024 * 1024))
    } finally {
        window.close()
    }
}

@Test
func textRasterTilesPreservePixelsAcrossRotationScaleAndSeams(): Unit {
    let directory = Directory.createTemp(".").toString()
    let actual = directory + "/tiles.bmp"
    let expected = directory + "/whole.bmp"
    let window = SdlWindow(WindowSpec("Text tile pixels", 640, 320, supersample: 1))
    let renderer = window.renderer
    let backend = NativeTextRenderer(renderer.ptr)
    let surface = Surface(
        backend.renderSurface("AV office ffi 仓颉", 32.0, FontStyle(italic: true).ttfFlags(),
            NativeFontFamily("", [], "tile-pixels")))
    let tiled = createTextRasterImage(renderer.ptr, renderer.renderDevice(), surface.ptr, 32)
    let whole = renderer.textureFromSurface(surface)
    try {
        whole.setBlendMode(TextureBlendMode.Blend)
        @Expect(tiled.tiles.size > Int64(2))
        var comparisons: Int64 = 0
        for (scale in [Float32(1.0), Float32(1.25), Float32(2.0)]) {
            for (angle in [Float64(0.0), Float64(15.0), Float64(45.0), Float64(90.0)]) {
                captureRasterTiles(renderer, tiled, whole, actual, scale, angle, useTiles: true)
                captureRasterTiles(renderer, tiled, whole, expected, scale, angle, useTiles: false)
                // Separate quads may round interpolation by one channel value on a GPU.
                let delta = maxRasterByteDelta(actual, expected)
                println("TEXT_TILE_PIXELS|scale=${scale}|angle=${angle}|maxDelta=${delta}")
                @Expect(delta <= Int64(1))
                comparisons += 1
            }
        }
        @Expect(comparisons, Int64(12))
    } finally {
        whole.close()
        tiled.close()
        surface.close()
        backend.close()
        window.close()
        if (exists(actual)) {
            remove(actual)
        }
        if (exists(expected)) {
            remove(expected)
        }
        remove(directory)
    }
}

private func captureRasterTiles(renderer: Renderer, tiled: TextRasterImage, whole: Texture, path: String,
    scale: Float32, angle: Float64, useTiles!: Bool): Unit {
    renderer.beginScene(640.0, 320.0, Color.rgb(255, 255, 255))
    renderer.setScale(scale)
    renderer.pushClip(Rect(48.0, 16.0, 300.0, 210.0))
    let color = Color.rgba(24, 65, 130, 170)
    if (useTiles) {
        tiled.draw(renderer.ptr, Point(60.0, 60.0), Size(scale, scale), color, angle: angle)
    } else {
        whole.setColorMod(color)
        whole.setAlpha(170)
        renderer.textureRotated(whole, Rect(60.0, 60.0, whole.width / scale, whole.height / scale), angle)
    }
    renderer.captureBmp(path)
    renderer.popClip()
    renderer.endScene()
}

private func maxRasterByteDelta(left: String, right: String): Int64 {
    let a = File.readFrom(left)
    let b = File.readFrom(right)
    @Expect(a.size, b.size)
    var maximum: Int64 = 0
    for (i in 0..min(a.size, b.size)) {
        let delta = Int64(a[i]) - Int64(b[i])
        maximum = max(maximum, if (delta < 0) {
            -delta
        } else {
            delta
        })
    }
    maximum
}
