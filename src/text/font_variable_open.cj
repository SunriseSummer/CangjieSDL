package sdl.text

// Uses the documented FreeType named-instance face index through official SDL_ttf properties.
// Both returned handles belong to the caller: close the font first, then the optional stream.
internal func openVariableNativeFont(source: NativeFontSource, size: Float32): (CPointer<Unit>, CPointer<Unit>) {
    let metadata = sfntSourceInfo(source)
    let face = sfntFile(source.path).faces[source.faceIndex & 65535]
    for (member in face.members) {
        if (sameFontCoordinates(member.coordinates, metadata.coordinates)) {
            let path = unsafe { LibC.mallocCString(source.path) }
            try (resource = path.asResource()) {
                return (openCollectionFace(resource.value, member.source.faceIndex, size), CPointer<Unit>())
            }
        }
    }
    let view = SfntView(source, metadata)
    openNativeFontView(source.path, size, view, 65536)
}

internal func openNativeFontView(path: String, size: Float32, view: SfntView, faceIndex: Int64): (CPointer<Unit>, 
    CPointer<Unit>) {
    let stream = openFontView(path, view)
    var properties: UInt32 = 0
    try {
        properties = unsafe { SDL_CreateProperties() }
        if (properties == 0) {
            throw NativeTextException("Cannot allocate variable font properties")
        }
        let streamName = unsafe { LibC.mallocCString("SDL_ttf.font.create.iostream") }
        let faceName = unsafe { LibC.mallocCString("SDL_ttf.font.create.face") }
        let sizeName = unsafe { LibC.mallocCString("SDL_ttf.font.create.size") }
        try (streamKey = streamName.asResource(), faceKey = faceName.asResource(), sizeKey = sizeName.asResource()) {
            if (!unsafe { SDL_SetPointerProperty(properties, streamKey.value, stream) } ||
                !unsafe { SDL_SetNumberProperty(properties, faceKey.value, faceIndex) } ||
                !unsafe { SDL_SetFloatProperty(properties, sizeKey.value, size) }) {
                throw NativeTextException("Cannot set variable font properties")
            }
        }
        let font = unsafe { TTF_OpenFontWithProperties(properties) }
        if (font.isNull()) {
            throw NativeTextException("Cannot open variable font view: ${lastNativeError()}")
        }
        (font, stream)
    } catch (error: Exception) {
        let _ = closeFontView(stream) // cjcheck-ignore: ignore-result # closing a read-only stream during failure cleanup; preserve the opening error
        throw error
    } finally {
        if (properties != 0) {
            unsafe { SDL_DestroyProperties(properties) }
        }
    }
}

private func sameFontCoordinates(left: Array<NativeFontCoordinate>, right: Array<NativeFontCoordinate>): Bool {
    if (left.size != right.size) {
        return false
    }
    for (i in 0..left.size) {
        if (left[i].tagCode != right[i].tagCode || left[i].value != right[i].value) {
            return false
        }
    }
    true
}

protected func nativeFontVariationsAvailable(): Bool {
    unsafe { TTF_Version() } >= 3002000
}
