package sdl.text

import std.fs.exists
import std.runtime.gc

@Test
func callbackFreeTextLayoutsRebuildAndReleaseDeterministically(): Unit {
    let path = "C:/Windows/Fonts/arial.ttf"
    if (!exists(path)) { return }
    @Assert(unsafe { TTF_Init() })
    let name = unsafe { LibC.mallocCString(path) }
    let font = unsafe { TTF_OpenFont(name, 24.0) }
    unsafe { LibC.free(name) }
    @Assert(font.isNotNull())
    let engine = createNativeTextEngine(CPointer<Unit>())
    try {
        registerNativeEngineFont(engine, font, NativeFontSource(path, 0), 24.0, 0)
        let sample = unsafe { LibC.mallocCString("AV office") }
        try (encoded = sample.asResource()) {
            let text = createNativeText(engine, font, encoded.value, UIntNative(9))
            @Assert(text.isNotNull())
            try {
                let first = nativeEngineEntry(text).layout.metrics.width
                let data = unsafe { CPointer<EngineText>(text).read().data.read() }
                @Expect(data.engine.isNull() && data.engineText.isNull())
                @Expect(data.operationCount > 0)
                for (_ in 0..8) {
                    gc(heavy: true)
                    @Expect(nativeEngineEntry(text).layout.metrics.width, first)
                    @Expect(nativeTextEngine(engine).texts.size, Int64(1))
                }
                unsafe { TTF_SetFontStyle(font, 1) }
                @Expect(nativeEngineEntry(text).layout.metrics.width > first)
                @Expect(nativeTextEngine(engine).texts.size, Int64(1))
                var rejected = false
                try { destroyNativeTextEngine(engine) } catch (_: IllegalStateException) { rejected = true }
                @Expect(rejected)
                @Expect(nativeTextEngine(engine).owned.size, Int64(1))
            } finally { destroyNativeText(text) }
        }
        @Expect(nativeTextEngine(engine).owned.isEmpty())
        @Expect(nativeTextEngine(engine).texts.isEmpty())
    } finally {
        forgetNativeEngineFont(engine, font)
        unsafe { TTF_CloseFont(font) }
        destroyNativeTextEngine(engine)
        unsafe { TTF_Quit() }
    }
    destroyNativeTextEngine(engine)
}

@Test
func callbackFreeEmojiRenderingSurvivesCollectionAndRepeatedInvalidation(): Unit {
    let path = "C:/Windows/Fonts/msyh.ttc"
    if (!exists(path) || !exists("C:/Windows/Fonts/seguiemj.ttf")) { return }
    let streams = activeFontStreams()
    let source = NativeFontSource(path, 1)
    let renderer = NativeTextRenderer(CPointer<Unit>(), bootstrapSources: Some([source]))
    try {
        let family = NativeFontFamily(source, [], "gc-emoji")
        for (i in 0..120) {
            let sample = "AV office 仓颉 🎉 👩🏽‍💻 " + Rune(UInt32(0x1F300 + i % 32)).toString()
            let surface = renderer.renderSurface(sample, Float32(18 + i % 12), Int32(i % 4), family)
            @Assert(surface.isNotNull())
            unsafe { SDL_DestroySurface(surface) }
            if (i % 8 == 0) { gc(heavy: true) }
            if (i % 13 == 0) { renderer.invalidateFonts() }
        }
    } finally { renderer.close() }
    @Expect(activeFontStreams(), streams)
}
