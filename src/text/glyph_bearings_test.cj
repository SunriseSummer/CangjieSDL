package sdl.text

import std.fs.exists
import std.runtime.gc

private func bearingTestFont(): ?NativeFontSource {
    for (source in nativeSystemFontCandidates()) { if (exists(source.path)) { return Some(source) } }
    None
}

@Test
func syntheticItalicMatchesOfficialPixelsAndPreservesOverhang(): Unit {
    let source = match (bearingTestFont()) { case Some(value) => value; case None => return }
    @Expect(unsafe { TTF_Init() })
    let baseline = activeFontStreams()
    let filename = unsafe { LibC.mallocCString(source.path) }
    let font = unsafe { TTF_OpenFont(filename, 32.0) }
    unsafe { LibC.free(filename) }
    @Expect(font.isNotNull())
    if (font.isNull()) { unsafe { TTF_Quit() }; return }
    let engine = createNativeTextEngine(CPointer<Unit>())
    try {
        unsafe { TTF_SetFontStyle(font, 2) }
        registerNativeEngineFont(engine, font, source, 32.0, 2)
        for (sample in ["AV office ffi jy", "保存 仓颉", "j ǵ Åé Vy"]) {
            let text = unsafe { LibC.mallocCString(sample) }
            try (encoded = text.asResource()) {
                let layout = createNativeText(engine, font, encoded.value, UIntNative(sample.size))
                @Expect(layout.isNotNull())
                if (layout.isNull()) { continue }
                var actual = CPointer<Unit>(); var reference = CPointer<Unit>()
                try {
                    let entry = nativeEngineEntry(layout)
                    let positioned = nativeEngineColorSurface(entry.layout, nativeTextEngine(engine), None)
                    actual = positioned.pointer
                    reference = unsafe { TTF_RenderText_Blended(font, encoded.value, UIntNative(sample.size), 0xFFFFFFFF) }
                    @Expect(actual.isNotNull() && reference.isNotNull())
                    if (actual.isNull() || reference.isNull()) { continue }
                    expectPositionedGlyphSurface(positioned, reference)
                    gc(heavy: true)
                } finally {
                    if (actual.isNotNull()) { unsafe { SDL_DestroySurface(actual) } }
                    if (reference.isNotNull()) { unsafe { SDL_DestroySurface(reference) } }
                    destroyNativeText(layout)
                }
            }
        }
    } finally {
        forgetNativeEngineFont(engine, font)
        unsafe { TTF_CloseFont(font) }
        destroyNativeTextEngine(engine)
        @Expect(activeFontStreams(), baseline)
        unsafe { TTF_Quit() }
    }
}

@Test
func glyphProbeCmapAvoidsNoncharactersAndUsesSmallBoundedTables(): Unit {
    let bytes = sfntGlyphProbeCmap(65535)
    @Expect(bytes.size, Int64(52))
    @Expect(sfntU32(bytes, 24), UInt32(2))
    @Expect(glyphProbeCodepoint(65533), UInt32(0xFFFFD))
    @Expect(glyphProbeCodepoint(65534), UInt32(0xE000))
    @Expect(fontAxisTagCode("wght"), AXIS_WEIGHT)
}

private func expectPositionedGlyphSurface(actual: NativeTextSurface, reference: CPointer<Unit>): Unit {
    let left = unsafe { CPointer<EngineSurface>(actual.pointer).read() }
    let right = unsafe { CPointer<EngineSurface>(reference).read() }
    @Expect(Int32(actual.width), right.width); @Expect(Int32(actual.height), right.height)
    @Expect(actual.x <= 0 && actual.y <= 0)
    @Expect(left.width + actual.x >= right.width && left.height + actual.y >= right.height)
    var differences: Int64 = 0
    for (y in 0..Int64(right.height)) {
        let a = unsafe { CPointer<UInt32>(CPointer<UInt8>(left.pixels) + (y - Int64(actual.y)) * Int64(left.pitch)) }
        let b = unsafe { CPointer<UInt32>(CPointer<UInt8>(right.pixels) + y * Int64(right.pitch)) }
        for (x in 0..Int64(right.width)) {
            if (unsafe { a.read(x - Int64(actual.x)) } != unsafe { b.read(x) }) { differences += 1 }
        }
    }
    @Expect(differences, Int64(0))
    // Native RenderText can crop an italic j's negative bearing. Newly retained padding must
    // contain real ink; compare the entire original visible region above without discarding it.
    if (actual.x < 0 || actual.y < 0) {
        var retained: Int64 = 0
        for (y in 0..Int64(left.height)) {
            let row = unsafe { CPointer<UInt32>(CPointer<UInt8>(left.pixels) + y * Int64(left.pitch)) }
            for (x in 0..Int64(left.width)) {
                if ((x + Int64(actual.x) < 0 || y + Int64(actual.y) < 0) && (unsafe { row.read(x) } >> 24) != 0) { retained += 1 }
            }
        }
        @Expect(retained > 0)
    }
}
