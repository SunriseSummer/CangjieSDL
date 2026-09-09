package sdl

/**
 * Pixel bounds for a static image. Zero leaves that axis unconstrained. Raster images are only
 * downscaled, after decoding; SVG is rasterized directly at the requested size. Aspect ratio is
 * preserved. `maxPixels` rejects an oversized decoded result before texture upload, but does not
 * bound a codec's temporary allocations. Defaults retain the image's native dimensions.
 */
public struct ImageLoadOptions {
    public let width: Int32
    public let height: Int32
    public let maxPixels: Int64

    /** Throws `IllegalArgumentException` for negative bounds or a non-positive pixel budget. */
    public init(width!: Int32 = 0, height!: Int32 = 0, maxPixels!: Int64 = 67108864) {
        if (width < 0 || height < 0 || maxPixels <= 0) {
            throw IllegalArgumentException("Image bounds must be non-negative and maxPixels must be positive")
        }
        if (width > 0 && height > 0 && Int64(width) * Int64(height) > maxPixels) {
            throw IllegalArgumentException("Requested image dimensions exceed maxPixels")
        }
        this.width = width
        this.height = height
        this.maxPixels = maxPixels
    }
}

/** Returns the linked SDL_image version as major * 1000000 + minor * 1000 + patch. */
public func imageVersion(): Int32 {
    unsafe { IMG_Version() }
}

internal func validateImageString(value: String): Unit {
    if (value.contains("\0")) {
        throw IllegalArgumentException("Image paths and type hints must not contain NUL")
    }
}
