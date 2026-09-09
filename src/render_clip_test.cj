package sdl

@Test
func textScissorMatchesSdlScaledPrimitiveScissor(): Unit {
    // SDL floors the scaled integer origin and ceils the scaled integer extent independently.
    let value = scaledSdlClipRect(Rect(23.0, 37.25, 3.5, 28.0), 4.5, 4.5)
    @Expect(value.x, Int32(103))
    @Expect(value.y, Int32(166))
    @Expect(value.w, Int32(18))
    @Expect(value.h, Int32(131))
    let negative = scaledSdlClipRect(Rect(-0.5, -1.2, 2.1, 3.1), 1.25, 2.5)
    @Expect(negative.x, Int32(-2))
    @Expect(negative.y, Int32(-5))
    @Expect(negative.w, Int32(4))
    @Expect(negative.h, Int32(10))
    @Expect(scaledSdlClipRect(Rect(0.5, 0.5, 0.0, 3.0), 1.5, 1.5).w, Int32(0))
}

@Test
func scaledClipRejectsNonFiniteAndOutOfRangeCoordinates(): Unit {
    for (scale in [Float32(0.0), Float32(-1.0), Float32.NaN, Float32.Inf]) {
        var rejected = false
        try { let _ = scaledSdlClipRect(Rect(0.0, 0.0, 10.0, 10.0), scale, 1.0) }
        catch (_: IllegalArgumentException) { rejected = true }
        @Expect(rejected)
    }
    var rejected = false
    try { let _ = scaledSdlClipRect(Rect(1000000000.0, 0.0, 10.0, 10.0), 4.0, 1.0) }
    catch (_: IllegalArgumentException) { rejected = true }
    @Expect(rejected)
}

@Test
func damageEdgesRemainPixelAlignedAcrossNestedClips(): Unit {
    let region = alignedDamageClip(Rect(23.0, 37.25, 3.5, 28.0), 4.5, 4.5).getOrThrow()
    @Expect(region.x, Float32(22.0)); @Expect(region.right(), Float32(28.0))
    let parent = scaledSdlClipRect(region, 4.5, 4.5)
    let nested = scaledSdlClipRect(region.intersection(Rect(24.0, 0.0, 300.0, 200.0)), 4.5, 4.5)
    @Expect(parent.x + parent.w, nested.x + nested.w)
    @Expect(alignedDamageClip(Rect(21.0, 22.0, 2.0, 3.0), 1.4142135, 1.4142135).isNone())
}
