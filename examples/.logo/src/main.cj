package cangjie

import std.collection.ArrayList
import sdl.{Color, Point, Rect, Renderer, SdlWindow, UiEvent, WindowSpec}

func fillLogoPolygon(
    renderer: Renderer,
    vertices: Array<Point>,
    color: Color,
    originX: Float32,
    originY: Float32,
    scale: Float32
): Unit {
    let points = ArrayList<Point>()
    for (vertex in vertices) {
        points.add(Point(originX + vertex.x * scale, originY + vertex.y * scale))
    }
    renderer.fillConvexPolygon(points, color)
}

func drawCangjieLogo(renderer: Renderer): Unit {
    let blue = Color.rgb(45, 119, 238)  // #2D77EE
    let green = Color.rgb(46, 232, 159) // #2EE89F
    let originX: Float32 = 228.4
    let originY: Float32 = 52.0
    let scale: Float32 = 0.52

    fillLogoPolygon(renderer,
        [Point(148.0, 17.9), Point(454.0, 55.0), Point(454.0, 68.0),
         Point(270.0, 126.0), Point(148.0, 112.6)],
        blue, originX, originY, scale)
    fillLogoPolygon(renderer,
        [Point(148.0, 598.4), Point(270.0, 585.0), Point(454.0, 644.0),
         Point(454.0, 657.0), Point(148.0, 693.4)],
        blue, originX, originY, scale)
    fillLogoPolygon(renderer,
        [Point(0.0, 0.0), Point(152.0, 18.4), Point(152.0, 692.3),
         Point(0.0, 711.0)],
        blue, originX, originY, scale)

    fillLogoPolygon(renderer,
        [Point(417.0, 135.0), Point(517.0, 103.2), Point(517.0, 155.4),
         Point(417.0, 146.0)],
        green, originX, originY, scale)
    fillLogoPolygon(renderer,
        [Point(417.0, 566.0), Point(517.0, 553.5), Point(517.0, 609.7),
         Point(417.0, 579.0)],
        green, originX, originY, scale)
    fillLogoPolygon(renderer,
        [Point(513.0, 104.5), Point(609.0, 74.0), Point(660.0, 80.0),
         Point(660.0, 631.0), Point(609.0, 638.0), Point(513.0, 608.5)],
        green, originX, originY, scale)
}

main() {
    try (window = SdlWindow(WindowSpec("CangjieSDL", 800, 600))) {
        var running = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case _ => ()
                }
            }

            let renderer = window.renderer
            renderer.beginScene(800.0, 600.0, Color.rgb(15, 23, 42))
            drawCangjieLogo(renderer)
            renderer.textCenter(
                "CangjieSDL",
                Rect(0.0, 458.0, 800.0, 64.0),
                Color.rgb(241, 245, 249),
                pointSize: 40.0
            )
            renderer.endScene()
            renderer.present()
            window.delay(16)
        }
    }
}