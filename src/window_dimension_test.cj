package sdl

@Test
func windowDimensionsRejectInvalidSizesAndOverflowBeforeNativeCalls(): Unit {
    var rejected = 0
    try { let _ = WindowSpec("bad", 0, 20) } catch (_: IllegalArgumentException) { rejected += 1 }
    try { let _ = scaledDimension(2147483647, 2.0) } catch (_: IllegalArgumentException) { rejected += 1 }
    @Expect(rejected, 2)
    @Expect(scaledDimension(0, 2.0), Int32(0))
    @Expect(scaledDimension(1, 0.1), Int32(1))
    @Expect(normalizedScale(Float32.NaN), Float32(1.0))
}
