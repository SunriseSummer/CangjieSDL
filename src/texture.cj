package sdl

/**
 * How a texture's pixels combine with the render target (mapped to SDL_BLENDMODE_*): no blending,
 * alpha blend, additive, color modulate, or multiply.
 */
public enum TextureBlendMode {
    | None
    | Blend
    | Add
    | Mod
    | Mul
}

/** Which axes a texture is mirrored across when rendered (mapped to SDL_FLIP_*). */
public enum TextureFlip {
    | None
    | Horizontal
    | Vertical
    | Both
}

/**
 * Optional settings for a rotated texture draw: a source sub-rectangle (in texture pixels,
 * defaulting to the whole texture), a rotation pivot (defaulting to the destination center),
 * and a mirror flip.
 */
public struct TextureRenderOptions {
    public let source: ?Rect
    public let center: ?Point
    public let flip: TextureFlip

    public init(source!: ?Rect = None, center!: ?Point = None, flip!: TextureFlip = TextureFlip.None) {
        this.source = source
        this.center = center
        this.flip = flip
    }
}

/**
 * A GPU-resident image wrapping an SDL_Texture, created from a `Surface` or an image file via the
 * renderer and drawn with `Renderer.texture`/`textureRotated`. `width`/`height` are the pixel size
 * captured at creation. Close it to free the GPU memory; reusing a closed texture throws
 * `SdlException`.
 */
public class Texture <: Resource {
    internal let ptr: CPointer<Unit>
    private var closed = false

    public let width: Float32
    public let height: Float32

    internal init(ptr: CPointer<Unit>) {
        this.ptr = ptr
        var w: Float32 = 0.0
        var h: Float32 = 0.0
        ensureSdl(unsafe { SDL_GetTextureSize(ptr, inout w, inout h) }, "SDL_GetTextureSize")
        this.width = w
        this.height = h
    }

    /** The texture's pixel dimensions as a `Size`. */
    public func size(): Size {
        Size(width, height)
    }

    /**
     * Sets the color multiplied into every drawn pixel (SDL_SetTextureColorMod); the alpha
     * channel is ignored — use `setAlpha`. Throws `SdlException` when the texture is closed
     * or SDL rejects the mod.
     */
    public func setColorMod(color: Color): Unit {
        ensureOpen()
        ensureSdl(unsafe { SDL_SetTextureColorMod(ptr, color.r, color.g, color.b) }, "SDL_SetTextureColorMod")
    }

    /**
     * Sets the texture's opacity as a 0-255 value, clamped (SDL_SetTextureAlphaMod).
     * Throws `SdlException` when the texture is closed or SDL rejects the mod.
     */
    public func setAlpha(alpha: Int64): Unit {
        ensureOpen()
        ensureSdl(unsafe { SDL_SetTextureAlphaMod(ptr, toChannel(alpha)) }, "SDL_SetTextureAlphaMod")
    }

    /**
     * Sets how the texture blends onto the render target (SDL_SetTextureBlendMode).
     * Throws `SdlException` when the texture is closed or SDL rejects the mode.
     */
    public func setBlendMode(mode: TextureBlendMode): Unit {
        ensureOpen()
        ensureSdl(unsafe { SDL_SetTextureBlendMode(ptr, blendModeCode(mode)) }, "SDL_SetTextureBlendMode")
    }

    /** Whether `close` has already been called; a closed texture throws on reuse. */
    public func isClosed(): Bool {
        closed
    }

    /** Frees the GPU texture (SDL_DestroyTexture); safe to call more than once. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        if (ptr.isNotNull()) {
            unsafe { SDL_DestroyTexture(ptr) }
        }
    }

    /**
     * Throws `SdlException` when a closed texture is reused.
     */
    private func ensureOpen(): Unit {
        if (closed) {
            throw SdlException("Texture is already closed.")
        }
    }
}

extend Renderer {
    /**
     * Throws `SdlException` when the source surface is closed or SDL cannot create a texture.
     */
    public func textureFromSurface(surface: Surface): Texture {
        if (surface.isClosed()) {
            throw SdlException("Cannot create texture from a closed surface.")
        }
        let texture = unsafe { SDL_CreateTextureFromSurface(ptr, surface.ptr) }
        if (texture.isNull()) {
            throw SdlException("SDL_CreateTextureFromSurface failed: ${lastSdlError()}")
        }
        Texture(texture)
    }

    /**
     * Throws `SdlException` when SDL cannot load the image or create a texture from it.
     */
    public func loadTexture(path: String): Texture {
        var texture = CPointer<Unit>()
        try (surface = Surface.load(path)) {
            texture = unsafe { SDL_CreateTextureFromSurface(ptr, surface.ptr) }
        }
        if (texture.isNull()) {
            throw SdlException("SDL_CreateTextureFromSurface failed: ${lastSdlError()}")
        }
        Texture(texture)
    }

    /**
     * Throws `SdlException` when the texture is closed or SDL cannot render it.
     */
    public func texture(texture: Texture, destination: Rect, source!: ?Rect = None): Unit {
        if (texture.isClosed()) {
            throw SdlException("Cannot render a closed texture.")
        }
        var dst = destination.toSdlFRect()
        match (source) {
            case Some(rect) =>
                var src = rect.toSdlFRect()
                ensureSdl(unsafe { SDL_RenderTexture(ptr, texture.ptr, inout src, inout dst) }, "SDL_RenderTexture")
            case None => ensureSdl(unsafe { SDL_RenderTexture(ptr, texture.ptr, CPointer<SdlFRect>(), inout dst) },
                "SDL_RenderTexture")
        }
    }

    /**
     * Throws `SdlException` when the texture is closed or SDL cannot render it.
     */
    public func textureRotated(
        texture: Texture,
        destination: Rect,
        angle: Float64,
        options!: TextureRenderOptions = TextureRenderOptions()
    ): Unit {
        if (texture.isClosed()) {
            throw SdlException("Cannot render a closed texture.")
        }
        var dst = destination.toSdlFRect()
        match ((options.source, options.center)) {
            case (Some(srcRect), Some(centerPoint)) =>
                var src = srcRect.toSdlFRect()
                var pivot = centerPoint.toSdlFPoint()
                ensureSdl(unsafe {
                    SDL_RenderTextureRotated(ptr, texture.ptr, inout src, inout dst, angle, inout pivot,
                        flipCode(options.flip))
                }, "SDL_RenderTextureRotated")
            case (Some(srcRect), None) =>
                var src = srcRect.toSdlFRect()
                ensureSdl(unsafe {
                    SDL_RenderTextureRotated(ptr, texture.ptr, inout src, inout dst, angle, CPointer<SdlFPoint>(),
                        flipCode(options.flip))
                }, "SDL_RenderTextureRotated")
            case (None, Some(centerPoint)) =>
                var pivot = centerPoint.toSdlFPoint()
                ensureSdl(unsafe {
                    SDL_RenderTextureRotated(ptr, texture.ptr, CPointer<SdlFRect>(), inout dst, angle, inout pivot,
                        flipCode(options.flip))
                }, "SDL_RenderTextureRotated")
            case (None, None) => ensureSdl(unsafe {
                SDL_RenderTextureRotated(
                    ptr,
                    texture.ptr,
                    CPointer<SdlFRect>(),
                    inout dst,
                    angle,
                    CPointer<SdlFPoint>(),
                    flipCode(options.flip)
                )
            }, "SDL_RenderTextureRotated")
        }
    }
}

private func blendModeCode(mode: TextureBlendMode): UInt32 {
    match (mode) {
        case TextureBlendMode.None => UInt32(0)
        case TextureBlendMode.Blend => UInt32(1)
        case TextureBlendMode.Add => UInt32(2)
        case TextureBlendMode.Mod => UInt32(4)
        case TextureBlendMode.Mul => UInt32(8)
    }
}

private func flipCode(flip: TextureFlip): Int32 {
    match (flip) {
        case TextureFlip.None => 0
        case TextureFlip.Horizontal => 1
        case TextureFlip.Vertical => 2
        case TextureFlip.Both => 3
    }
}

private func toChannel(value: Int64): UInt8 {
    if (value < 0) {
        UInt8(0)
    } else if (value > 255) {
        UInt8(255)
    } else {
        UInt8(value)
    }
}
