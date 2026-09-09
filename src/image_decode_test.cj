package sdl

import std.fs.{Directory, File, exists, remove}

private let IMAGE_FIXTURES = ".dev/fixtures/images/"

@Test
func imageCodecsDecodeRealFixturesFromFilesAndMemory(): Unit {
    @Expect(imageVersion() >= Int32(3004006))
    for (extension in ["bmp", "png", "jpg", "gif", "tga", "pcx", "qoi", "ppm", "svg", "PnG", "data"]) {
        let path = IMAGE_FIXTURES + if (extension == "PnG") { "mixed.PnG" } else { "quad." + extension }
        try (file = Surface.load(path)) {
            @Expect(file.size().w, Float32(16))
            @Expect(file.size().h, Float32(12))
            let red = file.readPixel(1, 1)
            @Expect(red.r > UInt8(210))
            @Expect(red.g < UInt8(65))
        }
        try (memory = Surface.loadBytes(File.readFrom(path), typeHint: extension)) {
            @Expect(memory.size().w, Float32(16))
            @Expect(memory.size().h, Float32(12))
        }
    }
    try (icon = Surface.load(IMAGE_FIXTURES + "quad.ico")) { @Expect(icon.size().w, Float32(32)) }
    try (xpm = Surface.load(IMAGE_FIXTURES + "quad.xpm")) {
        @Expect(xpm.size().w, Float32(2))
        @Expect(xpm.readPixel(1, 1).a, UInt8(0))
    }
}

@Test
func imageDecodingPreservesAlphaAndBoundsRasterAndVectorSizes(): Unit {
    try (image = Surface.load(IMAGE_FIXTURES + "quad.png")) {
        @Expect(image.readPixel(12, 9).a, UInt8(128))
        try (small = image.resized(8, 6, sampling: TextureScaleMode.Nearest)) {
            @Expect(small.readPixel(6, 4).a, UInt8(128))
        }
        @Expect(!image.isClosed())
    }
    let bounds = ImageLoadOptions(width: 8, height: 8)
    try (raster = Surface.load(IMAGE_FIXTURES + "quad.png", options: bounds)) {
        @Expect(raster.size().w, Float32(8))
        @Expect(raster.size().h, Float32(6))
    }
    try (vector = Surface.load(IMAGE_FIXTURES + "quad.svg", options: ImageLoadOptions(width: 160, height: 160))) {
        @Expect(vector.size().w, Float32(160))
        @Expect(vector.size().h, Float32(120))
    }
    try (vector = Surface.loadBytes(File.readFrom(IMAGE_FIXTURES + "quad.svg"),
        options: ImageLoadOptions(height: 60))) {
        @Expect(vector.size().w, Float32(80))
        @Expect(vector.size().h, Float32(60))
    }
}

@Test
func imageLoadFailuresDoNotPoisonLaterLoads(): Unit {
    for (bytes in [Array<UInt8>(), [UInt8(1), UInt8(2)], File.readFrom(IMAGE_FIXTURES + "broken.png")]) {
        var rejected = false
        try { Surface.loadBytes(bytes).close() } catch (_: SdlException) { rejected = true }
        @Expect(rejected)
    }
    var budgetRejected = false
    try { Surface.load(IMAGE_FIXTURES + "quad.png", options: ImageLoadOptions(maxPixels: 1)).close() }
    catch (_: SdlException) { budgetRejected = true }
    @Expect(budgetRejected)
    try (good = Surface.load(IMAGE_FIXTURES + "quad.jpg", options: ImageLoadOptions(maxPixels: 192))) {
        @Expect(good.size().h, Float32(12))
    }
    var beforeResizeRejected = false
    try { Surface.load(IMAGE_FIXTURES + "quad.png", options: ImageLoadOptions(width: 1, maxPixels: 191)).close() }
    catch (_: SdlException) { beforeResizeRejected = true }
    @Expect(beforeResizeRejected)
}

@Test
func imageSavingRoundTripsAndRejectsInvalidAccess(): Unit {
    let directory = Directory.createTemp("target").toString()
    let png = directory + "/透明.png"
    let jpg = directory + "/image.jpg"
    try {
        try (image = Surface.load(IMAGE_FIXTURES + "quad.png")) {
            image.savePng(png)
            image.saveJpeg(jpg, quality: 95)
        }
        try (image = Surface.load(png)) { @Expect(image.readPixel(12, 9).a, UInt8(128)) }
        try (image = Surface.load(jpg)) { @Expect(image.size().w, Float32(16)) }
    } finally {
        if (exists(png)) { remove(png) }
        if (exists(jpg)) { remove(jpg) }
        remove(directory)
    }
    let closed = Surface.create(2, 2)
    closed.close()
    var rejected = false
    try { closed.readPixel(0, 0) } catch (_: SdlException) { rejected = true }
    @Expect(rejected)
}

@Test
func imageArgumentsRejectNulAndInvalidSizes(): Unit {
    var count = 0
    try { Surface.load("quad.png\0.jpg").close() } catch (_: IllegalArgumentException) { count += 1 }
    try { Surface.loadBytes([UInt8(0)], typeHint: "PNG\0").close() }
    catch (_: IllegalArgumentException) { count += 1 }
    try { let _ = ImageLoadOptions(width: -1) } catch (_: IllegalArgumentException) { count += 1 }
    try { let _ = ImageLoadOptions(maxPixels: 0) } catch (_: IllegalArgumentException) { count += 1 }
    try { let _ = ImageLoadOptions(width: 100, height: 100, maxPixels: 100) }
    catch (_: IllegalArgumentException) { count += 1 }
    @Expect(count, 5)
    @Expect(match (imageFormatFromPath("quad.PnG")) { case ImageFileFormat.Png => true; case _ => false })
}

@Test
func imageWritersRejectNulWithoutWritingATruncatedPath(): Unit {
    let directory = Directory.createTemp("target").toString()
    let path = directory + "/must-not-exist"
    try {
        try (surface = Surface.create(2, 2)) {
            let writers: Array<(String) -> Unit> = [
                {name => surface.saveBmp(name)}, {name => surface.savePng(name)}, {name => surface.saveJpeg(name)}
            ]
            var rejected = 0
            for (writer in writers) {
                try { writer(path + "\0suffix") }
                catch (_: IllegalArgumentException) { rejected += 1 }
            }
            @Expect(rejected, 3)
            @Expect(!exists(path))
        }
    } finally {
        if (exists(path)) { remove(path) }
        remove(directory)
    }
}
