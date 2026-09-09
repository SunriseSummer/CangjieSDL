package sdl

import std.fs.{Directory, File, remove, exists}
import std.runtime.gc

@Test
func fontAtlasEvictsWithinBudgetAndRebuildsIdenticalVisibleText(): Unit {
    let directory = Directory.createTemp(".").toString()
    let before = directory + "/before.bmp"; let after = directory + "/after.bmp"
    let window = SdlWindow(WindowSpec("Font atlas budget", 400, 120, supersample: 1), hidden: true)
    try {
        let renderer = window.renderer
        captureBudgetText(renderer, before)
        for (iteration in 0..64) {
            renderer.beginScene(400.0, 120.0, Color.rgb(255, 255, 255))
            renderer.setScale(1.0)
            renderer.text("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", 8.0, 8.0,
                Color.rgb(24, 65, 130), pointSize: 72.0 + Float32(iteration))
            renderer.endScene()
            let stats = renderer.fontCacheStats()
            @Expect(stats.glyphAtlasBytes <= Int64(16 * 1024 * 1024))
            @Expect(stats.fontConfigurations <= Int64(24))
            if (iteration % 16 == 0) { gc(heavy: true) }
        }
        @Expect(renderer.fontCacheStats().glyphAtlasEvictions > UInt64(0))
        captureBudgetText(renderer, after)
        let left = File.readFrom(before); let right = File.readFrom(after)
        @Expect(left.size, right.size)
        var changed: Int64 = 0
        for (i in 0..min(left.size, right.size)) { if (left[i] != right[i]) { changed += 1 } }
        @Expect(changed, Int64(0))
    } finally {
        window.close()
        if (exists(before)) { remove(before) }; if (exists(after)) { remove(after) }; remove(directory)
    }
}

private func captureBudgetText(renderer: Renderer, path: String): Unit {
    renderer.beginScene(400.0, 120.0, Color.rgb(255, 255, 255))
    renderer.setScale(1.0)
    renderer.text("AV office ffi 仓颉", 12.25, 24.5, Color.rgb(24, 65, 130).withAlpha(170), pointSize: 24.0)
    renderer.captureBmp(path)
    renderer.endScene()
}
