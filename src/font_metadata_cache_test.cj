package sdl

import sdl.text.discoverNativeFonts
import std.fs.{Directory, File, copy, remove, exists}

@Test
func fontMetadataCacheReusesFilesAndRecoversAfterChangeOrCorruption(): Unit {
    let directory = Directory.createTemp(".").toString()
    let path = directory + "/font.ttf"
    let cache = directory + "/fonts.cache"
    copy(regressionSerif(), to: path)
    try {
        let cold = discoverNativeFonts([path], cachePath: cache)
        @Expect(cold.cacheHits, Int64(0))
        @Expect(!cold.faces.isEmpty())
        let warm = discoverNativeFonts([path], cachePath: cache)
        @Expect(warm.cacheHits, Int64(1))
        @Expect(warm.faces[0].familyName, cold.faces[0].familyName)
        @Expect(warm.faces[0].weight, cold.faces[0].weight)
        @Expect(discoverNativeFonts([path], cachePath: cache, refresh: true).cacheHits, Int64(0))
        // A size change forces metadata reinspection even on filesystems with coarse timestamps.
        let data = File.readFrom(path)
        let larger = Array<UInt8>(data.size + 4) {i => if (i < data.size) { data[i] } else { UInt8(0) }}
        File.writeTo(path, larger)
        @Expect(discoverNativeFonts([path], cachePath: cache).cacheHits, Int64(0))
        File.writeTo(cache, "corrupt cache".toArray())
        let recovered = discoverNativeFonts([path], cachePath: cache)
        @Expect(recovered.cacheHits, Int64(0))
        @Expect(recovered.faces[0].familyName, cold.faces[0].familyName)
        @Expect(discoverNativeFonts([path], cachePath: cache).cacheHits, Int64(1))
    } finally {
        if (exists(cache)) { remove(cache) }
        remove(path); remove(directory)
    }
}
