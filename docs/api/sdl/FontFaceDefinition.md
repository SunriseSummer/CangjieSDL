[sdl](index.md) › FontFaceDefinition

# FontFaceDefinition

应用补充的静态字体面，携带数值字重、倾斜及 1～9 字宽类别。传入 FontFamily 的 faces 参数；元数据用于匹配，真实打开后的字重仍由 resolveFont 报告。

## 声明与成员

```cangjie
public struct FontFaceDefinition
public let source: FontSource
public let weight: FontWeight
public let italic: Bool
public let widthClass: Int64
public init(source: FontSource, weight!: FontWeight = FontWeight.normal, italic!: Bool = false,
        widthClass!: Int64 = 5)
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
