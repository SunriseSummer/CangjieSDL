package sdl

import std.collection.HashMap
import sdl.text.NativeTextMetrics

// Per-point-size capacity for the text-metrics cache before a generation is retired. A handful of
// sizes each hold up to this many distinct strings — ample for a dense UI while staying bounded
// against pathological churn (for example a log of unique lines every frame).
internal let TEXT_METRICS_CAP_PER_SIZE: Int64 = 1024
private let METRICS_GENERATION_BYTES: Int64 = 64 * 1024
private let METRICS_ENTRY_OVERHEAD: Int64 = 80
private let METRICS_SIZE_CAP: Int64 = 32

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
    private var activeBytes: Int64 = 0
    var lastUse: UInt64 = UInt64(0)

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
        let weight = text.size + METRICS_ENTRY_OVERHEAD
        if (weight > METRICS_GENERATION_BYTES) {
            return
        }
        if (active.size >= capacity || activeBytes + weight > METRICS_GENERATION_BYTES) {
            let recycled = retired
            recycled.clear()
            retired = active
            active = recycled
            activeBytes = 0
        }
        if (!active.contains(text)) {
            activeBytes += weight
        }
        active[text] = value
    }
}

internal class TextMetricsCache {
    private let capacityPerSize: Int64
    private var bySize = HashMap<Int64, MetricsGeneration>()
    private var clock: UInt64 = UInt64(0)
    internal var lastUse: UInt64 = UInt64(0)

    init(capacityPerSize: Int64) {
        this.capacityPerSize = capacityPerSize
    }

    func get(sizeKey: Int64, text: String): ?NativeTextMetrics {
        clock += 1
        match (bySize.get(sizeKey)) {
            case Some(generation) =>
                generation.lastUse = clock
                generation.get(text)
            case None => None
        }
    }

    func put(sizeKey: Int64, text: String, value: NativeTextMetrics): Unit {
        clock += 1
        let generation = match (bySize.get(sizeKey)) {
            case Some(existing) => existing
            case None =>
                trimSizes()
                let created = MetricsGeneration(capacityPerSize)
                bySize[sizeKey] = created
                created
        }
        generation.lastUse = clock
        generation.put(text, value)
    }

    private func trimSizes(): Unit {
        if (bySize.size < METRICS_SIZE_CAP) {
            return
        }
        var oldest: UInt64 = UInt64.Max
        var victim: Int64 = 0
        for ((key, generation) in bySize) {
            if (generation.lastUse < oldest) {
                oldest = generation.lastUse
                victim = key
            }
        }
        bySize.remove(victim)
    }

    func clear(): Unit {
        bySize.clear()
    }
}
