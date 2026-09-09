package sdl

import std.fs.{Directory, exists, remove}

@Test
func imageStyleReplayPreservesPixelsAndTextureState(): Unit {
    let directory = Directory.createTemp("target").toString()
    let directPath = directory + "/direct.bmp"
    let replayPath = directory + "/replay.bmp"
    try {
        for (sampling in [Int32(1), Int32(2)]) {
            try (window = SdlWindow(WindowSpec("Image style replay", 240, 160, supersample: sampling), hidden: true)) {
                let r = window.renderer
                try (texture = r.loadTexture(".dev/fixtures/images/quad.png")) {
                    texture.setBlendMode(TextureBlendMode.Blend)
                    let buffer = r.recordCommands { paintImageStyles(r, texture) }
                    @Expect(buffer.stats().resourceCount, Int64(1))
                    r.beginScene(240.0, 160.0, Color.rgb(255, 255, 255))
                    paintImageStyles(r, texture)
                    r.captureBmp(directPath)
                    r.endScene()
                    r.beginScene(240.0, 160.0, Color.rgb(255, 255, 255))
                    @Expect(buffer.replay(r))
                    r.captureBmp(replayPath)
                    r.endScene()
                    @Expect(qualityPixelDifferences(directPath, replayPath), Int64(0))
                    try (pixels = Surface.load(directPath)) {
                        let pixelScale = pixels.size().w / 240.0
                        // The rounded corner is background; its center remains the source image.
                        @Expect(pixels.readPixel(Int32(11.0 * pixelScale), Int32(11.0 * pixelScale)).r, UInt8(255))
                        let green = pixels.readPixel(Int32(75.0 * pixelScale), Int32(30.0 * pixelScale))
                        @Expect(green.g, UInt8(210))
                        // Drawing styles did not leave a tint or opacity on the plain draw at right.
                        let red = pixels.readPixel(Int32(205.0 * pixelScale), Int32(15.0 * pixelScale))
                        @Expect(red.r > UInt8(220))
                    }
                    texture.close()
                    @Expect(!buffer.replay(r))
                }
            }
        }
    } finally {
        if (exists(directPath)) { remove(directPath) }
        if (exists(replayPath)) { remove(replayPath) }
        remove(directory)
    }
}

private func paintImageStyles(renderer: Renderer, texture: Texture): Unit {
    renderer.textureStyled(texture, Rect(10.0, 10.0, 80.0, 60.0),
        style: TextureStyle(radius: 16.0, sampling: TextureScaleMode.Nearest))
    renderer.textureStyled(texture, Rect(105.0, 10.0, 80.0, 60.0),
        style: TextureStyle(tint: Color.rgb(120, 220, 255), opacity: 0.5, flip: TextureFlip.Horizontal))
    renderer.textureStyled(texture, Rect(10.0, 90.0, 80.0, 60.0), source: Some(Rect(0.0, 0.0, 8.0, 6.0)),
        style: TextureStyle(radius: 30.0))
    renderer.texture(texture, Rect(200.0, 10.0, 32.0, 24.0))
}

@Test
func imageStylesRejectInvalidNumbersAndForeignTextures(): Unit {
    var rejected = 0
    try { let _ = TextureStyle(opacity: -1.0) } catch (_: IllegalArgumentException) { rejected += 1 }
    try { let _ = TextureStyle(radius: -1.0) } catch (_: IllegalArgumentException) { rejected += 1 }
    try (first = SdlWindow(WindowSpec("Image owner", 64, 48), hidden: true)) {
        try (second = SdlWindow(WindowSpec("Other image owner", 64, 48), hidden: true)) {
            try (texture = first.renderer.loadTexture(".dev/fixtures/images/quad.png")) {
                try { second.renderer.textureStyled(texture, Rect(0.0, 0.0, 32.0, 24.0)) }
                catch (_: SdlException) { rejected += 1 }
                try { first.renderer.textureStyled(texture, Rect(0.0, 0.0, 32.0, 24.0),
                    source: Some(Rect(-1.0, 0.0, 16.0, 12.0))) }
                catch (_: IllegalArgumentException) { rejected += 1 }
                try { let _ = second.renderer.recordCommands {=>
                    second.renderer.textureStyled(texture, Rect(0.0, 0.0, 32.0, 24.0))
                } } catch (_: SdlException) { rejected += 1 }
                texture.close()
                try { let _ = first.renderer.recordCommands {=>
                    first.renderer.textureStyled(texture, Rect(0.0, 0.0, 32.0, 24.0))
                } } catch (_: SdlException) { rejected += 1 }
            }
        }
    }
    @Expect(rejected, 6)
}

@Test
func imageStyleOpacityWorksOnOpaqueTexturesAndRestoresBlendAndSampling(): Unit {
    let directory = Directory.createTemp("target").toString()
    let path = directory + "/blend.bmp"
    try {
        try (window = SdlWindow(WindowSpec("Opaque styled image", 160, 80, supersample: 1), hidden: true)) {
            let renderer = window.renderer
            try (surface = Surface.create(16, 12)) {
                surface.clear(Color.rgb(240, 30, 20))
                try (texture = renderer.textureFromSurface(surface)) {
                    texture.setBlendMode(TextureBlendMode.None)
                    @Expect(unsafe { SDL_SetTextureScaleMode(texture.ptr, 0) })
                    let buffer = renderer.recordCommands {=>
                        renderer.textureStyled(texture, Rect(10.0, 10.0, 40.0, 30.0),
                            style: TextureStyle(opacity: 0.5, radius: 4.0))
                    }
                    // A style command owns its compositing, independently of later texture state.
                    for (blend in [TextureBlendMode.None, TextureBlendMode.Add]) {
                        texture.setBlendMode(blend)
                        var beforeBlend: UInt32 = 0
                        @Expect(unsafe { SDL_GetTextureBlendMode(texture.ptr, inout beforeBlend) })
                        renderer.beginScene(160.0, 80.0, Color.rgb(255, 255, 255))
                        @Expect(buffer.replay(renderer))
                        var restoredBlend: UInt32 = 0
                        var restoredSampling: Int32 = 0
                        @Expect(unsafe { SDL_GetTextureBlendMode(texture.ptr, inout restoredBlend) })
                        @Expect(unsafe { SDL_GetTextureScaleMode(texture.ptr, inout restoredSampling) })
                        @Expect(restoredBlend, beforeBlend)
                        @Expect(restoredSampling, Int32(0))
                        renderer.captureBmp(path)
                        renderer.endScene()
                        try (pixels = Surface.load(path)) {
                            let scale = pixels.size().w / 160.0
                            let center = pixels.readPixel(Int32(30.0 * scale), Int32(25.0 * scale))
                            @Expect(center.g >= UInt8(140) && center.g <= UInt8(145))
                        }
                    }
                }
            }
        }
    } finally {
        if (exists(path)) { remove(path) }
        remove(directory)
    }
}

@Test
func imageGeometryBoundsExtremeInputsBeforeNativeRendering(): Unit {
    var rejected = false
    try { validateImageRect(Rect(Float32.Max, 0.0, Float32.Max, 10.0)) }
    catch (_: IllegalArgumentException) { rejected = true }
    @Expect(rejected)
    let mesh = buildImageMesh(3.0e30, 3.0e30, 1.0e30)
    try {
        @Expect(mesh.vertCount <= Int64(520))
        for (i in 0..mesh.idxCount) {
            let index = unsafe { mesh.indices.read(i) }
            @Expect(index >= 0 && Int64(index) < mesh.vertCount)
        }
        for (i in 0..mesh.vertCount) {
            let point = unsafe { mesh.relVerts.read(i) }
            @Expect(!point.px.isInf() && !point.py.isInf())
        }
    } finally { mesh.free() }
}
