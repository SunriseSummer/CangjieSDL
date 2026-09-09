package sdl.text

import std.fs.exists

// Independent reference: SDL's public cluster rect contains its top compensation. The font
// ascent alone is not the baseline of a shaped surface whose glyphs extend above the font box.
@Test
func emojiFallbackUsesNativeClusterBaselineInsteadOfSurfaceTop(): Unit {
    let emojiPath = "C:/Windows/Fonts/seguiemj.ttf"
    if (!exists(emojiPath)) { return }
    for (primaryPath in ["C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/consola.ttf"]) {
        if (!exists(primaryPath)) { continue }
        for (size in [20.0f32, 40.5f32, 48.0f32, 81.0f32]) {
            @Assert(unsafe { TTF_Init() })
            let engine = createNativeTextEngine(CPointer<Unit>())
            var primary = CPointer<Unit>(); var emoji = CPointer<Unit>()
            try {
                primary = openBaselineTestFont(primaryPath, size)
                emoji = openBaselineTestFont(emojiPath, size)
                registerNativeEngineFont(engine, primary, NativeFontSource(primaryPath, 0), size, 0)
                registerNativeEngineFont(engine, emoji, NativeFontSource(emojiPath, 0), size, 0)
                @Assert(unsafe { TTF_AddFallbackFont(primary, emoji) })
                nativeTextEngine(engine).fallbacks[primary.toUIntNative()] = [emoji]
                for (unit in ["🎉", "👩🏽‍💻", "❤\u{FE0F}"]) {
                    for (sample in ["HH" + unit + "HH", "HH" + unit + "\nHH" + unit]) {
                        expectEmojiRunBaseline(engine, primary, emoji, sample, unit)
                    }
                }
                // Raw primary-emoji rendering remains compatible with SDL. Its text-local
                // cluster box retains the compensation; only embedding it as a run removes it.
                let own = baselineTestLayout(engine, emoji, "H🎉H")
                @Expect(own.clusters[0].rect.y > 0)
            } finally {
                if (primary.isNotNull()) { forgetNativeEngineFont(engine, primary); unsafe { TTF_CloseFont(primary) } }
                if (emoji.isNotNull()) { forgetNativeEngineFont(engine, emoji); unsafe { TTF_CloseFont(emoji) } }
                destroyNativeTextEngine(engine)
                unsafe { TTF_Quit() }
            }
        }
    }
}

private func openBaselineTestFont(path: String, size: Float32): CPointer<Unit> {
    let encoded = unsafe { LibC.mallocCString(path) }
    try (resource = encoded.asResource()) {
        let font = unsafe { TTF_OpenFont(resource.value, size) }
        if (font.isNull()) { throw NativeTextException("Cannot open baseline test font") }
        return font
    }
    throw IllegalStateException("Font was not opened")
}

private func baselineTestLayout(engine: CPointer<Unit>, font: CPointer<Unit>, sample: String): EngineLayout {
    let encoded = unsafe { LibC.mallocCString(sample) }
    try (resource = encoded.asResource()) {
        let text = createNativeText(engine, font, resource.value, UIntNative(sample.size))
        @Assert(text.isNotNull())
        try { return nativeEngineEntry(text).layout }
        finally { destroyNativeText(text) }
    }
    throw IllegalStateException("Layout was not created")
}

private func expectEmojiRunBaseline(engine: CPointer<Unit>, primary: CPointer<Unit>, emoji: CPointer<Unit>,
    sample: String, unit: String): Unit {
    let actual = baselineTestLayout(engine, primary, sample)
    let encoded = unsafe { LibC.mallocCString(unit) }
    try (resource = encoded.asResource()) {
        let text = unsafe { TTF_CreateText(CPointer<Unit>(), emoji, resource.value, UIntNative(unit.size)) }
        @Assert(text.isNotNull())
        try {
            @Assert(unsafe { TTF_UpdateText(text) })
            let data = unsafe { CPointer<EngineText>(text).read().data.read() }
            let origin = unsafe { data.clusters.read().rect.y }
            let ascent = unsafe { TTF_GetFontAscent(primary) - TTF_GetFontAscent(emoji) }
            let lineSkip = unsafe { TTF_GetFontLineSkip(primary) }
            var compared: Int64 = 0
            for (draw in actual.draws) {
                if (draw.font.toUIntNative() != emoji.toUIntNative()) { continue }
                for (i in 0..Int64(data.operationCount)) {
                    let operation = unsafe { data.operations.read(i) }
                    if (operation.command == 2 && operation.glyph == draw.glyph) {
                        let expected = operation.destination.y + ascent - origin + Int32(draw.line) * lineSkip
                        @Expect(draw.rectangle.y, expected)
                        compared += 1
                    }
                }
            }
            @Expect(compared > 0)
            // Ordinary H stays on the primary font's baseline in both lines.
            let h = baselineTestLayout(engine, primary, "H").draws[0]
            for (draw in actual.draws) {
                if (draw.font.toUIntNative() == primary.toUIntNative() && draw.glyph == h.glyph) {
                    @Expect(draw.rectangle.y, h.rectangle.y + Int32(draw.line) * lineSkip)
                }
            }
        } finally { unsafe { TTF_DestroyText(text) } }
    }
}
