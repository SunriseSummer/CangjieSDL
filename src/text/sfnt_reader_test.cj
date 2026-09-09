package sdl.text

import std.fs.{Directory, File, remove}

@Test
func sfntNamesDecodeUnicodeWithoutAcceptingBrokenSurrogates(): Unit {
    @Expect(sfntUtf16([0, 65, 0x4E, 0x2D, 0xD8, 0x3D, 0xDE, 0]), "A中😀")
    let invalid: Array<Array<UInt8>> = [[0], [0xD8, 0], [0xDC, 0], [0xD8, 0, 0, 65]]
    for (bytes in invalid) {
        var rejected = false
        try { let _ = sfntUtf16(bytes) } catch (_: NativeTextException) { rejected = true }
        @Expect(rejected)
    }
    @Expect(sfntFixed([0xFF, 0xFF, 0x80, 0], 0), Float32(-0.5))
    @Expect(sfntFixed([0, 1, 0x40, 0], 0), Float32(1.25))
}

@Test
func sfntReaderRejectsTruncationAndOutOfFileTableOffsets(): Unit {
    let directory = Directory.createTemp(".").toString()
    let path = directory + "/bad.ttf"
    try {
        let invalid: Array<Array<UInt8>> = [[0, 1],
            [0, 1, 0, 0, 0xFF, 0xFF, 0, 0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 110, 97, 109, 101, 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 1]]
        for (bytes in invalid) {
            File.writeTo(path, bytes)
            var rejected = false
            try { let _ = SfntFile(path) } catch (_: NativeTextException) { rejected = true }
            @Expect(rejected)
        }
    } finally { remove(path); remove(directory) }
}

@Test
func sfntFileCacheKeepsReadsStableUntilExplicitInvalidation(): Unit {
    let directory = Directory.createTemp(".").toString()
    let path = directory + "/missing.ttf"
    // An absent optional style is remembered without touching the filesystem on each request.
    try {
        for (_ in 0..2) {
            var rejected = false
            try { let _ = sfntFile(path) } catch (_: NativeTextException) { rejected = true }
            @Expect(rejected)
        }
        forgetNativeFontMetadata(path)
        var rejected = false
        try { let _ = sfntFile(path) } catch (_: NativeTextException) { rejected = true }
        @Expect(rejected)
    } finally { clearNativeFontMetadata(); remove(directory) }
}
