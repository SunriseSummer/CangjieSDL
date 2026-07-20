package sdl

import std.collection.HashMap
import sdl.text.NativeTextMetrics

// Per-point-size capacity for the text-metrics cache before a generation is retired. A handful of
// sizes each hold up to this many distinct strings — ample for a dense UI while staying bounded
// against pathological churn (for example a log of unique lines every frame).
internal let TEXT_METRICS_CAP_PER_SIZE: Int64 = 1024

/*
 * A per-point-size text-measurement cache. The UI tree is rebuilt every frame, so the same string
 * is measured over and over; caching (point size, text) -> metrics across frames turns those
 * repeats into a hash lookup instead of an SDL_ttf shaping call. Keyed size-first so the string is
 * used directly as the inner key with no per-lookup allocation — an earlier `"${size}#${text}"` key
 * was measured too costly (its float-to-string build dominated) and reverted. Bounded by a
 * two-generation eviction per size: when the active generation fills it is retired and a cleared one
 * takes over; a hit in the retired generation is promoted back, so hot strings survive a rotation.
 */
private class MetricsGeneration {
    private let capacity: Int64
    private var active = HashMap<String, NativeTextMetrics>()
    private var retired = HashMap<String, NativeTextMetrics>()

    init(capacity: Int64) {
        this.capacity = if (capacity < 1) {
            1
        } else {
            capacity
        }
    }

    func get(text: String): ?NativeTextMetrics {
        match (active.get(text)) {
            case Some(value) => return Some(value)
            case None => ()
        }
        match (retired.get(text)) {
            case Some(value) =>
                put(text, value)
                Some(value)
            case None => None
        }
    }

    func put(text: String, value: NativeTextMetrics): Unit {
        if (active.size >= capacity) {
            let recycled = retired
            recycled.clear()
            retired = active
            active = recycled
        }
        active[text] = value
    }
}

internal class TextMetricsCache {
    private let capacityPerSize: Int64
    private var bySize = HashMap<Int64, MetricsGeneration>()

    init(capacityPerSize: Int64) {
        this.capacityPerSize = capacityPerSize
    }

    func get(sizeKey: Int64, text: String): ?NativeTextMetrics {
        match (bySize.get(sizeKey)) {
            case Some(generation) => generation.get(text)
            case None => None
        }
    }

    func put(sizeKey: Int64, text: String, value: NativeTextMetrics): Unit {
        let generation = match (bySize.get(sizeKey)) {
            case Some(existing) => existing
            case None =>
                let created = MetricsGeneration(capacityPerSize)
                bySize[sizeKey] = created
                created
        }
        generation.put(text, value)
    }
}
