package sdl

import std.fs.{Directory, remove}

private func capturePrecisionShape(path: String, kind: Int64, warm!: Bool): Unit {
    try (window = SdlWindow(WindowSpec("Mesh precision", 160, 120, supersample: 2), hidden: true)) {
        let renderer = window.renderer
        if (warm) {
            renderer.beginScene(160.0, 120.0, Color.rgb(255, 255, 255))
            precisionShape(renderer, 0.24, kind)
            renderer.endScene()
        }
        renderer.beginScene(160.0, 120.0, Color.rgb(255, 255, 255))
        precisionShape(renderer, 0.01, kind)
        renderer.captureBmp(path)
        renderer.endScene()
    }
}

private func precisionShape(renderer: Renderer, fraction: Float32, kind: Int64): Unit {
    let rect = Rect(20.0, 20.0, 90.0 + fraction, 60.0 + fraction)
    let color = Color.rgb(20, 40, 70)
    match (kind) {
        case 0 => renderer.fillRoundedRect(rect, 12.0 + fraction, color)
        case 1 => renderer.strokeRoundedRect(rect, 12.0 + fraction, Pen(width: 1.0 + fraction, color: color))
        case 2 => renderer.fillCircle(60.0, 55.0, 24.0 + fraction, color)
        case _ => renderer.strokeCircle(60.0, 55.0, 24.0 + fraction, Pen(width: 1.0 + fraction, color: color))
    }
}

@Test
func fractionalMeshOutputDoesNotDependOnPreviouslyDrawnSizes(): Unit {
    let directory = Directory.createTemp(".").toString()
    let warm = directory + "/warm.bmp"
    let cold = directory + "/cold.bmp"
    try {
        for (kind in 0..4) {
            capturePrecisionShape(warm, kind, warm: true)
            capturePrecisionShape(cold, kind, warm: false)
            @Expect(qualityPixelDifferences(warm, cold), Int64(0))
        }
    } finally {
        remove(warm)
        remove(cold)
        remove(directory)
    }
}
