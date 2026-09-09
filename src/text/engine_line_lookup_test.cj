package sdl.text

import std.math.abs

@Test
func indexedDecorationLinesMatchNearestCenterIncludingDuplicateAndReorderedLines(): Unit {
    for (centers in [[Int64(20)], [Int64(30), 10, 30, 60], Array<Int64>(10000) {i => i * 20}]) {
        let lookup = EngineLineLookup(centers)
        for (point in [Int64(-10), 10, 20, 30, 40, 45, 70, 199999]) {
            var expected: Int64 = 0; var distance = Int64.Max
            for (i in 0..centers.size) {
                let delta = abs(centers[i] - point)
                if (delta < distance) { distance = delta; expected = i }
            }
            @Expect(lookup.closest(point), expected)
        }
    }
}
