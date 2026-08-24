package sdl

@Test
func keyFromScancodeMapsLettersAndControls(): Unit {
    match (keyFromScancode(SDL_SCANCODE_A)) {
        case Key.Letter(value) => @Expect(value, UInt8(65))
        case _ => @Fail("A scancode should map to Key.Letter.")
    }

    match (keyFromScancode(SDL_SCANCODE_ESCAPE)) {
        case Key.Escape => @Expect(true)
        case _ => @Fail("Escape scancode should map to Key.Escape.")
    }

    match (keyFromScancode(SDL_SCANCODE_HOME)) {
        case Key.Home => @Expect(true)
        case _ => @Fail("Home scancode should map to Key.Home.")
    }
}

@Test
func buttonFromCodeMapsKnownButtons(): Unit {
    match (buttonFromCode(SDL_BUTTON_LEFT)) {
        case MouseButton.Left => @Expect(true)
        case _ => @Fail("Left button code should map to MouseButton.Left.")
    }

    match (buttonFromCode(UInt8(9))) {
        case MouseButton.RawCode(value) => @Expect(value, UInt8(9))
        case _ => @Fail("Unknown button code should map to MouseButton.RawCode.")
    }
}

@Test
func mouseEventsScaleCoordinates(): Unit {
    let event = scaleEventCoordinates(UiEvent.MouseDown(MouseButton.Left, 30.0, 45.0), 1.5)

    match (event) {
        case UiEvent.MouseDown(MouseButton.Left, x, y) =>
            @Expect(x, Float32(20.0))
            @Expect(y, Float32(30.0))
        case _ => @Fail("Scaled event should remain a left mouse down event.")
    }
}

@Test
func dropEventsDecodeFileData(): Unit {
    let event = decodeRawDrop(SDL_EVENT_DROP_FILE, "C:/tmp/note.txt", 30.0, 45.0)

    match (event) {
        case UiEvent.DropFile(path, x, y) =>
            @Expect(path, "C:/tmp/note.txt")
            @Expect(x, Float32(30.0))
            @Expect(y, Float32(45.0))
        case _ => @Fail("Drop file event should decode with path and position.")
    }
}

@Test
func dropEventsScaleCoordinates(): Unit {
    let event = scaleEventCoordinates(UiEvent.DropText("hello", 30.0, 45.0), 1.5)

    match (event) {
        case UiEvent.DropText(value, x, y) =>
            @Expect(value, "hello")
            @Expect(x, Float32(20.0))
            @Expect(y, Float32(30.0))
        case _ => @Fail("Drop text event should scale coordinates.")
    }
}

@Test
func frameEventsKeepTimeValuesWhenScaled(): Unit {
    let event = scaleEventCoordinates(UiEvent.Frame(FrameInfo(UInt64(32), UInt64(16))), 2.0)

    match (event) {
        case UiEvent.Frame(info) =>
            @Expect(info.elapsedMs, UInt64(32))
            @Expect(info.deltaMs, UInt64(16))
        case _ => @Fail("Frame event should not be converted by coordinate scaling.")
    }
}

@Test
func keyboardEventPreservesTimestampWindowLogicalKeyAndModifiers(): Unit {
    let eventPtr = unsafe { LibC.malloc<SdlEvent>() }
    try (eventResource = eventPtr.asResource()) {
        var key = SdlKeyboardEvent()
        key.eventType = SDL_EVENT_KEY_DOWN
        key.timestamp = UInt64(123456)
        key.windowID = UInt32(42)
        key.scancode = SDL_SCANCODE_A
        key.key = UInt32(113) // logical 'q' on a non-QWERTY layout
        key.mod = UInt16(0x0040)
        unsafe { CPointer<SdlKeyboardEvent>(eventResource.value).write(key) }

        let record = decodeEventRecord(unsafe { eventResource.value.read() })

        match (record.event) {
            case UiEvent.KeyDown(Key.Letter(value), _) => @Expect(value, UInt8(81))
            case _ => @Fail("Logical keycode should drive printable shortcut keys.")
        }
        @Expect(record.metadata.timestampNs, UInt64(123456))
        @Expect(record.metadata.windowId, UInt32(42))
        @Expect(record.metadata.physicalScancode, SDL_SCANCODE_A)
        @Expect(record.metadata.logicalKeycode, UInt32(113))
        @Expect(record.metadata.modifiers.ctrl)
        @Expect(record.metadata.modifiers.command)
    }
}

@Test
func textEditingEventCopiesCompositionAndSelection(): Unit {
    let eventPtr = unsafe { LibC.malloc<SdlEvent>() }
    let composition = unsafe { LibC.mallocCString("拼音") }
    try (eventResource = eventPtr.asResource()) {
        try (textResource = composition.asResource()) {
            var editing = SdlTextEditingEvent()
            editing.eventType = SDL_EVENT_TEXT_EDITING
            editing.timestamp = UInt64(99)
            editing.windowID = UInt32(7)
            editing.text = textResource.value.getChars()
            editing.start = 1
            editing.length = 2
            unsafe { CPointer<SdlTextEditingEvent>(eventResource.value).write(editing) }

            let record = decodeEventRecord(unsafe { eventResource.value.read() })

            match (record.event) {
                case UiEvent.TextEditing(text, start, length) =>
                    @Expect(text, "拼音")
                    @Expect(start, Int32(1))
                    @Expect(length, Int32(2))
                case _ => @Fail("Text editing event should preserve the IME preedit range.")
            }
            @Expect(record.metadata.timestampNs, UInt64(99))
            @Expect(record.metadata.windowId, UInt32(7))
        }
    }
}

@Test
func windowAndRenderLifecycleEventsRemainTyped(): Unit {
    match (decodeRawWindowEvent(SDL_EVENT_WINDOW_CLOSE_REQUESTED, UInt32(8)).event) {
        case UiEvent.WindowCloseRequested => @Expect(true)
        case _ => @Fail("Close requested should not be dropped as Unknown.")
    }
    match (decodeRawRenderEvent(SDL_EVENT_RENDER_DEVICE_RESET, UInt32(9)).event) {
        case UiEvent.RenderDeviceReset => @Expect(true)
        case _ => @Fail("Renderer reset should remain typed.")
    }
}

private func decodeRawDrop(eventType: UInt32, data: String, x: Float32, y: Float32): UiEvent {
    let eventPtr = unsafe { LibC.malloc<SdlEvent>() }
    let cData = unsafe { LibC.mallocCString(data) }
    var decoded = UiEvent.Unknown(UInt32(0))
    try (eventResource = eventPtr.asResource()) {
        try (dataResource = cData.asResource()) {
            var drop = SdlDropEvent()
            drop.eventType = eventType
            drop.x = x
            drop.y = y
            drop.data = dataResource.value.getChars()
            unsafe { CPointer<SdlDropEvent>(eventResource.value).write(drop) }
            decoded = decodeEvent(unsafe { eventResource.value.read() })
        }
    }
    decoded
}

private func decodeRawWindowEvent(eventType: UInt32, windowId: UInt32): UiEventRecord {
    let eventPtr = unsafe { LibC.malloc<SdlEvent>() }
    var record = UiEventRecord(UiEvent.Unknown(UInt32(0)))
    try (eventResource = eventPtr.asResource()) {
        var window = SdlWindowEvent()
        window.eventType = eventType
        window.timestamp = UInt64(17)
        window.windowID = windowId
        unsafe { CPointer<SdlWindowEvent>(eventResource.value).write(window) }
        record = decodeEventRecord(unsafe { eventResource.value.read() })
    }
    record
}

private func decodeRawRenderEvent(eventType: UInt32, windowId: UInt32): UiEventRecord {
    let eventPtr = unsafe { LibC.malloc<SdlEvent>() }
    var record = UiEventRecord(UiEvent.Unknown(UInt32(0)))
    try (eventResource = eventPtr.asResource()) {
        var renderer = SdlRenderEvent()
        renderer.eventType = eventType
        renderer.timestamp = UInt64(23)
        renderer.windowID = windowId
        unsafe { CPointer<SdlRenderEvent>(eventResource.value).write(renderer) }
        record = decodeEventRecord(unsafe { eventResource.value.read() })
    }
    record
}
