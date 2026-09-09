package sdl.text

import std.fs.exists

@Test
func largeColorProbeReleasesAfterEachPassAndRetainsNumericBearings(): Unit {
    let path = "C:/Windows/Fonts/seguiemj.ttf"
    if (!exists(path)) { return }
    @Assert(unsafe { TTF_Init() })
    let baseline = activeFontStreams()
    let encoded = unsafe { LibC.mallocCString(path) }
    let font = unsafe { TTF_OpenFont(encoded, 20.0) }
    unsafe { LibC.free(encoded) }
    @Assert(font.isNotNull())
    let queue = GlyphProbeReleases()
    let source = GlyphRasterSource(NativeFontSource(path, 0), 20.0, 0, releases: Some(queue))
    try {
        for (sample in ["🎉", "😀", "🚀"]) {
            let value = unsafe { LibC.mallocCString(sample) }
            let text = unsafe { TTF_CreateText(CPointer<Unit>(), font, value, UIntNative(sample.size)) }
            unsafe { LibC.free(value) }
            @Assert(text.isNotNull())
            try {
                @Assert(unsafe { TTF_UpdateText(text) })
                let operation = unsafe { CPointer<EngineText>(text).read().data.read().operations.read() }
                var kind: Int32 = 0
                let image = unsafe { TTF_GetGlyphImageForIndex(font, operation.glyph, inout kind) }
                @Assert(image.isNotNull())
                try {
                    @Assert(kind, Int32(2))
                    let bearing = source.bearing(operation.glyph, image, kind == 2)
                    @Expect(activeFontStreams(), baseline + 1)
                    queue.flush()
                    @Expect(activeFontStreams(), baseline)
                    let cached = source.bearing(operation.glyph, image, kind == 2)
                    @Expect(cached.x, bearing.x)
                    @Expect(cached.y, bearing.y)
                    @Expect(activeFontStreams(), baseline)
                } finally { unsafe { SDL_DestroySurface(image) } }
            } finally { unsafe { TTF_DestroyText(text) } }
        }
    } finally { queue.flush(); source.close(); unsafe { TTF_CloseFont(font); TTF_Quit() } }
    @Expect(activeFontStreams(), baseline)
}

@Test
func decoratedEmojiSurfaceFlushesBackupProbes(): Unit {
    let path = "C:/Windows/Fonts/seguiemj.ttf"
    if (!exists(path)) { return }
    let baseline = activeFontStreams()
    let source = NativeFontSource(path, 0)
    let renderer = NativeTextRenderer(CPointer<Unit>(), bootstrapSources: Some([source]))
    let family = NativeFontFamily(source, [], "decorated-emoji")
    try {
        for (sample in ["🎉", "😀🚀", "🎉😀🚀"]) {
            // Decorations make original-font sampling inapplicable, exercising the backup path.
            let surface = renderer.renderSurface(sample, 20.0, 4, family)
            @Assert(surface.isNotNull())
            unsafe { SDL_DestroySurface(surface) }
            @Expect(activeFontStreams(), baseline)
        }
    } finally { renderer.close() }
    @Expect(activeFontStreams(), baseline)
}

@Test
func mixedEmojiCalibrationReusesOpenedFonts(): Unit {
    let path = "C:/Windows/Fonts/msyh.ttc"
    if (!exists(path) || !exists("C:/Windows/Fonts/seguiemj.ttf")) { return }
    let baseline = activeFontStreams()
    let source = NativeFontSource(path, 1)
    let renderer = NativeTextRenderer(CPointer<Unit>(), bootstrapSources: Some([source]))
    try {
        let family = NativeFontFamily(source, [], "mixed-emoji-sample")
        for (sample in ["AV office 仓颉 🎉", "AV office 仓颉 🎉 👩🏽‍💻"]) {
            let surface = renderer.renderSurface(sample, 20.0, 0, family)
            @Assert(surface.isNotNull())
            unsafe { SDL_DestroySurface(surface) }
            @Expect(activeFontStreams(), baseline)
        }
    } finally { renderer.close() }
    @Expect(activeFontStreams(), baseline)
}

@Test
func glyphSampleCalibrationMatchesGlyphIdOracleWithoutExtraFontStreams(): Unit {
    let emoji = "C:/Windows/Fonts/seguiemj.ttf"
    let latin = "C:/Windows/Fonts/arial.ttf"
    if (!exists(emoji) || !exists(latin)) { return }
    @Expect(unsafe { TTF_Init() })
    let baseline = activeFontStreams()
    try {
        for (path in [emoji, latin]) {
            for (size in [Float32(16.0), Float32(25.0), Float32(40.0)]) {
                let encoded = unsafe { LibC.mallocCString(path) }
                let font = unsafe { TTF_OpenFont(encoded, size) }
                unsafe { LibC.free(encoded) }
                @Assert(font.isNotNull())
                let style: Int32 = if (path == latin) { 2 } else { 0 }
                unsafe { TTF_SetFontStyle(font, style) }
                let oracle = GlyphRasterSource(NativeFontSource(path, 0), size, style)
                let reused = GlyphRasterSource(NativeFontSource(path, 0), size, style, original: font)
                try {
                    let samples = if (path == emoji) { ["🎉", "👩🏽‍💻", "❤\u{FE0F}"] } else { ["j", "Å", "f"] }
                    for (sample in samples) {
                        expectSampleBearing(font, oracle, reused, sample)
                    }
                } finally { reused.close(); oracle.close(); unsafe { TTF_CloseFont(font) } }
                @Expect(activeFontStreams(), baseline)
            }
        }
    } finally { unsafe { TTF_Quit() } }
}

private func expectSampleBearing(font: CPointer<Unit>, oracle: GlyphRasterSource, reused: GlyphRasterSource,
    sample: String): Unit {
    let encoded = unsafe { LibC.mallocCString(sample) }
    try (value = encoded.asResource()) {
        let text = unsafe { TTF_CreateText(CPointer<Unit>(), font, value.value, UIntNative(sample.size)) }
        @Assert(text.isNotNull())
        try {
            @Assert(unsafe { TTF_UpdateText(text) })
            let data = unsafe { CPointer<EngineText>(text).read().data.read() }
            @Assert(data.operationCount, Int32(1))
            let operation = unsafe { data.operations.read() }
            var kind: Int32 = 0
            let image = unsafe { TTF_GetGlyphImageForIndex(font, operation.glyph, inout kind) }
            @Assert(image.isNotNull())
            try {
                let streams = activeFontStreams()
                let correction = sampleGlyphBearing(font, operation.glyph, sample, image)
                // A clipped italic sample must be rejected and use the glyph-ID oracle instead.
                // All color samples in this matrix fit completely and must avoid that allocation.
                @Assert(correction.isSome() || kind != 2)
                @Expect(activeFontStreams(), streams)
                let expected = oracle.bearing(operation.glyph, image, kind == 2)
                if (let Some(actual) <- correction) {
                    @Expect(actual.x, expected.x)
                    @Expect(actual.y, expected.y)
                }
                reused.rememberSample(operation.glyph, sample, 0, sample.size)
                let actual = reused.bearing(operation.glyph, image, kind == 2)
                @Expect(actual.x, expected.x)
                @Expect(actual.y, expected.y)
                @Expect(sampleGlyphBearing(font, operation.glyph + 1, sample, image).isNone())
                @Expect(sampleGlyphBearing(font, operation.glyph, "unrelated text", image).isNone())
                let wrong = unsafe { SDL_CreateSurface(2, 2, GLYPH_PIXEL_FORMAT) }
                @Assert(wrong.isNotNull())
                try {
                    @Assert(unsafe { SDL_FillSurfaceRect(wrong, CPointer<TtfSubstringRect>(), 0xFFFFFFFF) })
                    @Expect(sampleGlyphBearing(font, operation.glyph, sample, wrong).isNone())
                } finally { unsafe { SDL_DestroySurface(wrong) } }
            } finally { unsafe { SDL_DestroySurface(image) } }
        } finally { unsafe { TTF_DestroyText(text) } }
    }
}
