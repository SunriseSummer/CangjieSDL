package sdl

import std.collection.ArrayList

internal struct TextRasterTile {
    let texture: Texture
    let source: Rect
    let position: Point

    init(texture: Texture, source: Rect, position: Point) {
        this.texture = texture
        this.source = source
        this.position = position
    }
}

// One shaped run, possibly uploaded as multiple textures. One-pixel sampling borders keep
// bilinear filtering continuous at tile seams during rotation and fractional scaling.
internal class TextRasterImage {
    let tiles: Array<TextRasterTile>
    let width: Float32
    let height: Float32
    let offset: Point
    let layoutSize: Size
    let bytes: Int64
    private let colorBaked: Bool

    init(tiles: Array<TextRasterTile>, width: Float32, height: Float32, colorBaked!: Bool = false,
        offset!: Point = Point(0.0, 0.0), layoutSize!: ?Size = None) {
        this.tiles = tiles
        this.width = width
        this.height = height
        this.colorBaked = colorBaked
        this.offset = offset
        this.layoutSize = layoutSize.getOrDefault({=> Size(width, height)})
        var bytes: Int64 = 0
        for (tile in tiles) {
            bytes += Int64(tile.texture.width) * Int64(tile.texture.height) * 4
        }
        this.bytes = bytes
    }

    func close(): Unit {
        for (tile in tiles) {
            tile.texture.close()
        }
    }

    func canTint(): Bool {
        !colorBaked
    }

    func draw(renderer: CPointer<Unit>, origin: Point, scale: Size, color: Color, angle!: Float64 = 0.0): Unit {
        for (tile in tiles) {
            // The baked path is premultiplied: opacity must scale RGB and alpha together.
            tile.texture.setColorMod(if (colorBaked) {
                Color.rgb(Int64(color.a), Int64(color.a), Int64(color.a))
            } else {
                color
            })
            tile.texture.setAlpha(Int64(color.a))
            let blend: UInt32 = if (colorBaked) {
                0x10
            } else {
                1
            } // SDL_BLENDMODE_BLEND_PREMULTIPLIED / BLEND
            ensureSdl(unsafe { SDL_SetTextureBlendMode(tile.texture.ptr, blend) }, "SDL_SetTextureBlendMode")
            var source = tile.source.toSdlFRect()
            let position = Point(tile.position.x + offset.x, tile.position.y + offset.y)
            var destination = Rect(origin.x + position.x / scale.w, origin.y + position.y / scale.h,
                tile.source.w / scale.w, tile.source.h / scale.h).toSdlFRect()
            if (angle == 0.0) {
                ensureSdl(unsafe { SDL_RenderTexture(renderer, tile.texture.ptr, inout source, inout destination) },
                    "SDL_RenderTexture")
            } else {
                var pivot = Point((layoutSize.w / 2.0 - position.x) / scale.w, (layoutSize.h / 2.0 - position.y) / scale
                    .h).toSdlFPoint()
                ensureSdl(
                    unsafe { SDL_RenderTextureRotated(renderer, tile.texture.ptr, inout source, inout destination, angle,
                        inout pivot, 0) }, "SDL_RenderTextureRotated")
            }
        }
    }
}

internal func createTextRasterImage(renderer: CPointer<Unit>, device: RenderDeviceToken, surface: CPointer<Unit>,
    maxTextureSize: Int32, colorBaked!: Bool = false, offset!: Point = Point(0.0, 0.0), layoutSize!: ?Size = None): TextRasterImage {
    let header = unsafe { CPointer<SdlSurfaceHeader>(surface).read() }
    let limit = if (maxTextureSize >= 3) {
        maxTextureSize
    } else {
        Int32(4096)
    }
    if (header.width <= limit && header.height <= limit) {
        let texture = uploadTextRaster(renderer, device, surface)
        return TextRasterImage([TextRasterTile(texture, Rect(0.0, 0.0, texture.width, texture.height), Point(0.0, 0.0))],
            texture.width, texture.height, colorBaked: colorBaked, offset: offset, layoutSize: layoutSize)
    }
    // Copy alpha verbatim; blending while copying would apply glyph coverage twice.
    ensureSdl(unsafe { SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE) }, "SDL_SetSurfaceBlendMode")
    let tiles = ArrayList<TextRasterTile>()
    try {
        let step = limit - 2
        var y: Int32 = 0
        while (y < header.height) {
            var x: Int32 = 0
            let height = min(step, header.height - y)
            while (x < header.width) {
                let width = min(step, header.width - x)
                tiles.add(
                    uploadTextRasterTile(renderer, device, surface, header,
                        Rect(Float32(x), Float32(y), Float32(width), Float32(height))))
                x += width
            }
            y += height
        }
        let image = TextRasterImage(tiles.toArray(), Float32(header.width), Float32(header.height),
            colorBaked: colorBaked, offset: offset, layoutSize: layoutSize)
        image
    } catch (error: Exception) {
        for (tile in tiles) {
            tile.texture.close()
        }
        throw error
    }
}

private func uploadTextRasterTile(renderer: CPointer<Unit>, device: RenderDeviceToken, surface: CPointer<Unit>,
    header: SdlSurfaceHeader, core: Rect): TextRasterTile {
    let left = max(Int32(0), Int32(core.x) - 1)
    let top = max(Int32(0), Int32(core.y) - 1)
    let right = min(header.width, Int32(core.x + core.w) + 1)
    let bottom = min(header.height, Int32(core.y + core.h) + 1)
    let raw = unsafe { SDL_CreateSurface(right - left, bottom - top, header.format) }
    if (raw.isNull()) {
        throw SdlException("Text tile allocation failed: ${lastSdlError()}")
    }
    let part = Surface(raw)
    try {
        var source = Rect(Float32(left), Float32(top), Float32(right - left), Float32(bottom - top)).toSdlRect()
        ensureSdl(unsafe { SDL_BlitSurface(surface, inout source, part.ptr, CPointer<SdlRect>()) }, "SDL_BlitSurface")
        let texture = uploadTextRaster(renderer, device, part.ptr)
        return TextRasterTile(texture, Rect(core.x - Float32(left), core.y - Float32(top), core.w, core.h),
            Point(core.x, core.y))
    } finally {
        part.close()
    }
}

private func uploadTextRaster(renderer: CPointer<Unit>, device: RenderDeviceToken, surface: CPointer<Unit>): Texture {
    let raw = unsafe { SDL_CreateTextureFromSurface(renderer, surface) }
    if (raw.isNull()) {
        throw SdlException("Text texture creation failed: ${lastSdlError()}")
    }
    let texture = Texture(raw, device)
    try {
        texture.setBlendMode(TextureBlendMode.Blend)
        texture
    } catch (error: SdlException) {
        texture.close()
        throw error
    }
}
