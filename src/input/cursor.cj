package sdl.input

import sdl.{SdlException, ensureSdl, lastSdlError}

/** The standard OS cursor shapes SDL can create (arrow, text beam, resize arrows, and so on). */
public enum SystemCursor {
    | Default
    | Text
    | Wait
    | Crosshair
    | Progress
    | NwseResize
    | NeswResize
    | EwResize
    | NsResize
    | Move
    | NotAllowed
    | Pointer
    | NwResize
    | NResize
    | NeResize
    | EResize
    | SeResize
    | SResize
    | SwResize
    | WResize
}

/**
 * An owned native mouse cursor; create one with `system`, activate it with `setActive`,
 * and release it with `close` (which restores the default cursor).
 */
public class Cursor <: Resource {
    private let ptr: CPointer<Unit>
    private var closed = false

    private init(ptr: CPointer<Unit>) {
        this.ptr = ptr
    }

    /**
     * Throws `SdlException` when SDL cannot create the requested native system cursor.
     */
    public static func system(kind: SystemCursor): Cursor {
        let cursor = unsafe { SDL_CreateSystemCursor(systemCursorCode(kind)) }
        if (cursor.isNull()) {
            throw SdlException("SDL_CreateSystemCursor failed: ${lastSdlError()}")
        }
        Cursor(cursor)
    }

    /**
     * Throws `SdlException` when a closed cursor is reused or SDL cannot activate it.
     */
    public func setActive(): Unit {
        ensureOpen()
        ensureSdl(unsafe { SDL_SetCursor(ptr) }, "SDL_SetCursor")
    }

    /** Whether this cursor has been closed and can no longer be activated. */
    public func isClosed(): Bool {
        closed
    }

    /** Destroys the native cursor, restoring the default cursor first; safe to call more than once. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        if (ptr.isNotNull()) {
            let defaultCursor = unsafe { SDL_GetDefaultCursor() }
            if (defaultCursor.isNotNull()) {
                let _ = unsafe { SDL_SetCursor(defaultCursor) } // cjcheck-ignore: ignore-result # shutdown path is best-effort: the resource is being destroyed regardless
            }
            unsafe { SDL_DestroyCursor(ptr) }
        }
    }

    /**
     * Throws `SdlException` when SDL cannot show the OS cursor.
     */
    public static func show(): Unit {
        ensureSdl(unsafe { SDL_ShowCursor() }, "SDL_ShowCursor")
    }

    /**
     * Throws `SdlException` when SDL cannot hide the OS cursor.
     */
    public static func hide(): Unit {
        ensureSdl(unsafe { SDL_HideCursor() }, "SDL_HideCursor")
    }

    /** Whether the OS cursor is currently shown. */
    public static func isVisible(): Bool {
        unsafe { SDL_CursorVisible() }
    }

    /**
     * Throws `SdlException` when a closed cursor is reused.
     */
    private func ensureOpen(): Unit {
        if (closed) {
            throw SdlException("Cursor is already closed.")
        }
    }
}

internal func systemCursorCode(kind: SystemCursor): Int32 {
    match (kind) {
        case SystemCursor.Default => 0
        case SystemCursor.Text => 1
        case SystemCursor.Wait => 2
        case SystemCursor.Crosshair => 3
        case SystemCursor.Progress => 4
        case SystemCursor.NwseResize => 5
        case SystemCursor.NeswResize => 6
        case SystemCursor.EwResize => 7
        case SystemCursor.NsResize => 8
        case SystemCursor.Move => 9
        case SystemCursor.NotAllowed => 10
        case SystemCursor.Pointer => 11
        case SystemCursor.NwResize => 12
        case SystemCursor.NResize => 13
        case SystemCursor.NeResize => 14
        case SystemCursor.EResize => 15
        case SystemCursor.SeResize => 16
        case SystemCursor.SResize => 17
        case SystemCursor.SwResize => 18
        case SystemCursor.WResize => 19
    }
}
