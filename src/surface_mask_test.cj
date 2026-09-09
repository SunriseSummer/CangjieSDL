package sdl

@Test
func alphaMaskPreservesCoverageAndDoesNotModifySource(): Unit {
    try (source = Surface.create(3, 2)) {
        source.clear(Color(20, 100, 220, 0))
        source.writePixel(1, 0, Color(0, 0, 0, 128))
        source.writePixel(2, 1, Color(180, 10, 90, 255))
        try (mask = source.alphaMask()) {
            @Expect(mask.size().w, Float32(3))
            @Expect(mask.size().h, Float32(2))
            for (y in 0..2) {
                for (x in 0..3) {
                    let actual = mask.readPixel(Int32(x), Int32(y))
                    @Expect(actual.r, UInt8(255))
                    @Expect(actual.g, UInt8(255))
                    @Expect(actual.b, UInt8(255))
                    @Expect(actual.a, source.readPixel(Int32(x), Int32(y)).a)
                }
            }
            @Expect(source.readPixel(1, 0).r, UInt8(0))
            @Expect(source.readPixel(2, 1).b, UInt8(90))
            source.close()
            @Expect(mask.readPixel(1, 0).a, UInt8(128))
        }
    }
}

@Test
func alphaMaskConvertsIndexedTransparencyAndRejectsClosedInput(): Unit {
    let data = "/* XPM */\nstatic char *icon[] = {\n\"2 1 2 1\",\n\". c None\",\n\"X c #000000\",\n\".X\"\n};\n"
    let source = Surface.loadBytes(data.toArray(), typeHint: "XPM")
    try {
        try (mask = source.alphaMask()) {
            @Expect(mask.readPixel(0, 0).a, UInt8(0))
            @Expect(mask.readPixel(1, 0).a, UInt8(255))
            @Expect(mask.readPixel(1, 0).r, UInt8(255))
        }
    } finally { source.close() }
    var rejected = false
    try { let result = source.alphaMask(); result.close() } catch (_: SdlException) { rejected = true }
    @Expect(rejected)
}
