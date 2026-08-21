package sdl

/**
 * Throws `SdlException` when an SDL boolean result reports failure.
 */
internal func ensureSdl(ok: Bool, api: String): Unit {
    if (!ok) {
        throw SdlException("${api} failed: ${lastSdlError()}")
    }
}

/** Returns the linked SDL library version encoded as a single integer. */
public func sdlVersion(): Int32 {
    unsafe { SDL_GetVersion() }
}

/** Returns the linked SDL library revision string, or an empty string when it is unavailable. */
public func sdlRevision(): String {
    let revision = unsafe { SDL_GetRevision() }
    if (revision.isNull()) {
        ""
    } else {
        revision.toString()
    }
}

internal func lastSdlError(): String {
    let err = unsafe { SDL_GetError() }
    if (err.isNull()) {
        return "unknown SDL error"
    }
    unsafe { err.toString() }
}

/**
 * Throws `SdlException` when renderer defaults cannot be applied after window creation.
 */
internal func configureRenderer(window: CPointer<Unit>, renderer: CPointer<Unit>, scale: Float32, vsync: Bool): Unit {
    if (!unsafe { SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND) }) {
        destroyCreatedResources(window, renderer)
        throw SdlException("SDL_SetRenderDrawBlendMode failed: ${lastSdlError()}")
    }
    if (!unsafe { SDL_SetRenderScale(renderer, scale, scale) }) {
        destroyCreatedResources(window, renderer)
        throw SdlException("SDL_SetRenderScale failed: ${lastSdlError()}")
    }
    // 1 = sync to every vertical blank; 0 = SDL_RENDERER_VSYNC_DISABLED (uncapped present).
    let vsyncMode = if (vsync) {
        Int32(1)
    } else {
        Int32(0)
    }
    let _ = unsafe { SDL_SetRenderVSync(renderer, vsyncMode) } // cjcheck-ignore: ignore-result # vsync is a performance preference; a backend that refuses it still renders
}

/**
 * Releases partially-created SDL resources before propagating a setup failure.
 */
internal func destroyCreatedResources(window: CPointer<Unit>, renderer: CPointer<Unit>): Unit {
    if (renderer.isNotNull()) {
        unsafe { SDL_DestroyRenderer(renderer) }
    }
    if (window.isNotNull()) {
        unsafe { SDL_DestroyWindow(window) }
    }
    // Ref-counted quit: a failed second window must not tear the subsystem down under
    // an already-open one (SDL_Quit() would destroy its window and renderer too).
    unsafe { SDL_QuitSubSystem(SDL_INIT_VIDEO) }
}

internal func normalizedScale(scale: Float32): Float32 {
    if (scale <= 0.0) {
        1.0
    } else {
        scale
    }
}

internal func scaledDimension(value: Int32, scale: Float32): Int32 {
    Int32(Float32(value) * scale)
}
