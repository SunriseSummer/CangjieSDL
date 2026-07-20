package sdl

@Test
func colorFactoryClampsChannels(): Unit {
    let color = Color.rgba(-20, 42, 999, 300)

    @Expect(color.r, UInt8(0))
    @Expect(color.g, UInt8(42))
    @Expect(color.b, UInt8(255))
    @Expect(color.a, UInt8(255))
}

@Test
func rectHelpersPreserveExpectedGeometry(): Unit {
    let rect = Rect(10.0, 20.0, 100.0, 50.0)

    @Expect(rect.right(), Float32(110.0))
    @Expect(rect.bottom(), Float32(70.0))
    @Expect(rect.centerX(), Float32(60.0))
    @Expect(rect.centerY(), Float32(45.0))
    @Expect(rect.contains(10.0, 20.0))
    @Expect(rect.contains(110.0, 70.0))
    @Expect(!rect.contains(111.0, 70.0))
}

@Test
func insetsShrinkWithoutNegativeSize(): Unit {
    let rect = Rect(0.0, 0.0, 12.0, 8.0).inset(8.0)

    @Expect(rect.x, Float32(8.0))
    @Expect(rect.y, Float32(8.0))
    @Expect(rect.w, Float32(0.0))
    @Expect(rect.h, Float32(0.0))
}

@Test
func rectIntersectionCoversOverlapContainmentAndDisjoint(): Unit {
    let base = Rect(0.0, 0.0, 100.0, 60.0)

    let overlap = base.intersection(Rect(40.0, 20.0, 100.0, 100.0))
    @Expect(overlap.x, Float32(40.0))
    @Expect(overlap.y, Float32(20.0))
    @Expect(overlap.w, Float32(60.0))
    @Expect(overlap.h, Float32(40.0))

    let contained = base.intersection(Rect(10.0, 10.0, 20.0, 20.0))
    @Expect(contained.x, Float32(10.0))
    @Expect(contained.w, Float32(20.0))

    let disjoint = base.intersection(Rect(200.0, 200.0, 10.0, 10.0))
    @Expect(disjoint.w, Float32(0.0))
    @Expect(disjoint.h, Float32(0.0))
}

@Test
func colorLerpInterpolatesChannelsAndClampsT(): Unit {
    let from = Color.rgba(0, 0, 0, 0)
    let to = Color.rgba(100, 200, 40, 255)

    let mid = from.lerp(to, 0.5)
    @Expect(mid.r, UInt8(50))
    @Expect(mid.g, UInt8(100))
    @Expect(mid.b, UInt8(20))
    @Expect(mid.a, UInt8(127))

    @Expect(from.lerp(to, 2.0).r, UInt8(100)) // t clamps to 1
    @Expect(from.lerp(to, -1.0).r, UInt8(0)) // t clamps to 0
}

@Test
func clampF32HonorsBounds(): Unit {
    @Expect(clampF32(-3.0, 0.0, 2.0), Float32(0.0))
    @Expect(clampF32(1.5, 0.0, 2.0), Float32(1.5))
    @Expect(clampF32(5.0, 0.0, 2.0), Float32(2.0))
}

@Test
func pointConvertsToSdlFPoint(): Unit {
    let raw = Point(12.5, 18.25).toSdlFPoint()

    @Expect(raw.x, Float32(12.5))
    @Expect(raw.y, Float32(18.25))
}

@Test
func pointConvertsToSdlPoint(): Unit {
    let raw = Point(12.5, 18.25).toSdlPoint()

    @Expect(raw.x, Int32(12))
    @Expect(raw.y, Int32(18))
}
