[sdl](index.md) › FontStyle

# FontStyle

完整的不可变字体样式。weight 优先于构造参数 bold；bold:true/withBold() 对应 700，false 对应 400。bold 属性是 weight≥600 的兼容标志，不能表达全部数值字重。斜体和装饰独立保存。显式 variations 的 wght 覆盖 weight；withWeight/withBold 会清除先前显式 wght，保留其它轴。ttfFlags 仍只有 SDL 的四个样式位，不足以单独作为完整字体缓存键。

## 声明与成员

```cangjie
public struct FontStyle <: Equatable<FontStyle>
public let variations: FontVariations
public let weight: FontWeight
public prop bold: Bool
public let italic: Bool
public let underline: Bool
public let strikethrough: Bool
public init(
        bold!: Bool = false,
        italic!: Bool = false,
        underline!: Bool = false,
        strikethrough!: Bool = false,
        weight!: ?FontWeight = None,
        variations!: FontVariations = FontVariations()
    )
public static let regular = FontStyle()
public prop isRegular: Bool
public func withBold(value!: Bool = true): FontStyle
public func withWeight(value: FontWeight): FontStyle
public func withVariations(value: FontVariations): FontStyle
public func withItalic(value!: Bool = true): FontStyle
public func withUnderline(value!: Bool = true): FontStyle
public func withStrikethrough(value!: Bool = true): FontStyle
public func ttfFlags(): Int32
public operator func ==(other: FontStyle): Bool
public operator func !=(other: FontStyle): Bool
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。

## regular

`FontStyle.regular` 表示 400 字重、正体、无装饰和空轴设置。
