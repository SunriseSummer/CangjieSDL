package sdl

extend SdlWindow {
    /** Moves the window to the given screen coordinates. Throws `SdlException` on failure. */
    public func setPosition(x: Int32, y: Int32): Unit {
        ensureSdl(unsafe { SDL_SetWindowPosition(windowPtr, x, y) }, "SDL_SetWindowPosition")
    }

    /** Returns the window's current screen coordinates. Throws `SdlException` on failure. */
    public func position(): WindowPosition {
        var x: Int32 = 0
        var y: Int32 = 0
        ensureSdl(unsafe { SDL_GetWindowPosition(windowPtr, inout x, inout y) }, "SDL_GetWindowPosition")
        WindowPosition(x, y)
    }

    /*
     * Sets the smallest size the user may resize the window to, in logical pixels (converted to
     * window pixels via `scale`). Throws `SdlException` on failure.
     */
    public func setMinimumSize(width: Int32, height: Int32): Unit {
        ensureSdl(unsafe {
            SDL_SetWindowMinimumSize(windowPtr, scaledDimension(width, scale), scaledDimension(height, scale))
        }, "SDL_SetWindowMinimumSize")
    }

    /*
     * Sets the largest size the user may resize the window to, in logical pixels (converted to
     * window pixels via `scale`). Throws `SdlException` on failure.
     */
    public func setMaximumSize(width: Int32, height: Int32): Unit {
        ensureSdl(unsafe {
            SDL_SetWindowMaximumSize(windowPtr, scaledDimension(width, scale), scaledDimension(height, scale))
        }, "SDL_SetWindowMaximumSize")
    }

    /** Shows or removes the window's border decorations. Throws `SdlException` on failure. */
    public func setBordered(bordered: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowBordered(windowPtr, bordered) }, "SDL_SetWindowBordered")
    }

    /** Allows or forbids the user to resize the window. Throws `SdlException` on failure. */
    public func setResizable(resizable: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowResizable(windowPtr, resizable) }, "SDL_SetWindowResizable")
    }

    /** Keeps the window above all other windows, or releases it. Throws `SdlException` on failure. */
    public func setAlwaysOnTop(onTop: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowAlwaysOnTop(windowPtr, onTop) }, "SDL_SetWindowAlwaysOnTop")
    }

    /*
     * Sets the whole-window opacity; the value is clamped to [0.0, 1.0] before being passed to
     * SDL. Throws `SdlException` on failure.
     */
    public func setOpacity(opacity: Float32): Unit {
        let value = clampF32(opacity, 0.0, 1.0)
        ensureSdl(unsafe { SDL_SetWindowOpacity(windowPtr, value) }, "SDL_SetWindowOpacity")
    }

    /** Makes a hidden window visible. Throws `SdlException` on failure. */
    public func show(): Unit {
        ensureSdl(unsafe { SDL_ShowWindow(windowPtr) }, "SDL_ShowWindow")
    }

    /** Hides the window from the screen. Throws `SdlException` on failure. */
    public func hide(): Unit {
        ensureSdl(unsafe { SDL_HideWindow(windowPtr) }, "SDL_HideWindow")
    }

    /** Brings the window above other windows and requests input focus. Throws `SdlException` on failure. */
    public func raiseWindow(): Unit {
        ensureSdl(unsafe { SDL_RaiseWindow(windowPtr) }, "SDL_RaiseWindow")
    }

    /** Makes the window as large as possible without going fullscreen. Throws `SdlException` on failure. */
    public func maximize(): Unit {
        ensureSdl(unsafe { SDL_MaximizeWindow(windowPtr) }, "SDL_MaximizeWindow")
    }

    /** Shrinks the window to an iconic representation (taskbar/dock). Throws `SdlException` on failure. */
    public func minimize(): Unit {
        ensureSdl(unsafe { SDL_MinimizeWindow(windowPtr) }, "SDL_MinimizeWindow")
    }

    /** Returns a minimized or maximized window to its previous size and position. Throws `SdlException` on failure. */
    public func restore(): Unit {
        ensureSdl(unsafe { SDL_RestoreWindow(windowPtr) }, "SDL_RestoreWindow")
    }

    /** Enters or leaves fullscreen mode. Throws `SdlException` on failure. */
    public func setFullscreen(fullscreen: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowFullscreen(windowPtr, fullscreen) }, "SDL_SetWindowFullscreen")
    }

    /*
     * Blocks until any pending asynchronous window state change (size, position, fullscreen,
     * minimize/maximize) has been applied by the window system. Throws `SdlException` on failure.
     */
    public func sync(): Unit {
        ensureSdl(unsafe { SDL_SyncWindow(windowPtr) }, "SDL_SyncWindow")
    }

    /** Requests the user's attention by flashing the window per `operation`. Throws `SdlException` on failure. */
    public func flash(operation!: WindowFlash = WindowFlash.Briefly): Unit {
        ensureSdl(unsafe { SDL_FlashWindow(windowPtr, flashCode(operation)) }, "SDL_FlashWindow")
    }

    /*
     * Enables or disables relative mouse mode for this window: the cursor is hidden and confined
     * while mouse events report relative motion deltas. Throws `SdlException` on failure.
     */
    public func setRelativeMouseMode(enabled: Bool): Unit {
        ensureSdl(unsafe { SDL_SetWindowRelativeMouseMode(windowPtr, enabled) }, "SDL_SetWindowRelativeMouseMode")
    }
}

private func flashCode(operation: WindowFlash): Int32 {
    match (operation) {
        case WindowFlash.Cancel => 0
        case WindowFlash.Briefly => 1
        case WindowFlash.UntilFocused => 2
    }
}
