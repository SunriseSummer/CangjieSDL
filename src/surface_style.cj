package sdl

/**
 * The visual recipe for a rounded panel: fill and border colors, corner radius, border width,
 * and a drop shadow (color plus vertical offset). Border and shadow default to fully
 * transparent, so a bare fill is the minimal style; the `with*` helpers derive variants.
 */
public struct SurfaceStyle {
    public let fill: Color
    public let border: Color
    public let radius: Float32
    public let borderWidth: Float32
    public let shadow: Color
    public let shadowOffsetY: Float32

    public init(
        fill: Color,
        border!: Color = Color.rgba(0, 0, 0, 0),
        radius!: Float32 = 0.0,
        borderWidth!: Float32 = 0.0,
        shadow!: Color = Color.rgba(0, 0, 0, 0),
        shadowOffsetY!: Float32 = 0.0
    ) {
        this.fill = fill
        this.border = border
        this.radius = radius
        this.borderWidth = borderWidth
        this.shadow = shadow
        this.shadowOffsetY = shadowOffsetY
    }

    /** A copy of this style with a different fill color; everything else is unchanged. */
    public func withFill(fill: Color): SurfaceStyle {
        SurfaceStyle(
            fill,
            border: border,
            radius: radius,
            borderWidth: borderWidth,
            shadow: shadow,
            shadowOffsetY: shadowOffsetY
        )
    }

    /** A copy of this style with a different border color; everything else is unchanged. */
    public func withBorder(border: Color): SurfaceStyle {
        SurfaceStyle(
            fill,
            border: border,
            radius: radius,
            borderWidth: borderWidth,
            shadow: shadow,
            shadowOffsetY: shadowOffsetY
        )
    }
}
