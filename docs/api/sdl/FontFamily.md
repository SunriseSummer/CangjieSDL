[sdl](index.md) › FontFamily

# FontFamily

不可变字体族：regular、可选粗斜体伴随源、附加静态 faces、缺字 fallbacks 和 synthesize 策略。系统目录族保留全部字体面；匹配先考虑倾斜、字宽，再按数值字重顺序选择。应用附加 faces 可提供 Medium/Semibold 等文件。synthesize:false 禁止补造粗斜体，装饰仍可绘制。

## 声明与成员

```cangjie
public class FontFamily
public let regular: FontSource
public let bold: ?FontSource
public let italic: ?FontSource
public let boldItalic: ?FontSource
public let synthesize: Bool
public init(regular: FontSource, bold!: ?FontSource = None, italic!: ?FontSource = None,
        boldItalic!: ?FontSource = None, fallbacks!: Array<FontSource> = [], synthesize!: Bool = true,
        faces!: Array<FontFaceDefinition> = [])
public func faces(): Array<FontFaceDefinition>
public func fallbacks(): Array<FontSource>
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
