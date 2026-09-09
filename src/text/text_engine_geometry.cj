package sdl.text

import std.collection.ArrayList

internal class EngineGeometry {
    private let layout: EngineLayout
    private var cache: Array<GlyphBatch> = []
    private var ready = false
    init(layout: EngineLayout) {
        this.layout = layout
    }

    func draw(renderer: CPointer<Unit>, atlas: GlyphAtlas, x: Float32, y: Float32, color: NativeTextColor): Unit {
        var valid = ready
        for (batch in cache) {
            valid = valid && batch.page.valid
        }
        if (valid) {
            for (batch in cache) {
                batch.draw(renderer, atlas, x, y, color)
            };
            return
        }
        close()
        let builders = ArrayList<GlyphBatchBuilder>()
        var streamed = false
        var chunk: Int64 = 0
        try {
            for (draw in layout.draws) {
                if (draw.rectangle.w <= 0 || draw.rectangle.h <= 0) {
                    continue
                }
                var found: ?AtlasGlyph = None
                try {
                    found = Some(atlas.get(draw))
                } catch (_: GlyphAtlasBusy) {
                    flush(renderer, atlas, builders, x, y, color, remember: false)
                    streamed = true
                    chunk = 0
                    found = Some(atlas.get(draw))
                }
                // Invariant: the initial allocation or retry assigned Some, or propagated an error.
                let glyph = found.getOrThrow()
                if (builders.isEmpty() || builders[builders.size - 1].page.identity != glyph.page.identity ||
                    builders[builders.size - 1].color != glyph.color) {
                    builders.add(GlyphBatchBuilder(glyph))
                }
                builders[builders.size - 1].add(draw, glyph)
                chunk += 1
                // Huge runs stream bounded batches; they cannot evict textures still awaiting draw.
                if (chunk >= 256 && layout.draws.size > 256) {
                    flush(renderer, atlas, builders, x, y, color, remember: false)
                    streamed = true
                    chunk = 0
                }
            }
            flush(renderer, atlas, builders, x, y, color, remember: !streamed)
        } finally {
            unpin(builders)
        }
    }

    func close(): Unit {
        for (batch in cache) {
            batch.close()
        };
        cache = []
        ready = false
    }

    private func flush(renderer: CPointer<Unit>, atlas: GlyphAtlas, builders: ArrayList<GlyphBatchBuilder>, x: Float32,
        y: Float32, color: NativeTextColor, remember!: Bool): Unit {
        let batches = ArrayList<GlyphBatch>()
        try {
            for (builder in builders) {
                batches.add(GlyphBatch(builder))
            }
            for (batch in batches) {
                batch.draw(renderer, atlas, x, y, color)
            }
            if (remember) {
                cache = batches.toArray()
                ready = true
            }
        } finally {
            if (!ready || !remember) {
                for (batch in batches) {
                    batch.close()
                }
            }
            unpin(builders)
        }
    }

    private func unpin(builders: ArrayList<GlyphBatchBuilder>): Unit {
        for (builder in builders) {
            builder.page.pins -= 1
        }
        builders.clear()
    }
}
