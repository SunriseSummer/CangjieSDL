package sdl.text

import std.collection.ArrayList

internal class GlyphBatchBuilder {
    let page: GlyphPage
    let color: Bool
    let xy = ArrayList<Float32>()
    let uv = ArrayList<Float32>()
    init(glyph: AtlasGlyph) {
        this.page = glyph.page
        this.color = glyph.color
        page.pins += 1
    }

    func add(draw: EngineDraw, glyph: AtlasGlyph): Unit {
        let rect = draw.rectangle
        var width = rect.w;
        var height = rect.h
        let sx = max(Int32(0), draw.source.x);
        let sy = max(Int32(0), draw.source.y)
        if (draw.font.isNotNull()) {
            width = min(width, glyph.rectangle.w - sx)
            height = min(height, glyph.rectangle.h - sy)
        }
        if (width <= 0 || height <= 0) {
            return
        }
        let x1 = Float32(rect.x) + Float32(glyph.bearing.x);
        let y1 = Float32(rect.y) + Float32(glyph.bearing.y)
        let x2 = x1 + Float32(width);
        let y2 = y1 + Float32(height)
        let side = Float32(page.side)
        let u1 = (Float32(glyph.rectangle.x) + if (draw.font.isNull()) {
            Float32(0.5)
        } else {
            Float32(sx)
        }) / side
        let v1 = (Float32(glyph.rectangle.y) + if (draw.font.isNull()) {
            Float32(0.5)
        } else {
            Float32(sy)
        }) / side
        let u2 = if (draw.font.isNull()) {
            u1
        } else {
            u1 + Float32(width) / side
        }
        let v2 = if (draw.font.isNull()) {
            v1
        } else {
            v1 + Float32(height) / side
        }
        for (value in [x1, y1, x2, y1, x2, y2, x1, y2]) {
            xy.add(value)
        }
        for (value in [u1, v1, u2, v1, u2, v2, u1, v2]) {
            uv.add(value)
        }
    }
}

internal class GlyphBatch {
    let page: GlyphPage
    private let color: Bool
    private let original: Array<Float32>
    private let positions: CPointer<Float32>
    private let uv: CPointer<Float32>
    private let indices: CPointer<Int32>
    private let count: Int32
    private var x: Float32 = Float32.Max
    private var y: Float32 = Float32.Max
    private var closed = false
    init(builder: GlyphBatchBuilder) {
        this.page = builder.page
        this.color = builder.color
        this.original = builder.xy.toArray()
        this.count = Int32(original.size / 8)
        this.positions = unsafe { LibC.malloc<Float32>(count: max(1, original.size)) }
        this.uv = unsafe { LibC.malloc<Float32>(count: max(1, original.size)) }
        this.indices = unsafe { LibC.malloc<Int32>(count: max(1, Int64(count) * 6)) }
        try {
            if (positions.isNull() || uv.isNull() || indices.isNull()) {
                throw NativeTextException("Cannot allocate text geometry")
            }
            for (i in 0..original.size) {
                unsafe { uv.write(i, builder.uv[i]) }
            }
            let order: Array<Int32> = [0, 1, 2, 0, 2, 3]
            for (i in 0..Int64(count)) {
                for (j in 0..6) {
                    unsafe { indices.write(i * 6 + j, Int32(i) * 4 + order[j]) }
                }
            }
        } catch (error: Exception) {
            unsafe { LibC.free(positions) };
            unsafe { LibC.free(uv) };
            unsafe { LibC.free(indices) };
            throw error
        }
    }

    func draw(renderer: CPointer<Unit>, atlas: GlyphAtlas, offsetX: Float32, offsetY: Float32, tint: NativeTextColor): Unit {
        if (count <= 0) {
            return
        }
        if (closed || !page.valid) {
            throw NativeTextException("Font atlas geometry was retired")
        }
        if (x.toBits() != offsetX.toBits() || y.toBits() != offsetY.toBits()) {
            x = offsetX
            y = offsetY
            for (i in 0..original.size / 2) {
                unsafe { positions.write(i * 2, original[i * 2] + x) }
                unsafe { positions.write(i * 2 + 1, original[i * 2 + 1] + y) }
            }
        }
        var colorValue = EngineColor()
        colorValue.a = Float32(tint.alpha) / 255.0
        colorValue.r = (if (color) {
            Float32(1.0)
        } else {
            Float32(tint.red) / 255.0
        }) * colorValue.a
        colorValue.g = (if (color) {
            Float32(1.0)
        } else {
            Float32(tint.green) / 255.0
        }) * colorValue.a
        colorValue.b = (if (color) {
            Float32(1.0)
        } else {
            Float32(tint.blue) / 255.0
        }) * colorValue.a
        atlas.touch(page)
        if (!unsafe { SDL_RenderGeometryRaw(renderer, page.texture, positions, 8, inout colorValue, 0, uv, 8, count * 4,
            indices, count * 6, 4) }) {
            throw NativeTextException("Text geometry drawing failed: ${lastNativeError()}")
        }
    }

    func close(): Unit {
        if (!closed) {
            closed = true
            unsafe { LibC.free(positions) };
            unsafe { LibC.free(uv) };
            unsafe { LibC.free(indices) }
        }
    }
}
