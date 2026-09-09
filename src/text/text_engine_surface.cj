package sdl.text

import std.collection.HashMap

private let TEXT_SURFACE_PIXEL_BUDGET: Int64 = 16 * 1024 * 1024
private let SURFACE_GLYPH_CACHE_BUDGET: Int64 = 8 * 1024 * 1024
private let SURFACE_ALPHA_MASK: UInt32 = 0xFF000000
private let SURFACE_RGB_WHITE: UInt32 = 0xFFFFFF
private let SURFACE_ALPHA_SHIFT: UInt32 = 24
private let SURFACE_RED_SHIFT: UInt32 = 16
private let SURFACE_GREEN_SHIFT: UInt32 = 8
private let SURFACE_CHANNEL_MAX: UInt32 = 255
private let SURFACE_HALF_CHANNEL: UInt32 = 127

/** Owned surface pixels and their position relative to the unchanged text layout origin. */
protected struct NativeTextSurface {
    public let pointer: CPointer<Unit>
    public let colorBaked: Bool
    public let x: Int32
    public let y: Int32
    public let width: Float32
    public let height: Float32
    init(pointer: CPointer<Unit>, bounds: TtfSubstringRect, metrics: NativeTextMetrics, colorBaked!: Bool = false) {
        this.pointer = pointer
        this.colorBaked = colorBaked
        x = bounds.x
        y = bounds.y
        width = metrics.width
        height = metrics.height
    }
}

internal func nativeEngineColorSurface(layout: EngineLayout, state: CangjieTextEngine, color: ?NativeTextColor): NativeTextSurface {
    let images = SurfaceGlyphImages()
    var surface = CPointer<Unit>()
    try {
        let bounds = engineSurfaceBounds(layout, state.sources, images)
        surface = allocateEngineSurface(bounds)
        if (surface.isNull()) {
            return NativeTextSurface(surface, bounds, layout.metrics)
        }
        let baked = color.isSome() && images.containsColor(layout)
        let ink = match (color) {
            case Some(value) where baked => surfaceInk(value)
            case _ => SURFACE_RGB_WHITE
        }
        let background: UInt32 = if (baked) {
            0
        } else {
            ink
        }
        if (!unsafe { SDL_FillSurfaceRect(surface, CPointer<TtfSubstringRect>(), background) }) {
            throw NativeTextException("Cannot initialize text surface")
        }
        paintEngineSurface(surface, layout, state.sources, images,
            SurfaceGlyphStyle(ink, color: false, premultiplied: baked, offset: GlyphBearing(x: -bounds.x, y: -bounds.y)))
        NativeTextSurface(surface, bounds, layout.metrics, colorBaked: baked)
    } catch (error: Exception) {
        if (surface.isNotNull()) {
            unsafe { SDL_DestroySurface(surface) }
        }
        throw error
    } finally {
        images.close()
        state.probes.flush()
    }
}

private func surfaceInk(color: NativeTextColor): UInt32 {
    (UInt32(color.red) << SURFACE_RED_SHIFT) | (UInt32(color.green) << SURFACE_GREEN_SHIFT) | UInt32(color.blue)
}

private func engineSurfaceBounds(layout: EngineLayout, sources: HashMap<UIntNative, GlyphRasterSource>,
    images: SurfaceGlyphImages): TtfSubstringRect {
    var width = Int64(layout.metrics.width);
    var height = Int64(layout.metrics.height)
    var left: Int64 = 0;
    var top: Int64 = 0
    var hasInk = false
    for (draw in layout.draws) {
        if (draw.rectangle.w > 0 && draw.rectangle.h > 0) {
            hasInk = true
            // Public copy metrics precede color/outline bearing correction. Reserve the actual
            // raster extent too; e.g. Segoe UI Emoji at 48 pt extends one row past those metrics.
            if (draw.font.isNotNull()) {
                let (image, color) = images.get(draw)
                let bearing = match (sources.get(draw.font.toUIntNative())) {
                    case Some(source) => source.bearing(draw.glyph, image, color)
                    case None => GlyphBearing()
                }
                let ink = images.ink(draw)
                let x = Int64(draw.rectangle.x) + Int64(bearing.x)
                let y = Int64(draw.rectangle.y) + Int64(bearing.y)
                let sx = max(0, draw.source.x);
                let sy = max(0, draw.source.y)
                if (ink.w > 0 && ink.h > 0) {
                    left = min(left, x + Int64(max(0, ink.x - sx)))
                    top = min(top, y + Int64(max(0, ink.y - sy)))
                    width = max(width, x + Int64(min(draw.rectangle.w, ink.x + ink.w - sx)))
                    height = max(height, y + Int64(min(draw.rectangle.h, ink.y + ink.h - sy)))
                }
            }
        }
    }
    if (width <= 0 || height <= 0 || !hasInk) {
        return TtfSubstringRect()
    }
    width -= left
    height -= top
    if (width > Int64(Int32.Max) || height > Int64(Int32.Max) || width > TEXT_SURFACE_PIXEL_BUDGET / height) {
        throw NativeTextException("Text surface exceeds the 16-million-pixel raster budget")
    }
    engineRect(Int32(left), Int32(top), Int32(width), Int32(height))
}

private func allocateEngineSurface(bounds: TtfSubstringRect): CPointer<Unit> {
    if (bounds.w <= 0 || bounds.h <= 0) {
        return CPointer<Unit>()
    }
    let surface = unsafe { SDL_CreateSurface(bounds.w, bounds.h, GLYPH_PIXEL_FORMAT) }
    if (surface.isNull()) {
        throw NativeTextException("Cannot allocate text surface: ${lastNativeError()}")
    }
    surface
}

private func paintEngineSurface(surface: CPointer<Unit>, layout: EngineLayout,
    sources: HashMap<UIntNative, GlyphRasterSource>, images: SurfaceGlyphImages, style: SurfaceGlyphStyle): Unit {
    let target = unsafe { CPointer<EngineSurface>(surface).read() }
    for (draw in layout.draws) {
        if (draw.rectangle.w <= 0 || draw.rectangle.h <= 0) {
            continue
        }
        if (draw.font.isNull()) {
            var rect = draw.rectangle
            rect.x += style.offset.x
            rect.y += style.offset.y
            if (!unsafe { SDL_FillSurfaceRect(surface, inout rect, style.ink | SURFACE_ALPHA_MASK) }) {
                throw NativeTextException("Cannot rasterize text decoration")
            }
            continue
        }
        let (image, colorGlyph) = images.get(draw)
        let correction = match (sources.get(draw.font.toUIntNative())) {
            case Some(source) => source.bearing(draw.glyph, image, colorGlyph)
            case None => GlyphBearing()
        }
        compositeGlyph(target, unsafe { CPointer<EngineSurface>(image).read() }, draw, correction,
            SurfaceGlyphStyle(style.ink, color: colorGlyph, premultiplied: style.premultiplied, offset: style.offset))
    }
}

private class SurfaceGlyphImages {
    private let images = HashMap<AtlasGlyphKey, CPointer<Unit>>()
    private let colors = HashMap<AtlasGlyphKey, Bool>()
    private let bounds = HashMap<AtlasGlyphKey, TtfSubstringRect>()
    private var bytes: Int64 = 0
    func ink(draw: EngineDraw): TtfSubstringRect {
        let key = AtlasGlyphKey(UInt64(draw.font.toUIntNative()), draw.glyph)
        if (let Some(rect) <- bounds.get(key)) {
            return rect
        }
        let (image, _) = get(draw)
        let header = unsafe { CPointer<EngineSurface>(image).read() }
        var left = header.width;
        var top = header.height;
        var right: Int32 = 0;
        var bottom: Int32 = 0
        for (y in 0..Int64(header.height)) {
            let row = unsafe { CPointer<UInt32>(CPointer<UInt8>(header.pixels) + y * Int64(header.pitch)) }
            for (x in 0..Int64(header.width)) {
                if ((unsafe { row.read(x) } & SURFACE_ALPHA_MASK) != 0) {
                    left = min(left, Int32(x))
                    top = min(top, Int32(y))
                    right = max(right, Int32(x) + 1)
                    bottom = max(bottom, Int32(y) + 1)
                }
            }
        }
        let rect = engineRect(left, top, max(0, right - left), max(0, bottom - top))
        bounds[key] = rect
        rect
    }
    // Reuse these bounded glyph images in the paint pass; no second raster buffer is allocated.
    func containsColor(layout: EngineLayout): Bool {
        for (draw in layout.draws) {
            if (draw.font.isNotNull() && draw.rectangle.w > 0 && draw.rectangle.h > 0 && get(draw)[1]) {
                return true
            }
        }
        false
    }
    func get(draw: EngineDraw): (CPointer<Unit>, Bool) {
        if (draw.rectangle.w > GLYPH_ATLAS_MAX_SIDE || draw.rectangle.h > GLYPH_ATLAS_MAX_SIDE) {
            throw NativeTextException("Text glyph exceeds the 2048-pixel raster limit")
        }
        let key = AtlasGlyphKey(UInt64(draw.font.toUIntNative()), draw.glyph)
        if (let Some(image) <- images.get(key)) {
            return (image, colors.get(key).getOrDefault({=> false}))
        }
        var kind: Int32 = 0
        let image = unsafe { TTF_GetGlyphImageForIndex(draw.font, draw.glyph, inout kind) }
        if (image.isNull()) {
            throw NativeTextException("Cannot rasterize text glyph")
        }
        let header = unsafe { CPointer<EngineSurface>(image).read() }
        if (header.width < 0 || header.height < 0 || header.width > GLYPH_ATLAS_MAX_SIDE || header.height >
            GLYPH_ATLAS_MAX_SIDE || header.format != GLYPH_PIXEL_FORMAT || kind == 3) {
            unsafe { SDL_DestroySurface(image) };
            throw NativeTextException("Unsupported text glyph raster")
        }
        let cost = Int64(header.pitch) * Int64(header.height) + 96
        if (bytes + cost > SURFACE_GLYPH_CACHE_BUDGET) {
            close()
        }
        images[key] = image
        bytes += cost
        colors[key] = kind == 2
        (image, kind == 2)
    }
    func close(): Unit {
        for ((_, image) in images) {
            unsafe { SDL_DestroySurface(image) }
        }
        images.clear();
        colors.clear();
        bounds.clear();
        bytes = 0
    }
}

private struct SurfaceGlyphStyle {
    let ink: UInt32
    let color: Bool
    let premultiplied: Bool
    let offset: GlyphBearing
    init(ink: UInt32, color!: Bool, premultiplied!: Bool, offset!: GlyphBearing = GlyphBearing()) {
        this.ink = ink
        this.color = color
        this.premultiplied = premultiplied
        this.offset = offset
    }
}

private func compositeGlyph(target: EngineSurface, glyph: EngineSurface, draw: EngineDraw, bearing: GlyphBearing,
    style: SurfaceGlyphStyle): Unit {
    var rect = draw.rectangle
    rect.x += bearing.x + style.offset.x
    rect.y += bearing.y + style.offset.y
    let sx = max(Int32(0), draw.source.x);
    let sy = max(Int32(0), draw.source.y)
    let width = min(rect.w, min(glyph.width - sx, target.width - rect.x))
    let height = min(rect.h, min(glyph.height - sy, target.height - rect.y))
    for (y in Int64(max(Int32(0), -rect.y))..Int64(max(Int32(0), height))) {
        let source = unsafe { CPointer<UInt32>(CPointer<UInt8>(glyph.pixels) + (Int64(sy) + y) * Int64(glyph.pitch)) }
        let destination = unsafe { CPointer<UInt32>(
            CPointer<UInt8>(target.pixels) + (Int64(rect.y) + y) * Int64(target.pitch)) }
        for (x in Int64(max(Int32(0), -rect.x))..Int64(max(Int32(0), width))) {
            let pixel = unsafe { source.read(Int64(sx) + x) }
            let alpha = pixel >> SURFACE_ALPHA_SHIFT
            if (alpha == 0) {
                continue
            }
            let position = Int64(rect.x) + x
            let previous = unsafe { destination.read(position) }
            // SDL_ttf's monochrome surface raster combines overlapping glyph coverage with OR.
            let result = if (style.color) {
                pixel
            } else {
                ((previous | (alpha << SURFACE_ALPHA_SHIFT)) & SURFACE_ALPHA_MASK) | style.ink
            }
            unsafe { destination.write(position, if (style.premultiplied) {
                premultiplyTextPixel(result)
            } else {
                result
            }) }
        }
    }
}

// Premultiply during composition, avoiding an extra full-surface pass or second buffer.
private func premultiplyTextPixel(pixel: UInt32): UInt32 {
    let alpha = pixel >> SURFACE_ALPHA_SHIFT
    let red = (((pixel >> SURFACE_RED_SHIFT) & SURFACE_CHANNEL_MAX) * alpha + SURFACE_HALF_CHANNEL) / SURFACE_CHANNEL_MAX
    let green = (((pixel >> SURFACE_GREEN_SHIFT) & SURFACE_CHANNEL_MAX) * alpha + SURFACE_HALF_CHANNEL) /
        SURFACE_CHANNEL_MAX
    let blue = ((pixel & SURFACE_CHANNEL_MAX) * alpha + SURFACE_HALF_CHANNEL) / SURFACE_CHANNEL_MAX
    (alpha << SURFACE_ALPHA_SHIFT) | (red << SURFACE_RED_SHIFT) | (green << SURFACE_GREEN_SHIFT) | blue
}
