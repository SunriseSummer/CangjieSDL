package sdl

import std.fs.{Directory, File, remove}

@Test
func containedClipKeepsExactFractionalEdgesForTextPasses(): Unit {
    let viewport = Rect(16.0, 16.0, 388.0, 68.0)
    let height: Float32 = 38.222222
    let selected = Rect(16.0, 50.0 - height / 2.0, 180.0, height)
    let nested = viewport.intersection(selected)
    @Expect(nested.y.toBits(), selected.y.toBits())
    @Expect(nested.h.toBits(), selected.h.toBits())
    let a = enclosingSdlClipRect(Rect(nested.x * 4.5, nested.y * 4.5, nested.w * 4.5, nested.h * 4.5))
    let b = enclosingSdlClipRect(Rect(selected.x * 4.5, selected.y * 4.5, selected.w * 4.5, selected.h * 4.5))
    @Expect(a.y + a.h, b.y + b.h)
    @Expect(selected.intersection(viewport).h.toBits(), selected.h.toBits())
    @Expect(viewport.intersection(Rect(20.0, 20.0, -1.0, 8.0)).w, 0.0)
}

@Test
func fractionalClipPreservesContentAtTheBottomAndRightEdges(): Unit {
    let directory = Directory.createTemp(".").toString()
    let clipped = directory + "/clipped.bmp"
    let reference = directory + "/reference.bmp"
    try {
        for (sampling in [Int32(1), Int32(2)]) {
            try (window = SdlWindow(WindowSpec("Fractional clip", 200, 130, supersample: sampling), hidden: true)) {
                let renderer = window.renderer
                let scales: Array<Float32> = [1.0, 1.25, 1.5, 2.0]
                for (scale in scales) {
                    for (withClip in [true, false]) {
                        renderer.beginScene(200.0, 130.0, Color.rgb(255, 255, 255))
                        renderer.setScale(scale)
                        if (withClip) { renderer.pushClip(Rect(10.75, 10.75, 60.75, 40.75)) }
                        // Both bars lie wholly within the logical clip, including its fractional edge.
                        renderer.fill(Rect(20.0, 50.5, 40.0, 0.75), Color.rgb(0, 0, 0))
                        renderer.fill(Rect(70.5, 20.0, 0.75, 20.0), Color.rgb(0, 0, 0))
                        renderer.captureBmp(if (withClip) { clipped } else { reference })
                        if (withClip) { renderer.popClip() }
                        renderer.endScene()
                    }
                    @Expect(qualityPixelDifferences(clipped, reference), Int64(0))
                }
            }
        }
    } finally {
        remove(clipped)
        remove(reference)
        remove(directory)
    }
}

func qualityPixelDifferences(left: String, right: String): Int64 {
    let a = File.readFrom(left)
    let b = File.readFrom(right)
    if (a.size != b.size) { return -1 }
    var differences: Int64 = 0
    for (i in 0..a.size) {
        if (a[i] != b[i]) { differences += 1 }
    }
    differences
}

@Test
func fractionalNativeClipEnclosesEdgesWithoutRevivingEmptyIntersections(): Unit {
    try (window = SdlWindow(WindowSpec("Clip bounds", 120, 80), hidden: true)) {
        let renderer = window.renderer
        renderer.pushClip(Rect(-0.75, 10.75, 60.5, 40.75))
        let clip = renderer.clipRect()
        @Expect(clip.x, Float32(-1.0))
        @Expect(clip.y, Float32(10.0))
        @Expect(clip.right(), Float32(60.0))
        @Expect(clip.bottom(), Float32(52.0))
        renderer.pushClip(Rect(90.5, 11.0, 2.0, 2.0))
        @Expect(renderer.clipRect().w, Float32(0.0))
        renderer.popClip()
        renderer.popClip()
    }
}

@Test
func rejectedNativeClipDoesNotCorruptTheLogicalClipStack(): Unit {
    try (window = SdlWindow(WindowSpec("Clip rollback", 120, 80), hidden: true)) {
        let renderer = window.renderer
        renderer.pushClip(Rect(4.0, 6.0, 30.0, 20.0))
        var rejected = false
        try { renderer.pushClip(Rect(1.0e30, 0.0, 1.0, 1.0)) }
        catch (_: IllegalArgumentException) { rejected = true }
        @Expect(rejected)
        @Expect(renderer.currentClip().getOrThrow().x, Float32(4.0))
        @Expect(renderer.clipRect().x, Float32(4.0))
        renderer.popClip()
        @Expect(renderer.currentClip().isNone())
    }
}
