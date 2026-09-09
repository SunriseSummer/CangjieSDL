package sdl

/** Numeric OpenType/CSS weight, from 1 through 1000. Values outside the range are rejected. */
public struct FontWeight <: Equatable<FontWeight> {
    public let value: Int64

    public init(value: Int64) {
        if (value < 1 || value > 1000) {
            throw IllegalArgumentException("Font weight must be between 1 and 1000")
        }
        this.value = value
    }

    public static let thin = FontWeight(100)
    public static let extraLight = FontWeight(200)
    public static let light = FontWeight(300)
    public static let normal = FontWeight(400)
    public static let medium = FontWeight(500)
    public static let semiBold = FontWeight(600)
    public static let bold = FontWeight(700)
    public static let extraBold = FontWeight(800)
    public static let black = FontWeight(900)

    public operator func ==(other: FontWeight): Bool {
        value == other.value
    }
    public operator func !=(other: FontWeight): Bool {
        !(this == other)
    }
}
