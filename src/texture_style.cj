package sdl

/** Nearest-neighbor sampling for pixel art, or linear filtering for smooth image scaling. */
public enum TextureScaleMode {
    | Nearest
    | Linear
}

internal func textureScaleCode(mode: TextureScaleMode): Int32 {
    match (mode) {
        case TextureScaleMode.Nearest => 0
        case TextureScaleMode.Linear => 1
    }
}

/** Immutable per-draw image styling, captured by retained command buffers without changing tint/alpha on shared textures. */
public struct TextureStyle {
    public let tint: Color
    public let opacity: Float32
    public let radius: Float32
    public let sampling: TextureScaleMode
    public let flip: TextureFlip

    /** Throws `IllegalArgumentException` for non-finite opacity/radius, opacity outside 0..1, or negative radius. */
    public init(tint!: Color = Color.rgb(255, 255, 255), opacity!: Float32 = 1.0, radius!: Float32 = 0.0,
        sampling!: TextureScaleMode = TextureScaleMode.Linear, flip!: TextureFlip = TextureFlip.None) {
        if (opacity.isNaN() || opacity.isInf() || opacity < 0.0 || opacity > 1.0 || radius.isNaN() || radius.isInf() ||
            radius < 0.0) {
            throw IllegalArgumentException("Texture style requires opacity in 0..1 and a finite non-negative radius")
        }
        this.tint = tint
        this.opacity = opacity
        this.radius = radius
        this.sampling = sampling
        this.flip = flip
    }
}
