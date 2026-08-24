package sdl

import std.collection.ArrayList

private let EVENT_KMOD_LSHIFT: UInt16 = UInt16(0x0001)
private let EVENT_KMOD_RSHIFT: UInt16 = UInt16(0x0002)
private let EVENT_KMOD_LCTRL: UInt16 = UInt16(0x0040)
private let EVENT_KMOD_RCTRL: UInt16 = UInt16(0x0080)
private let EVENT_KMOD_LALT: UInt16 = UInt16(0x0100)
private let EVENT_KMOD_RALT: UInt16 = UInt16(0x0200)
private let EVENT_KMOD_LGUI: UInt16 = UInt16(0x0400)
private let EVENT_KMOD_RGUI: UInt16 = UInt16(0x0800)
private let ASCII_DIGIT_ZERO: UInt32 = UInt32(48)
private let ASCII_DIGIT_NINE: UInt32 = UInt32(57)
private let ASCII_UPPER_A: UInt32 = UInt32(65)
private let ASCII_UPPER_Z: UInt32 = UInt32(90)
private let ASCII_LOWER_A: UInt32 = UInt32(97)
private let ASCII_LOWER_Z: UInt32 = UInt32(122)

/**
 * A decoded keyboard key. Letter and digit variants prefer SDL's logical keycode, so shortcuts
 * follow the active layout; navigation keys fall back to the physical scancode. Unmapped physical
 * keys arrive as `RawScancode`, so no press is dropped. Composed printable text (IME included)
 * arrives separately as `UiEvent.TextInput`. `UiEventMetadata` preserves both native identities.
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

/** Modifier keys captured at the instant SDL created a keyboard event. */
public struct EventKeyModifiers {
    public let raw: UInt16
    public let shift: Bool
    public let ctrl: Bool
    public let alt: Bool
    public let gui: Bool
    public let command: Bool

    public init(raw!: UInt16 = UInt16(0)) {
        this.raw = raw
        this.shift = eventModifierHas(raw, EVENT_KMOD_LSHIFT) || eventModifierHas(raw, EVENT_KMOD_RSHIFT)
        this.ctrl = eventModifierHas(raw, EVENT_KMOD_LCTRL) || eventModifierHas(raw, EVENT_KMOD_RCTRL)
        this.alt = eventModifierHas(raw, EVENT_KMOD_LALT) || eventModifierHas(raw, EVENT_KMOD_RALT)
        this.gui = eventModifierHas(raw, EVENT_KMOD_LGUI) || eventModifierHas(raw, EVENT_KMOD_RGUI)
        this.command = ctrl || gui
    }
}

/** Stable metadata copied from the native event before SDL reuses its queue storage. */
public struct UiEventMetadata {
    public let timestampNs: UInt64
    public let windowId: UInt32
    public let physicalScancode: Int32
    public let logicalKeycode: UInt32
    public let modifiers: EventKeyModifiers

    public init(
        timestampNs!: UInt64 = UInt64(0),
        windowId!: UInt32 = UInt32(0),
        physicalScancode!: Int32 = 0,
        logicalKeycode!: UInt32 = UInt32(0),
        modifiers!: EventKeyModifiers = EventKeyModifiers()
    ) {
        this.timestampNs = timestampNs
        this.windowId = windowId
        this.physicalScancode = physicalScancode
        this.logicalKeycode = logicalKeycode
        this.modifiers = modifiers
    }
}

/** One decoded UI event together with its event-time window, timestamp, key, and modifier data. */
public struct UiEventRecord {
    public let event: UiEvent
    public let metadata: UiEventMetadata

    public init(event: UiEvent) {
        this(event, UiEventMetadata())
    }

    public init(event: UiEvent, metadata: UiEventMetadata) {
        this.event = event
        this.metadata = metadata
    }
}

/*
 * A decoded SDL input event, offered to `Widget.handle` in arrival order. Pointer coordinates are in
 * logical pixels — the window divides out its scale, so events land in the same space as layout and
 * drawing. `MouseWheel`'s payload order is (wheelX, wheelY, mouseX, mouseY): the two SCROLL DELTAS
 * first, then the pointer position — destructuring it position-first silently turns scrolling into
 * hit testing. `KeyDown`'s `Bool` is the key-repeat flag. `Frame` is synthesized by the shell once
 * per rendered frame rather than polled from SDL; `Unknown` carries the raw SDL event type of
 * anything not decoded. `Wake` is an internal-loop signal posted from another thread; custom
 * shells may safely ignore it.
 */
public enum UiEvent {
    | Frame(FrameInfo)
    | Wake
    | Quit
    | WindowExposed
    | WindowResized(Int32, Int32)
    | WindowPixelSizeChanged(Int32, Int32)
    | WindowDisplayScaleChanged
    | WindowMinimized
    | WindowRestored
    | WindowFocusGained
    | WindowFocusLost
    | WindowCloseRequested
    | WindowOccluded
    | KeyDown(Key, Bool)
    | KeyUp(Key)
    | TextEditing(String, Int32, Int32)
    | TextEditingCandidates(Array<String>, Int32, Bool)
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
    | RenderTargetsReset
    | RenderDeviceReset
    | RenderDeviceLost
    | Unknown(UInt32)
}

internal func decodeEvent(raw: SdlEvent): UiEvent {
    decodeEventRecord(raw).event
}

internal func decodeEventRecord(raw: SdlEvent): UiEventRecord { // cjcheck-ignore: long-function # flat one-branch-per-SDL-event-type decode table; each arm is a single struct read
    let eventPtr = unsafe { LibC.malloc<SdlEvent>() }
    var record = UiEventRecord(UiEvent.Unknown(UInt32(0)))
    try (eventResource = eventPtr.asResource()) {
        unsafe { eventResource.value.write(raw) }
        let common = unsafe { CPointer<SdlCommonEvent>(eventResource.value).read() }
        let eventType = common.eventType
        let commonMetadata = UiEventMetadata(timestampNs: common.timestamp)

        if (eventType == SDL_EVENT_QUIT) {
            record = UiEventRecord(UiEvent.Quit, commonMetadata)
        } else if (isDecodedWindowEvent(eventType)) {
            let window = unsafe { CPointer<SdlWindowEvent>(eventResource.value).read() }
            record = UiEventRecord(decodeWindowStateEvent(eventType, window),
                UiEventMetadata(timestampNs: window.timestamp, windowId: window.windowID))
        } else if (eventType == SDL_EVENT_KEY_DOWN || eventType == SDL_EVENT_KEY_UP) {
            let keyEvent = unsafe { CPointer<SdlKeyboardEvent>(eventResource.value).read() }
            let key = keyFromEvent(keyEvent.scancode, keyEvent.key)
            let metadata = UiEventMetadata(timestampNs: keyEvent.timestamp, windowId: keyEvent.windowID,
                physicalScancode: keyEvent.scancode, logicalKeycode: keyEvent.key,
                modifiers: EventKeyModifiers(raw: keyEvent.mod))
            if (eventType == SDL_EVENT_KEY_DOWN) {
                record = UiEventRecord(UiEvent.KeyDown(key, keyEvent.repeat), metadata)
            } else {
                record = UiEventRecord(UiEvent.KeyUp(key), metadata)
            }
        } else if (eventType == SDL_EVENT_TEXT_EDITING) {
            let editing = unsafe { CPointer<SdlTextEditingEvent>(eventResource.value).read() }
            record = UiEventRecord(UiEvent.TextEditing(eventText(editing.text), editing.start, editing.length),
                UiEventMetadata(timestampNs: editing.timestamp, windowId: editing.windowID))
        } else if (eventType == SDL_EVENT_TEXT_EDITING_CANDIDATES) {
            let editing = unsafe { CPointer<SdlTextEditingCandidatesEvent>(eventResource.value).read() }
            record = UiEventRecord(
                UiEvent.TextEditingCandidates(copyCandidates(editing.candidates, editing.count), editing.selected,
                    editing.horizontal), UiEventMetadata(timestampNs: editing.timestamp, windowId: editing.windowID))
        } else if (eventType == SDL_EVENT_TEXT_INPUT) {
            let text = unsafe { CPointer<SdlTextInputEvent>(eventResource.value).read() }
            record = UiEventRecord(UiEvent.TextInput(eventText(text.text)),
                UiEventMetadata(timestampNs: text.timestamp, windowId: text.windowID))
        } else if (eventType == SDL_EVENT_MOUSE_MOTION) {
            let motion = unsafe { CPointer<SdlMouseMotionEvent>(eventResource.value).read() }
            record = UiEventRecord(UiEvent.MouseMove(motion.x, motion.y),
                UiEventMetadata(timestampNs: motion.timestamp, windowId: motion.windowID))
        } else if (eventType == SDL_EVENT_MOUSE_BUTTON_DOWN || eventType == SDL_EVENT_MOUSE_BUTTON_UP) {
            let button = unsafe { CPointer<SdlMouseButtonEvent>(eventResource.value).read() }
            if (eventType == SDL_EVENT_MOUSE_BUTTON_DOWN) {
                record = UiEventRecord(UiEvent.MouseDown(buttonFromCode(button.button), button.x, button.y),
                    UiEventMetadata(timestampNs: button.timestamp, windowId: button.windowID))
            } else {
                record = UiEventRecord(UiEvent.MouseUp(buttonFromCode(button.button), button.x, button.y),
                    UiEventMetadata(timestampNs: button.timestamp, windowId: button.windowID))
            }
        } else if (eventType == SDL_EVENT_MOUSE_WHEEL) {
            let wheel = unsafe { CPointer<SdlMouseWheelEvent>(eventResource.value).read() }
            record = UiEventRecord(UiEvent.MouseWheel(wheel.x, wheel.y, wheel.mouseX, wheel.mouseY),
                UiEventMetadata(timestampNs: wheel.timestamp, windowId: wheel.windowID))
        } else if (isDropEvent(eventType)) {
            let drop = unsafe { CPointer<SdlDropEvent>(eventResource.value).read() }
            record = UiEventRecord(decodeDropEvent(eventType, drop),
                UiEventMetadata(timestampNs: drop.timestamp, windowId: drop.windowID))
        } else if (isRenderEvent(eventType)) {
            let renderer = unsafe { CPointer<SdlRenderEvent>(eventResource.value).read() }
            record = UiEventRecord(decodeRenderEvent(eventType),
                UiEventMetadata(timestampNs: renderer.timestamp, windowId: renderer.windowID))
        } else {
            record = UiEventRecord(UiEvent.Unknown(eventType), commonMetadata)
        }
    }
    record
}

private func isDecodedWindowEvent(eventType: UInt32): Bool {
    eventType == SDL_EVENT_WINDOW_EXPOSED || eventType == SDL_EVENT_WINDOW_RESIZED || eventType ==
        SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED || eventType == SDL_EVENT_WINDOW_MINIMIZED || eventType ==
        SDL_EVENT_WINDOW_RESTORED || eventType == SDL_EVENT_WINDOW_FOCUS_GAINED || eventType ==
        SDL_EVENT_WINDOW_FOCUS_LOST || eventType == SDL_EVENT_WINDOW_CLOSE_REQUESTED || eventType ==
        SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED || eventType == SDL_EVENT_WINDOW_OCCLUDED
}

private func decodeWindowStateEvent(eventType: UInt32, window: SdlWindowEvent): UiEvent {
    if (eventType == SDL_EVENT_WINDOW_EXPOSED) {
        UiEvent.WindowExposed
    } else if (eventType == SDL_EVENT_WINDOW_RESIZED) {
        UiEvent.WindowResized(window.data1, window.data2)
    } else if (eventType == SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED) {
        UiEvent.WindowPixelSizeChanged(window.data1, window.data2)
    } else if (eventType == SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED) {
        UiEvent.WindowDisplayScaleChanged
    } else if (eventType == SDL_EVENT_WINDOW_MINIMIZED) {
        UiEvent.WindowMinimized
    } else if (eventType == SDL_EVENT_WINDOW_RESTORED) {
        UiEvent.WindowRestored
    } else if (eventType == SDL_EVENT_WINDOW_FOCUS_GAINED) {
        UiEvent.WindowFocusGained
    } else if (eventType == SDL_EVENT_WINDOW_FOCUS_LOST) {
        UiEvent.WindowFocusLost
    } else if (eventType == SDL_EVENT_WINDOW_CLOSE_REQUESTED) {
        UiEvent.WindowCloseRequested
    } else {
        UiEvent.WindowOccluded
    }
}

private func isRenderEvent(eventType: UInt32): Bool {
    eventType == SDL_EVENT_RENDER_TARGETS_RESET || eventType == SDL_EVENT_RENDER_DEVICE_RESET || eventType ==
        SDL_EVENT_RENDER_DEVICE_LOST
}

private func decodeRenderEvent(eventType: UInt32): UiEvent {
    if (eventType == SDL_EVENT_RENDER_TARGETS_RESET) {
        UiEvent.RenderTargetsReset
    } else if (eventType == SDL_EVENT_RENDER_DEVICE_RESET) {
        UiEvent.RenderDeviceReset
    } else {
        UiEvent.RenderDeviceLost
    }
}

private func eventText(text: CPointer<UInt8>): String {
    if (text.isNull()) {
        ""
    } else {
        CString(text).toString()
    }
}

private func copyCandidates(source: CPointer<CPointer<UInt8>>, count: Int32): Array<String> {
    if (source.isNull() || count <= 0) {
        return []
    }
    let result = ArrayList<String>(Int64(count))
    for (index in 0..Int64(count)) {
        let candidate = unsafe { source.read(index) }
        result.add(eventText(candidate))
    }
    result.toArray()
}

private func keyFromEvent(scancode: Int32, keycode: UInt32): Key {
    if (keycode >= ASCII_LOWER_A && keycode <= ASCII_LOWER_Z) {
        Key.Letter(UInt8(keycode - ASCII_LOWER_A + ASCII_UPPER_A))
    } else if (keycode >= ASCII_UPPER_A && keycode <= ASCII_UPPER_Z) {
        Key.Letter(UInt8(keycode))
    } else if (keycode >= ASCII_DIGIT_ZERO && keycode <= ASCII_DIGIT_NINE) {
        Key.Digit(UInt8(keycode))
    } else {
        keyFromScancode(scancode)
    }
}

private func eventModifierHas(mask: UInt16, flag: UInt16): Bool {
    (mask & flag) != UInt16(0)
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

internal func scaleEventRecord(record: UiEventRecord, scale: Float32): UiEventRecord {
    UiEventRecord(scaleEventCoordinates(record.event, scale), record.metadata)
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
        Key.Letter(UInt8(UInt32(scancode - SDL_SCANCODE_A) + ASCII_UPPER_A))
    } else if (scancode >= SDL_SCANCODE_1 && scancode <= SDL_SCANCODE_0) {
        if (scancode == SDL_SCANCODE_0) {
            Key.Digit(UInt8(ASCII_DIGIT_ZERO))
        } else {
            Key.Digit(UInt8(UInt32(scancode - SDL_SCANCODE_1) + ASCII_DIGIT_ZERO + UInt32(1)))
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
