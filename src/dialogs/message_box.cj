package sdl.dialogs

import sdl.{ensureSdl, SdlWindow}

/** The severity icon a native message box displays: error, warning, or plain information. */
public enum MessageBoxKind {
    | Error
    | Warning
    | Information
}

/** How message box buttons are laid out: the platform's convention or a forced left-to-right/right-to-left order. */
public enum MessageBoxButtonOrder {
    | PlatformDefault
    | LeftToRight
    | RightToLeft
}

/**
 * One button in a message box: the id returned when it is chosen, its label,
 * and whether Return or Escape triggers it by default.
 */
public struct MessageBoxButton {
    public let id: Int32
    public let label: String
    public let returnKeyDefault: Bool
    public let escapeKeyDefault: Bool

    public init(
        label: String,
        id!: Int32,
        returnKeyDefault!: Bool = false,
        escapeKeyDefault!: Bool = false
    ) {
        this.id = id
        this.label = label
        this.returnKeyDefault = returnKeyDefault
        this.escapeKeyDefault = escapeKeyDefault
    }
}

/** An 8-bit-per-channel RGB color used in a message box color scheme. */
public struct MessageBoxColor {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8) {
        this.r = r
        this.g = g
        this.b = b
    }
}

/** Colors for each part of a message box (background, text, and button states), for backends that honor them. */
public struct MessageBoxColorScheme {
    public let background: MessageBoxColor
    public let text: MessageBoxColor
    public let buttonBorder: MessageBoxColor
    public let buttonBackground: MessageBoxColor
    public let buttonSelected: MessageBoxColor

    public init(
        background: MessageBoxColor,
        text: MessageBoxColor,
        buttonBorder: MessageBoxColor,
        buttonBackground: MessageBoxColor,
        buttonSelected: MessageBoxColor
    ) {
        this.background = background
        this.text = text
        this.buttonBorder = buttonBorder
        this.buttonBackground = buttonBackground
        this.buttonSelected = buttonSelected
    }
}

/**
 * Full configuration for `showMessageBox`: title, message, severity, buttons,
 * button order, and an optional color scheme; defaults to an information box with a single "OK" button.
 */
public struct MessageBoxOptions {
    public var title: String
    public var message: String
    public var kind: MessageBoxKind
    public var buttons: Array<MessageBoxButton>
    public var buttonOrder: MessageBoxButtonOrder
    public var colorScheme: ?MessageBoxColorScheme

    public init(title: String, message: String) {
        this.title = title
        this.message = message
        this.kind = MessageBoxKind.Information
        this.buttons = [MessageBoxButton("OK", id: 0, returnKeyDefault: true, escapeKeyDefault: true)]
        this.buttonOrder = MessageBoxButtonOrder.PlatformDefault
        this.colorScheme = None
    }
}

/**
 * Throws `SdlException` when SDL cannot show the native message box.
 */
public func showSimpleMessageBox(
    title: String,
    message: String,
    kind!: MessageBoxKind = MessageBoxKind.Information,
    window!: ?SdlWindow = None
): Unit {
    let cTitle = unsafe { LibC.mallocCString(title) }
    let cMessage = unsafe { LibC.mallocCString(message) }
    try (titleResource = cTitle.asResource()) {
        try (messageResource = cMessage.asResource()) {
            ensureSdl(unsafe {
                SDL_ShowSimpleMessageBox(messageBoxFlag(kind), titleResource.value, messageResource.value,
                    parentWindowPtr(window))
            }, "SDL_ShowSimpleMessageBox")
        }
    }
}

/**
 * Throws `SdlException` when options are invalid or SDL cannot show the native message box.
 */
public func showMessageBox(options: MessageBoxOptions, window!: ?SdlWindow = None): Int32 {
    ensureMessageBoxOptions(options)
    let cTitle = unsafe { LibC.mallocCString(options.title) }
    let cMessage = unsafe { LibC.mallocCString(options.message) }
    let rawButtons = unsafe { LibC.malloc<SdlMessageBoxButtonData>(count: options.buttons.size) }
    let rawColorScheme = allocateRawColorScheme(options.colorScheme)
    let buttonTexts = Array<CString>(options.buttons.size, {_ => nullMessageBoxCString()})
    var selectedButton: Int32 = -1

    try {
        fillRawButtons(rawButtons, buttonTexts, options.buttons)
        var raw = SdlMessageBoxData()
        raw.flags = messageBoxFlags(options.kind, options.buttonOrder)
        raw.window = parentWindowPtr(window)
        raw.title = cTitle
        raw.message = cMessage
        raw.numbuttons = Int32(options.buttons.size)
        raw.buttons = rawButtons
        raw.colorScheme = rawColorScheme
        ensureSdl(unsafe { SDL_ShowMessageBox(inout raw, inout selectedButton) }, "SDL_ShowMessageBox")
    } finally {
        freeButtonTexts(buttonTexts)
        freeRawColorScheme(rawColorScheme)
        unsafe { LibC.free(rawButtons) }
        freeCString(cTitle)
        freeCString(cMessage)
    }

    selectedButton
}
