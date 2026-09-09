package sdl.text

import std.collection.{ArrayList, HashMap}
import std.sort.sort

internal class EmojiTextRun {
    let start: Int64
    var end: Int64
    let font: CPointer<Unit>
    let line: Int32
    var endsLine: Bool
    var order: Int32 = Int32.Max
    init(start: Int64, end: Int64, font: CPointer<Unit>, line: Int32, endsLine!: Bool = false) {
        this.start = start
        this.end = end
        this.font = font
        this.line = line
        this.endsLine = endsLine
    }
}

// Borrowed font handles have the same lifetime as the parent layout's leased font group.
internal class EngineTextRun {
    let start: Int64
    let length: Int64
    let font: CPointer<Unit>
    let width: Int32
    let line: Int32
    init(run: EmojiTextRun, width: Int32) {
        start = run.start
        length = run.end - run.start
        font = run.font
        line = run.line
        this.width = width
    }
}

// Adjacent text using the same face stays together: rounding the width of each emoji separately
// would accumulate errors in fractional advances. Native visual run order is retained.
internal func mergeEmojiLayout(value: String, base: EngineLayout, replacements: Array<EmojiReplacement>,
    primary: CPointer<Unit>, state: CangjieTextEngine): EngineLayout {
    let runs = emojiTextRuns(value, replacements, primary)
    var probe: Int64 = 0
    for (cluster in base.clusters) {
        if (cluster.length <= 0) {
            continue
        }
        while (probe < runs.size && runs[probe].end <= Int64(cluster.offset)) {
            probe += 1
        }
        if (probe < runs.size && runs[probe].start <= Int64(cluster.offset)) {
            runs[probe].order = min(runs[probe].order, cluster.rect.x)
        }
    }
    sort(runs, lessThan: {a, b => a.line < b.line || (a.line == b.line && a.order < b.order)})
    let builder = EmojiLayoutBuilder(primary, base)
    for (run in runs) {
        builder.append(run, rawEmojiRunLayout(run.font, value[run.start..run.end], state))
    }
    builder.finish()
}

private func emojiTextRuns(value: String, replacements: Array<EmojiReplacement>, primary: CPointer<Unit>): Array<EmojiTextRun> {
    let runs = ArrayList<EmojiTextRun>()
    var offset: Int64 = 0;
    var replacement: Int64 = 0;
    var line: Int32 = 0
    while (offset < value.size) {
        var end = if (replacement < replacements.size) {
            Int64(replacements[replacement].start)
        } else {
            value.size
        }
        var font = primary
        if (end == offset) {
            font = replacements[replacement].shape.font
            end = Int64(replacements[replacement].end)
            replacement += 1
        }
        var piece = offset
        for (i in offset..end) {
            if (value[i] == 10) {
                appendEmojiTextRun(runs, piece, i + 1, font, line, endsLine: true)
                line += 1
                piece = i + 1
            }
        }
        if (piece < end) {
            appendEmojiTextRun(runs, piece, end, font, line)
        }
        offset = end
    }
    runs.toArray()
}

private func appendEmojiTextRun(runs: ArrayList<EmojiTextRun>, start: Int64, end: Int64, font: CPointer<Unit>,
    line: Int32, endsLine!: Bool = false): Unit {
    if (!runs.isEmpty()) {
        let previous = runs[runs.size - 1]
        if (previous.end == start && previous.line == line && previous.font.toUIntNative() == font.toUIntNative()) {
            previous.end = end
            previous.endsLine = endsLine
            return
        }
    }
    runs.add(EmojiTextRun(start, end, font, line, endsLine: endsLine))
}

internal func rawEmojiRunLayout(font: CPointer<Unit>, sample: String, state: CangjieTextEngine): EngineLayout {
    let encoded = unsafe { LibC.mallocCString(sample) }
    try (resource = encoded.asResource()) {
        let pointer = unsafe { TTF_CreateText(CPointer<Unit>(), font, resource.value, UIntNative(sample.size)) }
        if (pointer.isNull()) {
            throw NativeTextException("Cannot create font run: ${lastNativeError()}")
        }
        try {
            if (!unsafe { TTF_UpdateText(pointer) }) {
                throw NativeTextException("Cannot shape font run: ${lastNativeError()}")
            }
            return EngineLayout(CPointer<EngineText>(pointer), state.sources)
        } finally {
            unsafe { TTF_DestroyText(pointer) }
        }
    }
    throw IllegalStateException("Font run was not produced")
}

private class EmojiLayoutBuilder {
    private let draws = ArrayList<EngineDraw>()
    private let clusters = ArrayList<TtfSubstring>()
    private let origins = HashMap<Int32, Int32>()
    private let runs = ArrayList<EngineTextRun>()
    private let ascent: Int32
    private let height: Int32
    private let lineSkip: Int32
    private let base: EngineLayout
    private let primary: CPointer<Unit>
    private let direction: UInt32
    private var lineCount: Int32 = 1
    init(primary: CPointer<Unit>, base: EngineLayout) {
        this.primary = primary
        this.base = base
        this.direction = emojiRunDirection(base)
        ascent = unsafe { TTF_GetFontAscent(primary) }
        height = unsafe { TTF_GetFontHeight(primary) }
        lineSkip = unsafe { TTF_GetFontLineSkip(primary) }
    }
    func append(run: EmojiTextRun, layout: EngineLayout): Unit {
        let x = origins.get(run.line).getOrDefault({=> Int32(0)})
        let y = run.line * lineSkip + ascent - unsafe { TTF_GetFontAscent(run.font) } - layout.firstLineOrigin()
        for (draw in layout.draws) {
            if (draw.font.isNull()) {
                continue
            }
            var rect = draw.rectangle;
            rect.x += x
            rect.y += y
            draws.add(EngineDraw(draw.font, draw.glyph, draw.source, rect, draw.line + Int64(run.line)))
        }
        for (item in layout.clusters) {
            if (item.length <= 0) {
                continue
            }
            var cluster = item
            if (run.font.toUIntNative() != primary.toUIntNative()) {
                cluster.flags = (cluster.flags & UInt32(0xFFFFFF00)) | direction
            }
            cluster.offset += Int32(run.start)
            cluster.lineIndex += run.line
            cluster.rect.x += x
            cluster.rect.y = cluster.lineIndex * lineSkip
            cluster.rect.h = height
            clusters.add(cluster)
            lineCount = max(lineCount, cluster.lineIndex + 1)
        }
        origins[run.line] = x + Int32(layout.metrics.width)
        runs.add(EngineTextRun(run, Int32(layout.metrics.width)))
        lineCount = max(lineCount, run.line + if (run.endsLine) {
            Int32(2)
        } else {
            Int32(1)
        })
    }
    func finish(): EngineLayout {
        for (draw in base.draws) {
            if (draw.font.isNotNull()) {
                continue
            }
            var rect = draw.rectangle
            rect.w = max(0, origins.get(Int32(draw.line)).getOrDefault({=> Int32(0)}) - rect.x)
            draws.add(EngineDraw(draw.font, draw.glyph, draw.source, rect, draw.line))
        }
        var width: Int32 = 0;
        var bottom = height + (lineCount - 1) * lineSkip
        var left = Int32.Max;
        var top = Int32.Max;
        var right: Int32 = 0;
        var inkBottom: Int32 = 0
        for ((_, end) in origins) {
            width = max(width, end)
        }
        for (draw in draws) {
            let rect = draw.rectangle
            if (rect.w <= 0 || rect.h <= 0) {
                continue
            }
            left = min(left, rect.x)
            top = min(top, rect.y)
            right = max(right, rect.x + rect.w)
            inkBottom = max(inkBottom, rect.y + rect.h)
        }
        bottom = max(bottom, inkBottom)
        let ordered = clusters.toArray()
        sort(ordered, lessThan: {a, b => a.offset < b.offset})
        let metrics = if (left == Int32.Max) {
            NativeTextMetrics(Float32(width), Float32(bottom), inkWidth: 0.0, inkHeight: 0.0)
        } else {
            NativeTextMetrics(Float32(max(width, right)), Float32(bottom), inkX: Float32(left), inkY: Float32(top),
                inkWidth: Float32(right - left), inkHeight: Float32(inkBottom - top))
        }
        let orderedRuns = runs.toArray()
        sort(orderedRuns, lessThan: {a, b => a.start < b.start})
        EngineLayout(draws.toArray(), ordered, metrics, runs: orderedRuns)
    }
}

private func emojiRunDirection(base: EngineLayout): UInt32 {
    var previous: ?TtfSubstring = None
    for (cluster in base.clusters) {
        if (cluster.length <= 0 || cluster.rect.w <= 0) {
            continue
        }
        if (let Some(before) <- previous && before.lineIndex == cluster.lineIndex && before.rect.x != cluster.rect.x) {
            return if (before.rect.x > cluster.rect.x) {
                UInt32(5)
            } else {
                UInt32(4)
            }
        }
        previous = Some(cluster)
    }
    UInt32(4)
}
