package sdl.text

import std.fs.exists

@Test
func colorFontCacheUsesTableBytesAndPreservesLeasedSessions(): Unit {
    let path = "C:/Windows/Fonts/seguiemj.ttf"
    let ui = "C:/Windows/Fonts/msyh.ttc"
    if (!exists(path) || !exists(ui)) { return }
    var cost: Int64 = 0
    for (table in sfntFile(path).faces[0].tables) {
        if (table.tagCode == SFNT_COLOR_LAYERS || table.tagCode == SFNT_COLOR_PALETTE) { cost += table.length }
    }
    if (cost == 0) { return }
    let capacity = max(1, min(24, (64 * 1024 * 1024) / cost))
    let renderer = NativeTextRenderer(CPointer<Unit>(), bootstrapSources: Some([NativeFontSource(ui, 1)]))
    let family = NativeFontFamily(NativeFontSource(path, 0), [], "color-budget")
    try {
        let session = renderer.measureSession("A🎉B", 20.0, 0, family)
        try {
            let width = session.measure(0, "A🎉B".size)
            for (size in 12..60) {
                let _ = renderer.measure("🎉", Float32(size), 0, family)
                @Expect(renderer.fontGroupCount() <= capacity)
                @Expect(session.measure(0, "A🎉B".size), width)
            }
            renderer.invalidateFonts()
            @Expect(renderer.fontGroupCount(), Int64(0))
            @Expect(session.measure(0, "A🎉B".size), width)
        } finally { session.close() }
    } finally { renderer.close() }
}
