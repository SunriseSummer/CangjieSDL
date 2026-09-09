[sdl](index.md) › InstalledFontFace

# InstalledFontFace

发现的字体文件/集合面/命名实例。weight 来自 OS/2 或实例的 wght 坐标，widthClass 是 OS/2 字宽类别，axes() 返回轴范围。仓颉代码直接读取 SFNT 元数据，避免命名实例被误报为 400，无需逐实例打开原生字体。

## 声明与成员

```cangjie
public struct InstalledFontFace
public let source: FontSource
public let familyName: String
public let styleName: String
public let style: FontStyle
public let widthClass: Int64
public let variations: FontVariations
public prop weight: FontWeight
public func axes(): Array<FontAxis>
public init(source: FontSource, familyName: String, styleName: String, style: FontStyle, widthClass!: Int64 = 5,
        axes!: Array<FontAxis> = [], variations!: FontVariations = FontVariations())
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。

variations 保存当前默认面/命名实例的完整设计坐标；axes() 保存范围。两者使用不同字段，查询不会把基础字体固定到默认字重。
