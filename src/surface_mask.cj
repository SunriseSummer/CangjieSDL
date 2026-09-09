package sdl

extend Surface {
    /**
     * Returns an independent RGBA32 white image with this surface's alpha coverage. Color-key and
     * palette transparency are converted by SDL before RGB is replaced. The input is unchanged.
     * Close the returned surface. Throws `SdlException` on closed input, conversion or lock failure.
     */
    public func alphaMask(): Surface {
        if (isClosed()) {
            throw SdlException("Surface is already closed.")
        }
        let converted = unsafe { SDL_ConvertSurface(ptr, SDL_PIXELFORMAT_RGBA32) }
        if (converted.isNull()) {
            throw SdlException("SDL_ConvertSurface failed: ${lastSdlError()}")
        }
        try {
            ensureSdl(unsafe { SDL_LockSurface(converted) }, "SDL_LockSurface")
            try {
                let header = unsafe { CPointer<SdlSurfaceHeader>(converted).read() }
                // RGBA32 is a byte-order format. Respect row pitch and preserve the fourth byte;
                // this loop has no per-pixel FFI calls and runs only when a mask enters the cache.
                if (header.width < 0 || header.height < 0 || Int64(header.pitch) < Int64(header.width) * 4 || (header
                    .width > 0 && header.height > 0 && header.pixels.isNull())) {
                    throw SdlException("SDL returned invalid RGBA surface storage")
                }
                for (rowIndex in 0..Int64(header.height)) {
                    let row = rowIndex * Int64(header.pitch)
                    for (pixelIndex in 0..Int64(header.width)) {
                        let offset = row + pixelIndex * 4
                        unsafe { header.pixels.write(offset, UInt8(255)) }
                        unsafe { header.pixels.write(offset + 1, UInt8(255)) }
                        unsafe { header.pixels.write(offset + 2, UInt8(255)) }
                    }
                }
            } finally {
                unsafe { SDL_UnlockSurface(converted) }
            }
            Surface(converted)
        } catch (error: Exception) {
            unsafe { SDL_DestroySurface(converted) }
            throw error
        }
    }
}
