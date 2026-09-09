package sdl.text

import std.fs.exists
import std.collection.ArrayList

private func clusterPixels(image: CPointer<Unit>): Array<UInt32> {
    let surface = unsafe { CPointer<EngineSurface>(image).read() }
    var left = surface.width; var right: Int32 = 0
    var top = surface.height; var bottom: Int32 = 0
    for (y in 0..Int64(surface.height)) {
        let row = unsafe { CPointer<UInt32>(CPointer<UInt8>(surface.pixels) + y * Int64(surface.pitch)) }
        for (x in 0..Int64(surface.width)) {
            if ((unsafe { row.read(x) } >> 24) != 0) {
                left = min(left, Int32(x)); right = max(right, Int32(x) + 1)
                top = min(top, Int32(y)); bottom = max(bottom, Int32(y) + 1)
            }
        }
    }
    let pixels = ArrayList<UInt32>()
    pixels.add(UInt32(max(0, right - left))); pixels.add(UInt32(max(0, bottom - top)))
    for (y in Int64(top)..Int64(bottom)) {
        let row = unsafe { CPointer<UInt32>(CPointer<UInt8>(surface.pixels) + y * Int64(surface.pitch)) }
        for (x in Int64(left)..Int64(right)) { pixels.add(unsafe { row.read(x) }) }
    }
    pixels.toArray()
}

@Test
func emojiClusterFallbackNeverDuplicatesOnAppend(): Unit {
    let ui = NativeFontSource("C:/Windows/Fonts/msyh.ttc", 0)
    let emoji = NativeFontSource("C:/Windows/Fonts/seguiemj.ttf", 0)
    if (!exists(ui.path) || !exists(emoji.path)) { return }
    let renderer = NativeTextRenderer(CPointer<Unit>(), bootstrapSources: Some([ui]))
    try {
        let family = NativeFontFamily(ui, [], "cluster-ui")
        let direct = NativeFontFamily(emoji, [], "cluster-emoji")
        var value = ""
        for (_ in 0..4) {
            value += "👩🏽‍💻"
            let expected = renderer.measure(value, 32.0, 0, direct)
            let actual = renderer.measure(value, 32.0, 0, family)
            @Expect(actual.width, expected.width)
            try (session = renderer.measureSession(value, 32.0, 0, family)) {
                @Expect(session.measure(0, value.size), expected.width)
                let fit = session.fit(0, Int32(expected.width))
                @Expect(fit.byteLength, value.size)
            }
        }
    } finally { renderer.close() }
}

@Test
func emojiClusterPixelsMatchWholeSequencePrimaryFont(): Unit {
    let ui = NativeFontSource("C:/Windows/Fonts/msyh.ttc", 0)
    let emoji = NativeFontSource("C:/Windows/Fonts/seguiemj.ttf", 0)
    if (!exists(ui.path) || !exists(emoji.path)) { return }
    let renderer = NativeTextRenderer(CPointer<Unit>(), bootstrapSources: Some([ui]))
    try {
        let family = NativeFontFamily(ui, [], "pixels-ui")
        let direct = NativeFontFamily(emoji, [], "pixels-emoji")
        for (size in [18.0f32, 32.0f32, 48.0f32]) {
            for (sample in ["🎉", "👩🏽", "👩🏽‍💻", "👩🏽‍💻👩🏽‍💻", "👨‍👩‍👧‍👦", "🇨🇳", "1\u{FE0F}⃣", "🏳\u{FE0F}‍🌈", "👍🏿", "❤\u{FE0F}"]) {
                let expected = renderer.renderSurface(sample, size, 0, direct)
                let actual = renderer.renderSurface(sample, size, 0, family)
                try {
                    @Assert(actual.isNotNull() && expected.isNotNull())
                    let a = clusterPixels(actual); let b = clusterPixels(expected)
                    let equal = a == b
                    if (!equal) {
                        let ah = unsafe { CPointer<EngineSurface>(actual).read() }; let bh = unsafe { CPointer<EngineSurface>(expected).read() }
                        println("Emoji pixel mismatch: ${sample}, size ${size}; crop ${a[0]}x${a[1]} vs ${b[0]}x${b[1]}; surface ${ah.width}x${ah.height} vs ${bh.width}x${bh.height}")
                    }
                    @Expect(equal)
                } finally { unsafe { SDL_DestroySurface(actual); SDL_DestroySurface(expected) } }
            }
        }
    } finally { renderer.close() }
}

@Test
func emojiClusterMidpointsRangesAndWrappingStayOnWholeSequences(): Unit {
    let ui = NativeFontSource("C:/Windows/Fonts/msyh.ttc", 0)
    if (!exists(ui.path) || !exists("C:/Windows/Fonts/seguiemj.ttf")) { return }
    let renderer = NativeTextRenderer(CPointer<Unit>(), bootstrapSources: Some([ui]))
    try {
        let family = NativeFontFamily(ui, [], "cluster-hits")
        let unit = "👩🏽‍💻"
        let width = renderer.measure(unit, 32.0, 0, family).width
        for (value in [unit + unit, "A" + unit + "B", unit + " ", unit + "\n" + unit]) {
            try (session = renderer.measureSession(value, 32.0, 0, family)) {
                @Expect(session.measure(0, value.size), renderer.measure(value, 32.0, 0, family).width)
            }
        }
        try (session = renderer.measureSession(unit + unit, 32.0, 0, family)) {
            @Expect(session.fit(0, Int32(width) - 1).byteLength, 0)
            @Expect(session.fit(0, Int32(width)).byteLength, unit.size)
            @Expect(session.fit(unit.size, Int32(width)).byteLength, unit.size)
            @Expect(session.measure(unit.size, unit.size), width)
            @Expect(session.hitTest(Int32(width / 4.0), 20).byteOffset, 0)
            @Expect(session.hitTest(Int32(width * 0.75), 20).byteOffset, unit.size)
            @Expect(session.hitTest(Int32(width * 1.75), 20).byteOffset, unit.size * 2)
        }
        try (session = renderer.measureSession("A" + unit, 32.0, 0, family)) {
            let a = renderer.measure("A", 32.0, 0, family).width
            @Expect(session.fit(0, Int32(a)).byteLength, Int64(1))
        }
    } finally { renderer.close() }
}

@Test
func emojiClusterPresentationAndUnicodeBoundariesStayIndependent(): Unit {
    @Expect(graphemeByteBoundaries("👩🏽‍💻"), [Int64(0), Int64(15)])
    @Expect(graphemeByteBoundaries("👩🏽 💻"), [Int64(0), Int64(8), Int64(9), Int64(13)])
    @Expect(graphemeByteBoundaries(""), [Int64(0)])
    @Expect(emojiPresentationCluster("❤\u{FE0F}"))
    @Expect(!emojiPresentationCluster("❤\u{FE0E}"))
    @Expect(!emojiPresentationCluster("❤"))
    @Expect(emojiPresentationCluster("1\u{FE0F}⃣"))
    @Expect(!emojiPresentationCluster("A\u{FE0F}"))
    @Expect(!hasEmojiCandidates("AV office 仓颉"))
}
