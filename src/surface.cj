package sdl

/**
 * A CPU-side RGBA pixel buffer wrapping an SDL_Surface — the staging ground for loading image
 * files, writing pixels, and saving BMPs before uploading to a GPU `Texture`. Close it to free
 * the native surface; reusing a closed surface throws `SdlException`.
 */
public class Surface <: Resource {
    internal let ptr: CPointer<Unit>
    private var closed = false

    internal init(ptr: CPointer<Unit>) {
        this.ptr = ptr
    }

    /**
     * Throws `SdlException` when SDL cannot allocate an RGBA surface.
     */
    public static func create(width: Int32, height: Int32): Surface {
        let surface = unsafe { SDL_CreateSurface(width, height, SDL_PIXELFORMAT_RGBA32) }
        if (surface.isNull()) {
            throw SdlException("SDL_CreateSurface failed: ${lastSdlError()}")
        }
        Surface(surface)
    }

    /**
     * Loads an image file, picking the decoder from the path's extension (`.png` reads as PNG,
     * anything else as BMP). Throws `SdlException` when the file cannot be loaded.
     */
    public static func load(path: String): Surface {
        match (imageFormatFromPath(path)) {
            case ImageFileFormat.Png => return loadPng(path)
            case ImageFileFormat.Bmp => return loadBmp(path)
        }
    }

    /** Loads a BMP file (SDL_LoadBMP). Throws `SdlException` when the file cannot be loaded. */
    public static func loadBmp(path: String): Surface {
        loadWith(path, ImageFileFormat.Bmp)
    }

    /** Loads a PNG file (SDL_LoadPNG). Throws `SdlException` when the file cannot be loaded. */
    public static func loadPng(path: String): Surface {
        loadWith(path, ImageFileFormat.Png)
    }

    /**
     * Fills the whole surface with `color` (SDL_ClearSurface).
     * Throws `SdlException` when the surface is closed or SDL cannot clear it.
     */
    public func clear(color: Color): Unit {
        ensureOpen()
        ensureSdl(unsafe {
            SDL_ClearSurface(
                ptr,
                Float32(color.r) / 255.0,
                Float32(color.g) / 255.0,
                Float32(color.b) / 255.0,
                Float32(color.a) / 255.0
            )
        }, "SDL_ClearSurface")
    }

    /**
     * Sets the pixel at (`x`, `y`) to `color` (SDL_WriteSurfacePixel).
     * Throws `SdlException` when the surface is closed or the write fails.
     */
    public func writePixel(x: Int32, y: Int32, color: Color): Unit {
        ensureOpen()
        ensureSdl(unsafe { SDL_WriteSurfacePixel(ptr, x, y, color.r, color.g, color.b, color.a) },
            "SDL_WriteSurfacePixel")
    }

    /**
     * Writes the surface to a BMP file (SDL_SaveBMP).
     * Throws `SdlException` when the surface is closed or SDL cannot save the file.
     */
    public func saveBmp(path: String): Unit {
        ensureOpen()
        let cPath = unsafe { LibC.mallocCString(path) }
        try (pathResource = cPath.asResource()) {
            ensureSdl(unsafe { SDL_SaveBMP(ptr, pathResource.value) }, "SDL_SaveBMP")
        }
    }

    /** Whether `close` has already been called; a closed surface throws on reuse. */
    public func isClosed(): Bool {
        closed
    }

    /** Frees the native surface (SDL_DestroySurface); safe to call more than once. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        if (ptr.isNotNull()) {
            unsafe { SDL_DestroySurface(ptr) }
        }
    }

    /**
     * Throws `SdlException` when a closed surface is reused.
     */
    private func ensureOpen(): Unit {
        if (closed) {
            throw SdlException("Surface is already closed.")
        }
    }
}

/** The image file formats surface loading understands. */
public enum ImageFileFormat {
    | Bmp
    | Png
}

/** The image format implied by a path's extension: `.png`/`.PNG` is PNG, anything else BMP. */
public func imageFormatFromPath(path: String): ImageFileFormat {
    if (path.endsWith(".png") || path.endsWith(".PNG")) {
        ImageFileFormat.Png
    } else {
        ImageFileFormat.Bmp
    }
}

/**
 * Throws `SdlException` when SDL cannot load the requested image file.
 */
private func loadWith(path: String, format: ImageFileFormat): Surface {
    let cPath = unsafe { LibC.mallocCString(path) }
    var surface = CPointer<Unit>()
    try (pathResource = cPath.asResource()) {
        surface = match (format) {
            case ImageFileFormat.Png => unsafe { SDL_LoadPNG(pathResource.value) }
            case ImageFileFormat.Bmp => unsafe { SDL_LoadBMP(pathResource.value) }
        }
    }
    if (surface.isNull()) {
        throw SdlException("Image load failed for '${path}': ${lastSdlError()}")
    }
    Surface(surface)
}
