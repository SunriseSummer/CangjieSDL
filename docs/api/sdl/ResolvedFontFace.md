[sdl](index.md) › ResolvedFontFace

# ResolvedFontFace

实际打开的字体面；weight 是真实轮廓的字重，source.variations 为实际采用的源/请求坐标，synthesizedStyle 只包含额外合成的样式。合成粗体并不意味着字体存在精确 700 的真实轮廓。

## 声明与成员

```cangjie
public struct ResolvedFontFace
public let source: FontSource
public let familyName: String
public let styleName: String
public let weight: FontWeight
public let synthesizedStyle: FontStyle
public init(source: FontSource, familyName: String, styleName: String, synthesizedStyle: FontStyle, weight!: FontWeight = FontWeight.normal)
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
