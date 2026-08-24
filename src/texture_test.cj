package sdl

@Test
func textureRenderOptionsUseSafeDefaults(): Unit {
    let options = TextureRenderOptions()

    @Expect(isNoSource(options.source))
    @Expect(isNoCenter(options.center))
    @Expect(isNoFlip(options.flip))
}

@Test
func textureRenderOptionsKeepExplicitFlip(): Unit {
    let options = TextureRenderOptions(flip: TextureFlip.Horizontal)

    @Expect(isHorizontalFlip(options.flip))
}

@Test
func textureBecomesClosedWhenItsRendererIsDestroyed(): Unit {
    let window = SdlWindow(WindowSpec("Texture owner lifetime", 120, 80, supersample: 1))
    let surface = Surface.create(2, 2)
    let texture = window.renderer.textureFromSurface(surface)
    surface.close()

    window.close()

    @Expect(texture.isClosed())
    texture.close() // renderer destruction already freed the native texture; this must not double-free
}

private func isNoSource(source: ?Rect): Bool {
    match (source) {
        case None => true
        case Some(_) => false
    }
}

private func isNoCenter(center: ?Point): Bool {
    match (center) {
        case None => true
        case Some(_) => false
    }
}

private func isNoFlip(flip: TextureFlip): Bool {
    match (flip) {
        case TextureFlip.None => true
        case _ => false
    }
}

private func isHorizontalFlip(flip: TextureFlip): Bool {
    match (flip) {
        case TextureFlip.Horizontal => true
        case _ => false
    }
}
