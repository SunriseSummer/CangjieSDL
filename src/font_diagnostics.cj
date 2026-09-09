package sdl

/** Renderer-local font cache counters; texture bytes estimate RGBA storage, excluding driver overhead. */
public struct FontCacheStats {
    public let fontConfigurations: Int64
    public let textTextures: Int64
    public let textTextureBytes: Int64
    public let textRasterizations: UInt64
    public let glyphAtlasBytes: Int64
    public let cachedGlyphs: Int64
    public let glyphAtlasEvictions: UInt64

    public init(fontConfigurations: Int64, textTextures: Int64, textTextureBytes: Int64, textRasterizations: UInt64,
        glyphAtlasBytes!: Int64 = 0, cachedGlyphs!: Int64 = 0, glyphAtlasEvictions!: UInt64 = 0) {
        this.fontConfigurations = fontConfigurations
        this.textTextures = textTextures
        this.textTextureBytes = textTextureBytes
        this.textRasterizations = textRasterizations
        this.glyphAtlasBytes = glyphAtlasBytes
        this.cachedGlyphs = cachedGlyphs
        this.glyphAtlasEvictions = glyphAtlasEvictions
    }
}
