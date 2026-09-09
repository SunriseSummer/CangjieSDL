package sdl.text

@When[os == "Windows"]
@Test
func windowsFontSourceKeysDeduplicateSlashAndCaseAliases(): Unit {
    let left = NativeFontSource("C:/Windows/Fonts/seguiemj.ttf", 0)
    let right = NativeFontSource("c:\\WINDOWS\\Fonts\\SEGUIEMJ.TTF", 0)
    @Expect(left.key(), right.key())
    @Expect(left.key() != NativeFontSource(right.path, 1).key())
    @Expect(left.key() != NativeFontSource(right.path, 0,
        coordinates: [NativeFontCoordinate("wght", 500.0)]).key())
}

@When[os != "Windows"]
@Test
func fontSourceKeysPreserveCaseOnOtherPlatforms(): Unit {
    @Expect(NativeFontSource("/fonts/Example.ttf", 0).key() != NativeFontSource("/fonts/example.ttf", 0).key())
}

@Test
func normalizedFontSizesUseOneGridAndRejectNonFiniteValues(): Unit {
    @Expect(normalizeFontPointSize(13.003), Float32(13.0))
    @Expect(normalizeFontPointSize(0.0), Float32(15.0))
    for (bits in [UInt32(0x7FC00000), UInt32(0x7F800000), UInt32(0xFF800000)]) {
        var rejected = false
        try {
            let value = normalizeFontPointSize(Float32.fromBits(bits))
            @Fail("Non-finite size was accepted as ${value}")
        } catch (_: IllegalArgumentException) {
            rejected = true
        }
        @Expect(rejected)
    }
}
