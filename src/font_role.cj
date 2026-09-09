package sdl

/** Portable family selectors resolved through the platform font service, then directory fallbacks. */
public struct FontRole {
    public static let systemUI: String = "system-ui"
    public static let sansSerif: String = "sans-serif"
    public static let serif: String = "serif"
    public static let monospace: String = "monospace"
    public static let emoji: String = "emoji"
}
