[sdl](index.md) › FontWeight

# FontWeight

1～1000 的整数数值字重；越界抛出 IllegalArgumentException。提供 100～900 常用常量；350、625 等值同样可用。400 为 normal，700 为 bold。

## 声明与成员

```cangjie
public struct FontWeight <: Equatable<FontWeight>
public let value: Int64
public init(value: Int64)
public static let thin = FontWeight(100)
public static let extraLight = FontWeight(200)
public static let light = FontWeight(300)
public static let normal = FontWeight(400)
public static let medium = FontWeight(500)
public static let semiBold = FontWeight(600)
public static let bold = FontWeight(700)
public static let extraBold = FontWeight(800)
public static let black = FontWeight(900)
public operator func ==(other: FontWeight): Bool
public operator func !=(other: FontWeight): Bool
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
