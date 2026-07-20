package sdl

import std.collection.ArrayList

@Test
func fillConvexPolygonToleratesHeadlessAndDegenerateInput(): Unit {
    let renderer = Renderer.headless()

    let triangle = ArrayList<Point>([Point(0.0, 0.0), Point(24.0, 0.0), Point(12.0, 18.0)])
    renderer.fillConvexPolygon(triangle, Color.rgb(200, 60, 60))

    // A caller-closed ring (last point repeats the first) must not produce a zero-length edge.
    let closed = ArrayList<Point>([Point(0.0, 0.0), Point(24.0, 0.0), Point(12.0, 18.0), Point(0.0, 0.0)])
    renderer.fillConvexPolygon(closed, Color.rgba(20, 20, 20, 128))

    // Below three distinct points there is no area to fill.
    renderer.fillConvexPolygon(ArrayList<Point>([Point(1.0, 1.0), Point(2.0, 2.0)]), Color.rgb(0, 0, 0))
    renderer.fillConvexPolygon(ArrayList<Point>(), Color.rgb(0, 0, 0))

    @Expect(renderer.driverName(), "headless")
}

@Test
func textRotatedIsANoOpHeadlessAndOnEmptyText(): Unit {
    let renderer = Renderer.headless()

    renderer.textRotated("axis title", 120.0, 80.0, -90.0, Color.rgb(30, 30, 30))
    renderer.textRotated("", 0.0, 0.0, 45.0, Color.rgb(30, 30, 30), pointSize: 18.0)
    renderer.textRotated("styled", 10.0, 10.0, 90.0, Color.rgb(0, 0, 0), style: FontStyle.regular.withBold())

    @Expect(renderer.driverName(), "headless")
}
