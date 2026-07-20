package sdl

/**
 * A keyboard key decoded from the SDL scancode — physical, layout-independent keys. `Letter` carries
 * the uppercase ASCII code (A-Z) and `Digit` the ASCII digit code ('0'-'9'); anything unmapped
 * arrives as `RawScancode`, so no press is dropped. Printable text does not come through here — it
 * arrives already composed (IME included) as `UiEvent.TextInput`.
 */
public enum Key {
    | Escape
    | Backspace
    | Enter
    | Tab
    | Delete
    | Space
    | Home
    | End
    | Left
    | Right
    | Up
    | Down
    | Letter(UInt8)
    | Digit(UInt8)
    | RawScancode(Int32)
}

/** A decoded mouse button; buttons beyond left/middle/right arrive as `RawCode` with SDL's code. */
public enum MouseButton {
    | Left
    | Middle
    | Right
    | RawCode(UInt8)
}

/**
 * Frame timing in milliseconds: `elapsedMs` since SDL initialization and `deltaMs` since the previous
 * frame. Animations advance by `deltaMs`, so their speed is independent of the frame rate.
 */
public struct FrameInfo {
    public let elapsedMs: UInt64
    public let deltaMs: UInt64

    public init(elapsedMs: UInt64, deltaMs: UInt64) {
        this.elapsedMs = elapsedMs
        this.deltaMs = deltaMs
    }
}

/*
 * A decoded SDL input event, offered to `Widget.handle` in arrival order. Pointer coordinates are in
 * logical pixels — the window divides out its scale, so events land in the same space as layout and
 * drawing. `MouseWheel`'s payload order is (wheelX, wheelY, mouseX, mouseY): the two SCROLL DELTAS
 * first, then the pointer position — destructuring it position-first silently turns scrolling into
 * hit testing. `KeyDown`'s `Bool` is the key-repeat flag. `Frame` is synthesized by the shell once
 * per rendered frame rather than polled from SDL; `Unknown` carries the raw SDL event type of
 * anything not decoded.
 */
public enum UiEvent {
    | Frame(FrameInfo)
    | Quit
    | WindowResized(Int32, Int32)
    | KeyDown(Key, Bool)
    | KeyUp(Key)
    | TextInput(String)
    | MouseMove(Float32, Float32)
    | MouseDown(MouseButton, Float32, Float32)
    | MouseUp(MouseButton, Float32, Float32)
    | MouseWheel(Float32, Float32, Float32, Float32)
    | DropBegin
    | DropFile(String, Float32, Float32)
    | DropText(String, Float32, Float32)
    | DropPosition(Float32, Float32)
    | DropComplete
    | Unknown(UInt32)
}

internal func decodeEvent(raw: SdlEvent): UiEvent {
    let eventPtr = unsafe { LibC.malloc<SdlEvent>() }
    var decoded = UiEvent.Unknown(UInt32(0))
    try (eventResource = eventPtr.asResource()) {
        unsafe { eventResource.value.write(raw) }
        let common = unsafe { CPointer<SdlCommonEvent>(eventResource.value).read() }
        let eventType = common.eventType

        // Only SDL_EVENT_QUIT ends the app. For a single-window desktop app SDL raises
        // it when the last window's close button is pressed. SDL_EVENT_WINDOW_CLOSE_REQUESTED
        // is intentionally NOT treated as quit: Windows can emit a spurious close request
        // during window creation, which would otherwise flash the window shut on startup.
        if (eventType == SDL_EVENT_QUIT) {
            decoded = UiEvent.Quit
        } else if (eventType == SDL_EVENT_WINDOW_RESIZED) {
            let window = unsafe { CPointer<SdlWindowEvent>(eventResource.value).read() }
            decoded = UiEvent.WindowResized(window.data1, window.data2)
        } else if (eventType == SDL_EVENT_KEY_DOWN || eventType == SDL_EVENT_KEY_UP) {
            let keyEvent = unsafe { CPointer<SdlKeyboardEvent>(eventResource.value).read() }
            if (eventType == SDL_EVENT_KEY_DOWN) {
                decoded = UiEvent.KeyDown(keyFromScancode(keyEvent.scancode), keyEvent.repeat)
            } else {
                decoded = UiEvent.KeyUp(keyFromScancode(keyEvent.scancode))
            }
        } else if (eventType == SDL_EVENT_TEXT_INPUT) {
            let text = unsafe { CPointer<SdlTextInputEvent>(eventResource.value).read() }
            if (text.text.isNull()) {
                decoded = UiEvent.TextInput("")
            } else {
                decoded = UiEvent.TextInput(CString(text.text).toString())
            }
        } else if (eventType == SDL_EVENT_MOUSE_MOTION) {
            let motion = unsafe { CPointer<SdlMouseMotionEvent>(eventResource.value).read() }
            decoded = UiEvent.MouseMove(motion.x, motion.y)
        } else if (eventType == SDL_EVENT_MOUSE_BUTTON_DOWN || eventType == SDL_EVENT_MOUSE_BUTTON_UP) {
            let button = unsafe { CPointer<SdlMouseButtonEvent>(eventResource.value).read() }
            if (eventType == SDL_EVENT_MOUSE_BUTTON_DOWN) {
                decoded = UiEvent.MouseDown(buttonFromCode(button.button), button.x, button.y)
            } else {
                decoded = UiEvent.MouseUp(buttonFromCode(button.button), button.x, button.y)
            }
        } else if (eventType == SDL_EVENT_MOUSE_WHEEL) {
            let wheel = unsafe { CPointer<SdlMouseWheelEvent>(eventResource.value).read() }
            decoded = UiEvent.MouseWheel(wheel.x, wheel.y, wheel.mouseX, wheel.mouseY)
        } else if (isDropEvent(eventType)) {
            let drop = unsafe { CPointer<SdlDropEvent>(eventResource.value).read() }
            decoded = decodeDropEvent(eventType, drop)
        } else {
            decoded = UiEvent.Unknown(eventType)
        }
    }
    decoded
}

internal func scaleEventCoordinates(event: UiEvent, scale: Float32): UiEvent {
    if (scale == 1.0) {
        return event
    }
    match (event) {
        case UiEvent.MouseMove(x, y) => UiEvent.MouseMove(x / scale, y / scale)
        case UiEvent.MouseDown(button, x, y) => UiEvent.MouseDown(button, x / scale, y / scale)
        case UiEvent.MouseUp(button, x, y) => UiEvent.MouseUp(button, x / scale, y / scale)
        case UiEvent.MouseWheel(dx, dy, x, y) => UiEvent.MouseWheel(dx, dy, x / scale, y / scale)
        case UiEvent.DropFile(path, x, y) => UiEvent.DropFile(path, x / scale, y / scale)
        case UiEvent.DropText(text, x, y) => UiEvent.DropText(text, x / scale, y / scale)
        case UiEvent.DropPosition(x, y) => UiEvent.DropPosition(x / scale, y / scale)
        case _ => event
    }
}

internal func isDropEvent(eventType: UInt32): Bool {
    eventType == SDL_EVENT_DROP_FILE || eventType == SDL_EVENT_DROP_TEXT || eventType == SDL_EVENT_DROP_BEGIN ||
        eventType == SDL_EVENT_DROP_COMPLETE || eventType == SDL_EVENT_DROP_POSITION
}

internal func decodeDropEvent(eventType: UInt32, drop: SdlDropEvent): UiEvent {
    if (eventType == SDL_EVENT_DROP_FILE) {
        UiEvent.DropFile(dropData(drop), drop.x, drop.y)
    } else if (eventType == SDL_EVENT_DROP_TEXT) {
        UiEvent.DropText(dropData(drop), drop.x, drop.y)
    } else if (eventType == SDL_EVENT_DROP_POSITION) {
        UiEvent.DropPosition(drop.x, drop.y)
    } else if (eventType == SDL_EVENT_DROP_BEGIN) {
        UiEvent.DropBegin
    } else {
        UiEvent.DropComplete
    }
}

private func dropData(drop: SdlDropEvent): String {
    if (drop.data.isNull()) {
        ""
    } else {
        CString(drop.data).toString()
    }
}

internal func keyFromScancode(scancode: Int32): Key {
    if (scancode >= SDL_SCANCODE_A && scancode <= SDL_SCANCODE_Z) {
        Key.Letter(UInt8(scancode - SDL_SCANCODE_A + 65))
    } else if (scancode >= SDL_SCANCODE_1 && scancode <= SDL_SCANCODE_0) {
        if (scancode == SDL_SCANCODE_0) {
            Key.Digit(UInt8(48))
        } else {
            Key.Digit(UInt8(scancode - SDL_SCANCODE_1 + 49))
        }
    } else if (scancode == SDL_SCANCODE_ESCAPE) {
        Key.Escape
    } else if (scancode == SDL_SCANCODE_BACKSPACE) {
        Key.Backspace
    } else if (scancode == SDL_SCANCODE_RETURN) {
        Key.Enter
    } else if (scancode == SDL_SCANCODE_TAB) {
        Key.Tab
    } else if (scancode == SDL_SCANCODE_DELETE) {
        Key.Delete
    } else if (scancode == SDL_SCANCODE_SPACE) {
        Key.Space
    } else if (scancode == SDL_SCANCODE_HOME) {
        Key.Home
    } else if (scancode == SDL_SCANCODE_END) {
        Key.End
    } else if (scancode == SDL_SCANCODE_RIGHT) {
        Key.Right
    } else if (scancode == SDL_SCANCODE_LEFT) {
        Key.Left
    } else if (scancode == SDL_SCANCODE_DOWN) {
        Key.Down
    } else if (scancode == SDL_SCANCODE_UP) {
        Key.Up
    } else {
        Key.RawScancode(scancode)
    }
}

internal func buttonFromCode(button: UInt8): MouseButton {
    if (button == SDL_BUTTON_LEFT) {
        MouseButton.Left
    } else if (button == SDL_BUTTON_MIDDLE) {
        MouseButton.Middle
    } else if (button == SDL_BUTTON_RIGHT) {
        MouseButton.Right
    } else {
        MouseButton.RawCode(button)
    }
}
