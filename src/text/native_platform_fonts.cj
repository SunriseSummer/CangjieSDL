package sdl.text

foreign func SDL_free(memory: CPointer<Unit>): Unit

protected struct NativePlatformFont {
    public let path: String
    public let index: Int64
    public let family: String
    public init(path: String, index: Int64, family: String) {
        this.path = path
        this.index = index
        this.family = family
    }
}

/** Platform file-backed fonts; full enumeration is only used by an explicit catalog request. */
protected func nativePlatformFonts(role: Int32): Array<NativePlatformFont> {
    try {
        if (role == 4) {
            platformFontFiles()
        } else {
            platformRoleFonts(role)
        }
    } catch (_: NativeTextException) {
        []
    }
}

/** Exact installed family lookup. A miss never starts a full font-directory scan. */
protected func nativePlatformNamedFonts(name: String): Array<NativePlatformFont> {
    if (name.isEmpty() || name.size > 16384) {
        return []
    }
    try {
        platformNamedFonts(name)
    } catch (_: NativeTextException) {
        []
    }
}
