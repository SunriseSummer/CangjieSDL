package sdl

extend Surface {
    private func ensureImageSurfaceOpen(): Unit {
        if (isClosed()) {
            throw SdlException("Surface is already closed.")
        }
    }
    /**
     * Decodes one static image from encoded bytes. An optional hint such as "TGA" handles formats
     * without a signature. Does not retain the caller's bytes; do not mutate them during this call.
     * Throws `SdlException` on decode failure and `IllegalArgumentException` for a NUL type hint.
     */
    public static func loadBytes(bytes: Array<UInt8>, typeHint!: String = "",
        options!: ImageLoadOptions = ImageLoadOptions()): Surface {
        decodeImageBytes(bytes, typeHint, options)
    }

    /** Returns the pixel dimensions; throws `SdlException` after close. */
    public func size(): Size {
        ensureImageSurfaceOpen()
        let header = unsafe { CPointer<SdlSurfaceHeader>(ptr).read() }
        Size(Float32(header.width), Float32(header.height))
    }

    /** Reads an RGBA pixel; throws `SdlException` for closed surfaces or out-of-bounds coordinates. */
    public func readPixel(x: Int32, y: Int32): Color {
        ensureImageSurfaceOpen()
        var r: UInt8 = 0
        var g: UInt8 = 0
        var b: UInt8 = 0
        var a: UInt8 = 0
        ensureSdl(unsafe { SDL_ReadSurfacePixel(ptr, x, y, inout r, inout g, inout b, inout a) }, "SDL_ReadSurfacePixel")
        Color(r, g, b, a)
    }

    /**
     * Returns an independent surface at the exact pixel size. Throws `IllegalArgumentException`
     * for non-positive dimensions and `SdlException` on a closed source or SDL allocation failure.
     */
    public func resized(width: Int32, height: Int32, sampling!: TextureScaleMode = TextureScaleMode.Linear): Surface {
        ensureImageSurfaceOpen()
        if (width <= 0 || height <= 0) {
            throw IllegalArgumentException("Resized image dimensions must be positive")
        }
        let result = unsafe { SDL_ScaleSurface(ptr, width, height, textureScaleCode(sampling)) }
        if (result.isNull()) {
            throw SdlException("SDL_ScaleSurface failed: ${lastSdlError()}")
        }
        Surface(result)
    }

    /**
     * Saves lossless PNG with transparency. Throws `IllegalArgumentException` for a NUL path,
     * or `SdlException` on a closed surface or a write failure.
     */
    public func savePng(path: String): Unit {
        ensureImageSurfaceOpen()
        validateImageString(path)
        let cPath = unsafe { LibC.mallocCString(path) }
        try (name = cPath.asResource()) {
            ensureSdl(unsafe { SDL_SavePNG(ptr, name.value) }, "SDL_SavePNG")
        }
    }

    /**
     * Saves JPEG (no alpha). Throws `IllegalArgumentException` for quality outside 0..100 or a NUL
     * path, and `SdlException` on a closed surface or write failure.
     */
    public func saveJpeg(path: String, quality!: Int32 = 90): Unit {
        ensureImageSurfaceOpen()
        validateImageString(path)
        if (quality < 0 || quality > 100) {
            throw IllegalArgumentException("JPEG quality must be in 0..100")
        }
        let cPath = unsafe { LibC.mallocCString(path) }
        try (name = cPath.asResource()) {
            ensureSdl(unsafe { IMG_SaveJPG(ptr, name.value, quality) }, "IMG_SaveJPG")
        }
    }
}
