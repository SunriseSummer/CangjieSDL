package sdl.text

import std.collection.{ArrayList, HashMap}
import std.deriving.*

internal let GLYPH_ATLAS_BUDGET: Int64 = 16 * 1024 * 1024
internal let GLYPH_ATLAS_MAX_SIDE: Int32 = 2048
internal let GLYPH_PIXEL_FORMAT: UInt32 = 0x16362004 // SDL_PIXELFORMAT_ARGB8888

private let ATLAS_GLYPH_LIMIT: Int64 = 32768
private let ATLAS_DEFAULT_SIDE: Int32 = 512
private let GLYPH_IMAGE_SDF: Int32 = 3
private let RGBA_BYTES: Int64 = 4
private let PIXEL_WHITE: UInt32 = 0xFFFFFFFF
private let PIXEL_ALPHA_SHIFT: UInt32 = 24
private let PIXEL_RED_SHIFT: UInt32 = 16
private let PIXEL_GREEN_SHIFT: UInt32 = 8
private let PIXEL_CHANNEL_MAX: UInt32 = 255
private let PIXEL_HALF_CHANNEL: UInt32 = 127

internal class GlyphAtlasBusy <: Exception {
    init() {
        super("Glyph atlas pages are in use by the current draw batch")
    }
}

@Derive[Equatable, Hashable]
internal struct AtlasGlyphKey {
    let font: UInt64
    let glyph: UInt32
    init(font: UInt64, glyph: UInt32) {
        this.font = font
        this.glyph = glyph
    }
}

internal class GlyphPage {
    let texture: CPointer<Unit>
    let side: Int32
    let identity: UInt64
    var lastUse: UInt64 = 0
    var pins: Int64 = 0
    var valid = true
    private var x: Int32 = 1
    private var y: Int32 = 1
    private var rowHeight: Int32 = 0
    init(renderer: CPointer<Unit>, side: Int32, identity: UInt64) {
        this.side = side
        this.identity = identity
        let texture = unsafe { SDL_CreateTexture(renderer, GLYPH_PIXEL_FORMAT, 0, side, side) }
        if (texture.isNull()) {
            throw NativeTextException("Cannot allocate font atlas texture: ${lastNativeError()}")
        }
        this.texture = texture
        let clear = unsafe { SDL_CreateSurface(side, side, GLYPH_PIXEL_FORMAT) }
        try {
            if (clear.isNull()) {
                throw NativeTextException("Cannot initialize font atlas pixels")
            }
            let surface = unsafe { CPointer<EngineSurface>(clear).read() }
            if (!unsafe { SDL_FillSurfaceRect(clear, CPointer<TtfSubstringRect>(), 0) } ||
                !unsafe { SDL_UpdateTexture(texture, CPointer<TtfSubstringRect>(), surface.pixels, surface.pitch) } ||
                !unsafe { SDL_SetTextureBlendMode(texture, 0x10) } || !unsafe { SDL_SetTextureScaleMode(texture, 1) }) {
                throw NativeTextException("Cannot initialize font atlas: ${lastNativeError()}")
            }
        } catch (error: Exception) {
            unsafe { SDL_DestroyTexture(texture) };
            throw error
        } finally {
            if (clear.isNotNull()) {
                unsafe { SDL_DestroySurface(clear) }
            }
        }
    }

    func allocate(width: Int32, height: Int32): ?TtfSubstringRect {
        if (width + 2 > side || height + 2 > side) {
            return None
        }
        var nextX = x;
        var nextY = y;
        var nextRow = rowHeight
        if (nextX + width + 1 > side) {
            nextX = 1
            nextY += nextRow
            nextRow = 0
        }
        if (nextY + height + 1 > side) {
            return None
        }
        let rect = engineRect(nextX, nextY, width, height)
        x = nextX + width + 2
        y = nextY
        rowHeight = max(nextRow, height + 2)
        Some(rect)
    }

    func close(): Unit {
        if (valid) {
            valid = false
            unsafe { SDL_DestroyTexture(texture) }
        }
    }
}

internal class AtlasGlyph {
    let page: GlyphPage
    let rectangle: TtfSubstringRect
    let color: Bool
    let bearing: GlyphBearing
    init(page: GlyphPage, rectangle: TtfSubstringRect, color: Bool, bearing: GlyphBearing) {
        this.page = page
        this.rectangle = rectangle
        this.color = color
        this.bearing = bearing
    }
}

internal class GlyphAtlas {
    private let renderer: CPointer<Unit>
    private let sources: HashMap<UIntNative, GlyphRasterSource>
    private let pages = ArrayList<GlyphPage>()
    private let glyphs = HashMap<AtlasGlyphKey, AtlasGlyph>()
    private let fonts = HashMap<UIntNative, UInt64>()
    private var nextIdentity: UInt64 = 1
    private var clock: UInt64 = 0
    var bytes: Int64 = 0
    var evictions: UInt64 = 0
    init(renderer: CPointer<Unit>, sources: HashMap<UIntNative, GlyphRasterSource>) {
        this.renderer = renderer
        this.sources = sources
    }

    func size(): Int64 {
        glyphs.size
    }

    func touch(page: GlyphPage): Unit {
        clock += 1
        page.lastUse = clock
    }

    func get(draw: EngineDraw): AtlasGlyph {
        let key = keyFor(draw)
        clock += 1
        if (let Some(glyph) <- glyphs.get(key)) {
            glyph.page.lastUse = clock
            return glyph
        }
        if (draw.font.isNotNull() && (draw.rectangle.w > GLYPH_ATLAS_MAX_SIDE || draw.rectangle.h > GLYPH_ATLAS_MAX_SIDE)) {
            throw NativeTextException("A font glyph exceeds the 2048-pixel atlas limit")
        }
        var kind: Int32 = 1
        let image = if (draw.font.isNull()) {
            unsafe { SDL_CreateSurface(1, 1, GLYPH_PIXEL_FORMAT) }
        } else {
            unsafe { TTF_GetGlyphImageForIndex(draw.font, draw.glyph, inout kind) }
        }
        if (image.isNull()) {
            throw NativeTextException("Cannot rasterize font glyph: ${lastNativeError()}")
        }
        try {
            if (draw.font.isNull()) {
                if (!unsafe { SDL_FillSurfaceRect(image, CPointer<TtfSubstringRect>(), PIXEL_WHITE) }) {
                    throw NativeTextException("Cannot initialize decoration glyph")
                }
            }
            let surface = unsafe { CPointer<EngineSurface>(image).read() }
            validateGlyphImage(surface, kind)
            let correction = match (sources.get(draw.font.toUIntNative())) {
                case Some(source) => source.bearing(draw.glyph, image, kind == 2)
                case None => GlyphBearing()
            }
            let glyph = allocate(surface.width, surface.height, kind == 2, correction)
            let page = glyph.page
            // Premultiplied pixels with transparent gutters prevent dark or colored fringes when
            // glyphs are sampled at fractional positions. The temporary caller-owned surface is freed.
            premultiplyGlyph(surface)
            var area = glyph.rectangle
            if (!unsafe { SDL_UpdateTexture(page.texture, inout area, surface.pixels, surface.pitch) }) {
                throw NativeTextException("Font atlas upload failed: ${lastNativeError()}")
            }
            page.lastUse = clock
            glyphs[key] = glyph
            glyph
        } finally {
            unsafe { SDL_DestroySurface(image) }
        }
    }

    private func keyFor(draw: EngineDraw): AtlasGlyphKey {
        AtlasGlyphKey(fontIdentity(draw.font), if (draw.font.isNull()) {
            UInt32(0)
        } else {
            draw.glyph
        })
    }

    func forgetFont(font: CPointer<Unit>): Unit {
        if (let Some(identity) <- fonts.remove(font.toUIntNative())) {
            let keys = ArrayList<AtlasGlyphKey>()
            for ((key, _) in glyphs) {
                if (key.font == identity) {
                    keys.add(key)
                }
            }
            for (key in keys) {
                let _ = glyphs.remove(key) // cjcheck-ignore: ignore-result # the key was collected from this map; removal is idempotent
            }
        }
    }

    func close(): Unit {
        glyphs.clear();
        fonts.clear()
        for (page in pages) {
            page.close()
        }
        pages.clear();
        bytes = 0
    }

    private func fontIdentity(font: CPointer<Unit>): UInt64 {
        if (font.isNull()) {
            return 0
        }
        let pointer = font.toUIntNative()
        if (let Some(identity) <- fonts.get(pointer)) {
            return identity
        }
        let identity = freshIdentity()
        fonts[pointer] = identity
        identity
    }

    private func freshIdentity(): UInt64 {
        if (nextIdentity == UInt64.Max) {
            throw NativeTextException("Font atlas identity exhausted")
        }
        let identity = nextIdentity;
        nextIdentity += 1
        identity
    }

    private func allocate(width: Int32, height: Int32, color: Bool, bearing: GlyphBearing): AtlasGlyph {
        if (glyphs.size >= ATLAS_GLYPH_LIMIT) {
            evictPage()
        }
        for (page in pages) {
            if (let Some(rect) <- page.allocate(width, height)) {
                return AtlasGlyph(page, rect, color, bearing)
            }
        }
        var side = ATLAS_DEFAULT_SIDE
        while (side < width + 2 || side < height + 2) {
            side *= 2
        }
        let cost = Int64(side) * Int64(side) * RGBA_BYTES
        while (bytes + cost > GLYPH_ATLAS_BUDGET) {
            evictPage()
        }
        let page = GlyphPage(renderer, side, freshIdentity())
        pages.add(page);
        bytes += cost
        let rect = match (page.allocate(width, height)) {
            case Some(value) => value
            case None => throw NativeTextException("New atlas page cannot fit its requested glyph")
        }
        AtlasGlyph(page, rect, color, bearing)
    }

    private func evictPage(): Unit {
        var oldest: ?GlyphPage = None
        for (page in pages) {
            if (page.pins > 0) {
                continue
            }
            match (oldest) {
                case Some(previous) =>
                    if (page.lastUse < previous.lastUse) {
                        oldest = Some(page)
                    }
                case None => oldest = Some(page)
            }
        }
        let page = match (oldest) {
            case Some(value) => value;
            case None => throw GlyphAtlasBusy()
        }
        let keys = ArrayList<AtlasGlyphKey>()
        for ((key, glyph) in glyphs) {
            if (glyph.page.identity == page.identity) {
                keys.add(key)
            }
        }
        for (key in keys) {
            let _ = glyphs.remove(key) // cjcheck-ignore: ignore-result # the key was collected from this map; removal is idempotent
        }
        pages.removeIf({value => value.identity == page.identity})
        page.close();
        bytes -= Int64(page.side) * Int64(page.side) * RGBA_BYTES
        evictions += 1
    }
}

internal func engineRect(x: Int32, y: Int32, width: Int32, height: Int32): TtfSubstringRect {
    var rect = TtfSubstringRect();
    rect.x = x
    rect.y = y
    rect.w = width
    rect.h = height
    rect
}

private func premultiplyGlyph(surface: EngineSurface): Unit {
    for (y in 0..Int64(surface.height)) {
        let row = unsafe { CPointer<UInt32>(CPointer<UInt8>(surface.pixels) + y * Int64(surface.pitch)) }
        for (x in 0..Int64(surface.width)) {
            let pixel = unsafe { row.read(x) }
            let alpha = pixel >> PIXEL_ALPHA_SHIFT
            let red = (((pixel >> PIXEL_RED_SHIFT) & PIXEL_CHANNEL_MAX) * alpha + PIXEL_HALF_CHANNEL) / PIXEL_CHANNEL_MAX
            let green = (((pixel >> PIXEL_GREEN_SHIFT) & PIXEL_CHANNEL_MAX) * alpha + PIXEL_HALF_CHANNEL) /
                PIXEL_CHANNEL_MAX
            let blue = ((pixel & PIXEL_CHANNEL_MAX) * alpha + PIXEL_HALF_CHANNEL) / PIXEL_CHANNEL_MAX
            unsafe { row.write(x,
                (alpha << PIXEL_ALPHA_SHIFT) | (red << PIXEL_RED_SHIFT) | (green << PIXEL_GREEN_SHIFT) | blue) }
        }
    }
}

private func validateGlyphImage(surface: EngineSurface, kind: Int32): Unit {
    if (surface.width <= 0 || surface.height <= 0 || surface.width + 2 > GLYPH_ATLAS_MAX_SIDE || surface.height + 2 >
        GLYPH_ATLAS_MAX_SIDE || surface.format != GLYPH_PIXEL_FORMAT || kind == GLYPH_IMAGE_SDF) {
        throw NativeTextException("Unsupported glyph image size, format or SDF mode")
    }
}
