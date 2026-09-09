package sdl.text

import std.collection.ArrayList
import std.sort.sort

// Decorations have no text offset. Index their nearest line center once, including unusual
// non-monotonic centers from very tall combining marks, instead of scanning every line per glyph.
internal class EngineLineLookup {
    private let centers: Array<Int64>
    private let lines: Array<Int64>
    init(values: Array<Int64>) {
        let order = Array<Int64>(values.size) {i => i}
        sort<Int64, Int64>(order, key: {i => values[i]})
        let centers = ArrayList<Int64>();
        let lines = ArrayList<Int64>()
        for (i in order) {
            if (!centers.isEmpty() && centers[centers.size - 1] == values[i]) {
                lines[lines.size - 1] = min(lines[lines.size - 1], i)
            } else {
                centers.add(values[i]);
                lines.add(i)
            }
        }
        this.centers = centers.toArray()
        this.lines = lines.toArray()
    }

    func closest(value: Int64): Int64 {
        if (centers.isEmpty()) {
            return 0
        }
        var low: Int64 = 0;
        var high = centers.size
        while (low < high) {
            let middle = low + (high - low) / 2
            if (centers[middle] < value) {
                low = middle + 1
            } else {
                high = middle
            }
        }
        if (low == 0) {
            return lines[0]
        }
        if (low == centers.size) {
            return lines[low - 1]
        }
        let before = value - centers[low - 1];
        let after = centers[low] - value
        if (before == after) {
            min(lines[low - 1], lines[low])
        } else if (before < after) {
            lines[low - 1]
        } else {
            lines[low]
        }
    }
}
