package sdl.text

import std.collection.{ArrayList, HashMap}

internal struct EngineDraw {
    let font: CPointer<Unit>
    let glyph: UInt32
    let source: TtfSubstringRect
    let rectangle: TtfSubstringRect
    let line: Int64
    init(font: CPointer<Unit>, glyph: UInt32, source: TtfSubstringRect, rectangle: TtfSubstringRect, line: Int64) {
        this.font = font
        this.glyph = glyph
        this.source = source
        this.rectangle = rectangle
        this.line = line
    }
}

// SDL owns shaping, ligatures, bidi and clusters. This immutable copy aligns fallback baselines
// and provides one layout to drawing, ink bounds, surfaces and editor hit testing.
internal class EngineLayout {
    let draws: Array<EngineDraw>
    let clusters: Array<TtfSubstring>
    let metrics: NativeTextMetrics
    let runs: Array<EngineTextRun>
    init(draws: Array<EngineDraw>, clusters: Array<TtfSubstring>, metrics: NativeTextMetrics,
        runs!: Array<EngineTextRun> = []) {
        this.draws = draws
        this.clusters = clusters
        this.metrics = metrics
        this.runs = runs
    }
    init(text: CPointer<EngineText>, sources: HashMap<UIntNative, GlyphRasterSource>) {
        this.runs = []
        let header = unsafe { text.read() }
        let data = unsafe { header.data.read() }
        if (data.operationCount < 0 || data.operationCount > 1048576 || data.clusterCount < 0 || data.clusterCount >
            1048576 || header.lines < 0 || header.lines > 1048576 || (data.operationCount > 0 && data
            .operations
            .isNull()) || (data.clusterCount > 0 && data.clusters.isNull())) {
            throw NativeTextException("Invalid text engine layout")
        }
        let clusterPointer = data.clusters
        let clusters = Array<TtfSubstring>(Int64(data.clusterCount)) {i => unsafe { clusterPointer.read(i) }}
        let lineCount = max(1, Int64(header.lines))
        let lineSkip = Int64(unsafe { TTF_GetFontLineSkip(data.font) })
        let height = Int64(unsafe { TTF_GetFontHeight(data.font) })
        let ascent = unsafe { TTF_GetFontAscent(data.font) }
        let direction = unsafe { TTF_GetTextDirection(CPointer<Unit>(text)) }
        let horizontal = direction != 6 && direction != 7
        let oldOrigins = Array<Int64>(lineCount, repeat: 0)
        for (cluster in clusters) {
            let line = Int64(cluster.lineIndex)
            if (line < 0 || line >= lineCount) {
                continue
            }
            oldOrigins[line] = max(oldOrigins[line], Int64(cluster.rect.y) - line * lineSkip - Int64(data.y))
        }
        let textY = Int64(data.y)
        let lineCenters = Array<Int64>(lineCount) {i => (i * lineSkip + oldOrigins[i] + textY) * 2 + height}
        let glyphLines = HashMap<Int32, Int64>()
        let lineLookup: ?EngineLineLookup = if (lineCount > 1) {
            Some(EngineLineLookup(lineCenters))
        } else {
            None
        }
        if (lineCount > 1) {
            for (cluster in clusters) {
                if (cluster.lineIndex >= 0 && Int64(cluster.lineIndex) < lineCount) {
                    glyphLines[cluster.offset] = max(glyphLines.get(cluster.offset).getOrDefault({=> Int64(0)}),
                        Int64(cluster.lineIndex))
                }
            }
        }
        let prepared = ArrayList<EngineDraw>()
        let minimums = Array<Int64>(lineCount, repeat: 0)
        let ascents = HashMap<UIntNative, Int32>()
        let samplePointer = header.text
        var sampleText: ?GlyphSampleClusters = None
        for (i in 0..Int64(data.operationCount)) {
            let pointer = unsafe { data.operations + i }
            let operation = unsafe { pointer.read() }
            var rectangle = operation.destination
            var source = operation.source
            var font = operation.font
            if (operation.command == 1) {
                rectangle = unsafe { CPointer<EngineFill>(pointer).read().rectangle }
                source = TtfSubstringRect()
                font = CPointer<Unit>()
            } else if (operation.command != 2) {
                continue
            }
            if (let Some(raster) <- sources.get(font.toUIntNative())) {
                if (raster.needsSample(operation.glyph)) {
                    let samples = sampleText.getOrDefault({=> GlyphSampleClusters(samplePointer, clusters)})
                    sampleText = Some(samples)
                    samples.remember(raster, operation)
                }
            }
            var line: Int64 = 0
            if (let Some(lookup) <- lineLookup) {
                // Public copy offsets identify the shaped cluster's exact line, even for tall marks.
                let exact: ?Int64 = if (font.isNotNull()) {
                    glyphLines.get(operation.textOffset)
                } else {
                    None
                }
                line = match (exact) {
                    case Some(index) => index
                    case None => lookup.closest(Int64(rectangle.y) * 2 + Int64(rectangle.h))
                }
            }
            var delta: Int64 = 0
            if (horizontal && font.isNotNull()) {
                let key = font.toUIntNative()
                let glyphFont = font
                let glyphAscent = ascents.get(key).getOrDefault({=> unsafe { TTF_GetFontAscent(glyphFont) }})
                ascents[key] = glyphAscent
                delta = Int64(ascent) - Int64(glyphAscent)
            }
            if (horizontal) {
                rectangle.y = Int32(Int64(rectangle.y) + delta - oldOrigins[line])
                minimums[line] = min(minimums[line], Int64(rectangle.y) - line * lineSkip - Int64(data.y))
            }
            prepared.add(EngineDraw(font, operation.glyph, source, rectangle, line))
        }
        let result = Array<EngineDraw>(prepared.size) {
            i =>
                let draw = prepared[i]
                var rectangle = draw.rectangle
                if (horizontal) {
                    rectangle.y = Int32(Int64(rectangle.y) - minimums[draw.line])
                }
                EngineDraw(draw.font, draw.glyph, draw.source, rectangle, draw.line)
        }
        var rasterHeight = if (horizontal) {
            height + (lineCount - 1) * lineSkip + Int64(data.y)
        } else {
            Int64(data.height)
        }
        for (line in 0..lineCount) {
            if (horizontal) {
                rasterHeight = max(rasterHeight, line * lineSkip + height - minimums[line] + Int64(data.y))
            }
        }
        var left = Int64.Max;
        var top = Int64.Max;
        var right: Int64 = 0;
        var bottom: Int64 = 0
        for (draw in result) {
            let rect = draw.rectangle
            if (rect.w <= 0 || rect.h <= 0) {
                continue
            }
            left = min(left, Int64(rect.x))
            top = min(top, Int64(rect.y))
            right = max(right, Int64(rect.x) + Int64(rect.w))
            bottom = max(bottom, Int64(rect.y) + Int64(rect.h))
        }
        rasterHeight = max(rasterHeight, bottom)
        for (i in 0..clusters.size) {
            let line = Int64(clusters[i].lineIndex)
            if (horizontal && line >= 0 && line < lineCount) {
                var cluster = clusters[i]
                cluster.rect.y = Int32(Int64(cluster.rect.y) - oldOrigins[line] - minimums[line])
                clusters[i] = cluster
            }
        }
        this.draws = result
        this.clusters = clusters
        this.metrics = if (left == Int64.Max) {
            NativeTextMetrics(Float32(data.width), Float32(rasterHeight), inkWidth: 0.0, inkHeight: 0.0)
        } else {
            NativeTextMetrics(Float32(data.width), Float32(rasterHeight), inkX: Float32(left), inkY: Float32(top),
                inkWidth: Float32(right - left), inkHeight: Float32(bottom - top))
        }
    }

    // A shaped range may reserve space above its font box for tall glyphs. When embedding
    // it in another line, align this box plus the font ascent, not just the surface top.
    // Runs are split at hard line boundaries before composition; no additional map is needed.
    func firstLineOrigin(): Int32 {
        for (cluster in clusters) {
            if (cluster.lineIndex == 0) {
                return cluster.rect.y
            }
        }
        0
    }

    func substringAt(x: Int32, y: Int32): TtfSubstring {
        var selected = TtfSubstring()
        var distanceY = Int64.Max
        var distanceX = Int64.Max
        // Same line-first nearest-cluster policy as SDL, using the corrected line rectangles.
        for (cluster in clusters) {
            let rect = cluster.rect
            let dx = max(Int64(rect.x) - Int64(x), max(Int64(0), Int64(x) - Int64(rect.x) - Int64(rect.w)))
            let dy = max(Int64(rect.y) - Int64(y), max(Int64(0), Int64(y) - Int64(rect.y) - Int64(rect.h)))
            if (dy < distanceY || (dy == distanceY && dx < distanceX)) {
                selected = cluster
                distanceY = dy
                distanceX = dx
            }
        }
        selected
    }
}
