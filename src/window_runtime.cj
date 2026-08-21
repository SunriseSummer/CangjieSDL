package sdl

extend SdlWindow {
    /** Returns the current window title, or an empty string when SDL reports none. */
    public func title(): String {
        let value = unsafe { SDL_GetWindowTitle(windowPtr) }
        if (value.isNull()) {
            ""
        } else {
            value.toString()
        }
    }

    /** Returns the window's current state flags decoded into a `WindowFlags` value. */
    public func windowFlags(): WindowFlags {
        windowFlagsFromRaw(unsafe { SDL_GetWindowFlags(windowPtr) })
    }

    /*
     * Returns the window's client area size in actual pixels (unaffected by `scale`; larger than
     * the logical size on high-DPI displays). Throws `SdlException` on failure.
     */
    public func sizeInPixels(): Size {
        var w: Int32 = 0
        var h: Int32 = 0
        ensureSdl(unsafe { SDL_GetWindowSizeInPixels(windowPtr, inout w, inout h) }, "SDL_GetWindowSizeInPixels")
        Size(Float32(w), Float32(h))
    }

    /*
     * Returns the region of the window guaranteed free of system obstructions (notches, system
     * bars), in window coordinates. Throws `SdlException` on failure.
     */
    public func safeArea(): Rect {
        var raw = SdlRect()
        ensureSdl(unsafe { SDL_GetWindowSafeArea(windowPtr, inout raw) }, "SDL_GetWindowSafeArea")
        rectFromSdlRect(raw)
    }

    /** Returns the window's minimum resize limit in logical pixels. Throws `SdlException` on failure. */
    public func minimumSize(): Size {
        var w: Int32 = 0
        var h: Int32 = 0
        ensureSdl(unsafe { SDL_GetWindowMinimumSize(windowPtr, inout w, inout h) }, "SDL_GetWindowMinimumSize")
        windowSizeFromPixels(w, h, scale)
    }

    /** Returns the window's maximum resize limit in logical pixels. Throws `SdlException` on failure. */
    public func maximumSize(): Size {
        var w: Int32 = 0
        var h: Int32 = 0
        ensureSdl(unsafe { SDL_GetWindowMaximumSize(windowPtr, inout w, inout h) }, "SDL_GetWindowMaximumSize")
        windowSizeFromPixels(w, h, scale)
    }

    /*
     * Returns the thickness of the window decorations (title bar and borders) around the client
     * area, in window pixels. Throws `SdlException` on failure.
     */
    public func borderSize(): WindowBorderSize {
        var top: Int32 = 0
        var left: Int32 = 0
        var bottom: Int32 = 0
        var right: Int32 = 0
        ensureSdl(unsafe {
            SDL_GetWindowBordersSize(windowPtr, inout top, inout left, inout bottom, inout right)
        }, "SDL_GetWindowBordersSize")
        WindowBorderSize(top, left, bottom, right)
    }

    /*
     * Constrains user resizes to keep width/height between the given aspect ratios (0 disables a
     * bound). Throws `SdlException` when a bound is negative, minimum exceeds maximum, or SDL
     * rejects the call.
     */
    public func setAspectRatio(minimum: Float32, maximum: Float32): Unit {
        validateWindowAspectRatio(minimum, maximum)
        ensureSdl(unsafe { SDL_SetWindowAspectRatio(windowPtr, minimum, maximum) }, "SDL_SetWindowAspectRatio")
    }

    /** Returns the window's current aspect ratio bounds. Throws `SdlException` on failure. */
    public func aspectRatio(): WindowAspectRatio {
        var minimum: Float32 = 0.0
        var maximum: Float32 = 0.0
        ensureSdl(unsafe { SDL_GetWindowAspectRatio(windowPtr, inout minimum, inout maximum) },
            "SDL_GetWindowAspectRatio")
        WindowAspectRatio(minimum, maximum)
    }

    /**
     * Throws `SdlException` when SDL cannot query the window opacity.
     */
    public func opacity(): Float32 {
        let value = unsafe { SDL_GetWindowOpacity(windowPtr) }
        if (value < 0.0) {
            throw SdlException("SDL_GetWindowOpacity failed: ${lastSdlError()}")
        }
        value
    }

    /*
     * Returns the ratio of actual pixels to window coordinates (e.g. 2.0 on a Retina display).
     * Throws `SdlException` when SDL reports an invalid value.
     */
    public func pixelDensity(): Float32 {
        positiveWindowFloat(unsafe { SDL_GetWindowPixelDensity(windowPtr) }, "SDL_GetWindowPixelDensity")
    }

    /*
     * Returns the content scale expected on the window's current display (pixel density combined
     * with the user's display scale setting). Throws `SdlException` when SDL reports an invalid
     * value.
     */
    public func displayScale(): Float32 {
        positiveWindowFloat(unsafe { SDL_GetWindowDisplayScale(windowPtr) }, "SDL_GetWindowDisplayScale")
    }

    /*
     * Requests that the window fill the browser document when running under Emscripten; a no-op
     * on other platforms. Throws `SdlException` on failure.
     */
    public func setFillDocument(fill: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowFillDocument(windowPtr, fill) }, "SDL_SetWindowFillDocument")
    }

    /*
     * Grabs or releases exclusive keyboard input, routing system shortcuts to this window.
     * Throws `SdlException` on failure.
     */
    public func setKeyboardGrab(grabbed: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowKeyboardGrab(windowPtr, grabbed) }, "SDL_SetWindowKeyboardGrab")
    }

    /** Confines the mouse cursor to the window, or releases it. Throws `SdlException` on failure. */
    public func setMouseGrab(grabbed: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowMouseGrab(windowPtr, grabbed) }, "SDL_SetWindowMouseGrab")
    }

    /** Whether this window currently holds the keyboard grab. */
    public func keyboardGrabbed(): Bool {
        unsafe { SDL_GetWindowKeyboardGrab(windowPtr) }
    }

    /** Whether this window currently holds the mouse grab. */
    public func mouseGrabbed(): Bool {
        unsafe { SDL_GetWindowMouseGrab(windowPtr) }
    }

    /*
     * Confines the mouse cursor to a rectangle within the window while the mouse grab is active;
     * `None` removes the confinement rectangle. Throws `SdlException` on failure.
     */
    public func setMouseGrabRect(rect: ?Rect): Unit {
        match (rect) {
            case Some(value) =>
                var raw = value.toSdlRect()
                ensureSdl(unsafe { SDL_SetWindowMouseRect(windowPtr, inout raw) }, "SDL_SetWindowMouseRect")
            case None => ensureSdl(unsafe { SDL_SetWindowMouseRect(windowPtr, CPointer<SdlRect>()) },
                "SDL_SetWindowMouseRect")
        }
    }

    /** Returns the mouse confinement rectangle, or `None` when no rectangle is set. */
    public func mouseGrabRect(): ?Rect {
        let raw = unsafe { SDL_GetWindowMouseRect(windowPtr) }
        if (raw.isNull()) {
            None
        } else {
            Some(rectFromSdlRect(unsafe { raw.read() }))
        }
    }

    /** Allows or forbids the window to receive input focus. Throws `SdlException` on failure. */
    public func setFocusable(focusable: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowFocusable(windowPtr, focusable) }, "SDL_SetWindowFocusable")
    }

    /*
     * Opens the platform window-manager menu (move/resize/minimize commands) at the given window
     * coordinates. Throws `SdlException` on failure.
     */
    public func showSystemMenu(x: Int32, y: Int32): Unit {
        ensureSdl(unsafe { SDL_ShowWindowSystemMenu(windowPtr, x, y) }, "SDL_ShowWindowSystemMenu")
    }

    /*
     * Sets the progress display mode shown on the window's taskbar entry. Throws `SdlException`
     * on failure.
     */
    public func setProgressState(state: WindowProgressState): Unit {
        ensureSdl(unsafe { SDL_SetWindowProgressState(windowPtr, windowProgressStateCode(state)) },
            "SDL_SetWindowProgressState")
    }

    /**
     * Throws `SdlException` when SDL cannot query the native taskbar progress state.
     */
    public func progressState(): WindowProgressState {
        let code = unsafe { SDL_GetWindowProgressState(windowPtr) }
        match (windowProgressStateFromCode(code)) {
            case Some(state) => state
            case None => throw SdlException("SDL_GetWindowProgressState failed: ${lastSdlError()}")
        }
    }

    /*
     * Sets the taskbar progress fraction; the value is clamped to [0.0, 1.0] before being passed
     * to SDL. Throws `SdlException` on failure.
     */
    public func setProgressValue(value: Float32): Unit {
        ensureSdl(unsafe { SDL_SetWindowProgressValue(windowPtr, clampF32(value, 0.0, 1.0)) },
            "SDL_SetWindowProgressValue")
    }

    /**
     * Throws `SdlException` when SDL cannot query the native taskbar progress value.
     */
    public func progressValue(): Float32 {
        let value = unsafe { SDL_GetWindowProgressValue(windowPtr) }
        if (value < 0.0) {
            throw SdlException("SDL_GetWindowProgressValue failed: ${lastSdlError()}")
        }
        value
    }
}

/**
 * Throws `SdlException` when SDL reports an invalid floating-point window query result.
 */
private func positiveWindowFloat(value: Float32, api: String): Float32 {
    if (value <= 0.0) {
        throw SdlException("${api} failed: ${lastSdlError()}")
    }
    value
}
