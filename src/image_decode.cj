package sdl

private let CLOSE_IMAGE_STREAM_IN_DECODER = false

internal func loadImageFile(path: String, options: ImageLoadOptions): Surface {
    validateImageString(path)
    let cPath = unsafe { LibC.mallocCString(path) }
    var decoded = CPointer<Unit>()
    try (name = cPath.asResource()) {
        if (options.width == 0 && options.height == 0) {
            decoded = unsafe { IMG_Load(name.value) }
        } else {
            let cMode = unsafe { LibC.mallocCString("rb") }
            var stream = CPointer<Unit>()
            try (mode = cMode.asResource()) {
                stream = unsafe { SDL_IOFromFile(name.value, mode.value) }
            }
            decoded = decodeImageStream(stream, imagePathHint(path), options)
        }
    }
    finishImageDecode(decoded, options)
}

private func imagePathHint(path: String): String {
    let parts = path.split(".")
    if (parts.size > 1) {
        parts[parts.size - 1]
    } else {
        ""
    }
}

// Always consumes the stream, including SVG and failure paths. Capture decode errors before close.
private func decodeImageStream(stream: CPointer<Unit>, kind: String, options: ImageLoadOptions): CPointer<Unit> {
    if (stream.isNull()) {
        throw SdlException("Cannot open image stream: ${lastSdlError()}")
    }
    var decoded = CPointer<Unit>()
    try {
        if ((options.width > 0 || options.height > 0) && unsafe { IMG_isSVG(stream) }) {
            decoded = unsafe { IMG_LoadSizedSVG_IO(stream, options.width, options.height) }
        } else {
            let cKind = unsafe { LibC.mallocCString(kind) }
            try (hint = cKind.asResource()) {
                decoded = unsafe { IMG_LoadTyped_IO(stream, CLOSE_IMAGE_STREAM_IN_DECODER, hint.value) }
            }
        }
        if (decoded.isNull()) {
            throw SdlException("Image decode failed: ${lastSdlError()}")
        }
    } catch (error: Exception) {
        let _ = unsafe { SDL_CloseIO(stream) } // cjcheck-ignore: ignore-result # read-only stream cleanup preserves the original decode failure
        throw error
    }
    if (!unsafe { SDL_CloseIO(stream) }) {
        unsafe { SDL_DestroySurface(decoded) }
        throw SdlException("Cannot close image stream: ${lastSdlError()}")
    }
    decoded
}

internal func decodeImageBytes(bytes: Array<UInt8>, kind: String, options: ImageLoadOptions): Surface {
    validateImageString(kind)
    if (bytes.isEmpty()) {
        throw SdlException("Image data is empty")
    }
    // Copy during a short pin, then release the Cangjie array before calling arbitrary codecs.
    let native = unsafe { LibC.malloc<UInt8>(count: bytes.size) }
    if (native.isNull()) {
        throw SdlException("Cannot allocate encoded image buffer")
    }
    try {
        let count = UIntNative(bytes.size)
        let pinned = unsafe { acquireArrayRawData(bytes) }
        let _ = unsafe { memcpy(native, pinned.pointer, count) } // cjcheck-ignore: ignore-result # memcpy returns its already-owned destination; no managed allocation occurs while pinned
        unsafe { releaseArrayRawData(pinned) }
        let stream = unsafe { SDL_IOFromConstMem(CPointer<Unit>(native), UIntNative(bytes.size)) }
        let decoded = decodeImageStream(stream, kind, options)
        finishImageDecode(decoded, options)
    } finally {
        unsafe { LibC.free(native) }
    }
}

private func finishImageDecode(decoded: CPointer<Unit>, options: ImageLoadOptions): Surface {
    if (decoded.isNull()) {
        throw SdlException("Image decode failed: ${lastSdlError()}")
    }
    let image = Surface(decoded)
    try {
        let header = unsafe { CPointer<SdlSurfaceHeader>(decoded).read() }
        if (header.width <= 0 || header.height <= 0 || Int64(header.width) * Int64(header.height) > options.maxPixels) {
            throw SdlException("Decoded image dimensions exceed the pixel budget")
        }
        var scale: Float64 = 1.0
        if (options.width > 0) {
            scale = min(scale, Float64(options.width) / Float64(header.width))
        }
        if (options.height > 0) {
            scale = min(scale, Float64(options.height) / Float64(header.height))
        }
        if (scale >= 1.0) {
            return image
        }
        let resized = image.resized(max(Int32(1), Int32(Float64(header.width) * scale)),
            max(Int32(1), Int32(Float64(header.height) * scale)))
        image.close()
        resized
    } catch (error: Exception) {
        image.close()
        throw error
    }
}
