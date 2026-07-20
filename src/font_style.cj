package sdl

/**
 * A text style: weight, slant, and line decorations layered on top of the base UI font.
 *
 * `bold` prefers the face's true bold companion file when one ships alongside it (msyh.ttc ->
 * msyhbd.ttc, segoeui.ttf -> segoeuib.ttf, X-Regular -> X-Bold), so bold text carries the family's
 * real hinted bold outlines; a face without a companion falls back to SDL_ttf's synthetic
 * emboldening. `italic` shears the glyphs and `underline` / `strikethrough` add a rule under or
 * through the run — those are synthesised for any script the font covers, Latin and CJK alike.
 * Styles compose freely, e.g. `FontStyle(bold: true, italic: true)`.
 *
 * The type is an immutable value; the `with…` helpers return adjusted copies so a style can be
 * built up a flag at a time.
 */
public struct FontStyle <: Equatable<FontStyle> {
    public let bold: Bool
    public let italic: Bool
    public let underline: Bool
    public let strikethrough: Bool

    public init(
        bold!: Bool = false,
        italic!: Bool = false,
        underline!: Bool = false,
        strikethrough!: Bool = false
    ) {
        this.bold = bold
        this.italic = italic
        this.underline = underline
        this.strikethrough = strikethrough
    }

    /** The plain UI font — no weight, slant, or decoration. */
    public static let regular = FontStyle()

    /** Whether this is the plain style: no weight, slant, or decoration. */
    public prop isRegular: Bool {
        get() {
            !bold && !italic && !underline && !strikethrough
        }
    }

    /** This style with bold turned on (or set to `value`). */
    public func withBold(value!: Bool = true): FontStyle {
        FontStyle(bold: value, italic: italic, underline: underline, strikethrough: strikethrough)
    }

    /** This style with italic turned on (or set to `value`). */
    public func withItalic(value!: Bool = true): FontStyle {
        FontStyle(bold: bold, italic: value, underline: underline, strikethrough: strikethrough)
    }

    /** This style with an underline turned on (or set to `value`). */
    public func withUnderline(value!: Bool = true): FontStyle {
        FontStyle(bold: bold, italic: italic, underline: value, strikethrough: strikethrough)
    }

    /** This style with a strikethrough turned on (or set to `value`). */
    public func withStrikethrough(value!: Bool = true): FontStyle {
        FontStyle(bold: bold, italic: italic, underline: underline, strikethrough: value)
    }

    /*
     * The SDL_ttf style bitmask (TTF_STYLE_*). These flag values are part of SDL_ttf's stable ABI —
     * BOLD 0x01, ITALIC 0x02, UNDERLINE 0x04, STRIKETHROUGH 0x08 — so the renderer passes the result
     * straight to TTF_SetFontStyle. It is also folded into the text-metrics cache key, keeping styled
     * and plain runs of the same size measured and cached apart.
     */
    public func ttfFlags(): Int32 {
        var flags: Int32 = 0
        if (bold) {
            flags |= 0x01
        }
        if (italic) {
            flags |= 0x02
        }
        if (underline) {
            flags |= 0x04
        }
        if (strikethrough) {
            flags |= 0x08
        }
        flags
    }

    public operator func ==(other: FontStyle): Bool {
        bold == other.bold && italic == other.italic && underline == other.underline && strikethrough ==
            other.strikethrough
    }

    public operator func !=(other: FontStyle): Bool {
        !(this == other)
    }
}

/**
 * Standard text sizes shared by the renderer, widgets, and applications.
 */
public struct FontSizes {
    public static let CAPTION: Float32 = 13.0
    public static let BODY: Float32 = 15.0
    public static let CONTROL: Float32 = 15.0
    public static let TITLE: Float32 = 20.0
    public static let DISPLAY: Float32 = 32.0
}
