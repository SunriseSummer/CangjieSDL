package sdl

/*
 * Clip bookkeeping is renderer-side state independent of any SDL device, so a headless
 * renderer exercises the stack semantics directly: push intersects with the active clip,
 * pop restores the previous one, and a new scene always starts unclipped.
 */
@Test
func clipStackIntersectsOnPushAndRestoresOnPop(): Unit {
    let renderer = Renderer.headless()
    @Expect(renderer.currentClip().isNone())

    renderer.pushClip(Rect(0.0, 0.0, 100.0, 100.0))
    renderer.pushClip(Rect(60.0, 40.0, 100.0, 100.0))
    let nested = renderer.currentClip().getOrThrow()
    @Expect(nested.x, Float32(60.0))
    @Expect(nested.y, Float32(40.0))
    @Expect(nested.w, Float32(40.0))
    @Expect(nested.h, Float32(60.0))

    renderer.popClip()
    let outer = renderer.currentClip().getOrThrow()
    @Expect(outer.x, Float32(0.0))
    @Expect(outer.w, Float32(100.0))

    renderer.popClip()
    @Expect(renderer.currentClip().isNone())
}

@Test
func disjointNestedClipDegeneratesToZeroArea(): Unit {
    let renderer = Renderer.headless()
    renderer.pushClip(Rect(0.0, 0.0, 50.0, 50.0))
    renderer.pushClip(Rect(80.0, 80.0, 20.0, 20.0))

    let clip = renderer.currentClip().getOrThrow()
    @Expect(clip.w, Float32(0.0))
    @Expect(clip.h, Float32(0.0))

    renderer.popClip()
    renderer.popClip()
}

@Test
func beginSceneDropsAnyLeakedClip(): Unit {
    let renderer = Renderer.headless()
    renderer.pushClip(Rect(0.0, 0.0, 10.0, 10.0))

    renderer.beginScene(100.0, 100.0, Color.rgb(0, 0, 0))

    @Expect(renderer.currentClip().isNone())
}

// The headless contract: every rendering entry point is a no-op and every query returns a
// neutral value, so custom shells and canvas code run unchanged in windowless tests.
@Test
func headlessRendererNoOpsAndAnswersNeutrally(): Unit {
    let renderer = Renderer.headless()

    // Setters are no-ops rather than throwing on the missing device.
    renderer.setScale(2.0)
    renderer.setVSync(1)
    renderer.setViewport(Rect(10.0, 10.0, 100.0, 80.0))
    renderer.resetViewport()
    renderer.setColorScale(1.5)
    renderer.setColorFloat(0.2, 0.4, 0.6, 1.0)
    renderer.captureBmp("never-written.bmp")

    // Queries answer with neutral values.
    @Expect(renderer.vsync(), Int32(0))
    @Expect(renderer.viewport().w, Float32(0.0))
    @Expect(renderer.colorScale(), Float32(1.0))

    // Clip queries fall back to the logical clip stack, which works headlessly.
    @Expect(!renderer.clipEnabled())
    renderer.pushClip(Rect(4.0, 6.0, 40.0, 30.0))
    @Expect(renderer.clipEnabled())
    @Expect(renderer.clipRect().x, Float32(4.0))
    @Expect(renderer.clipRect().h, Float32(30.0))
    renderer.popClip()
    @Expect(renderer.clipRect().w, Float32(0.0))
}
