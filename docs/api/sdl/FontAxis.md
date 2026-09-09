[sdl](index.md) › FontAxis

# FontAxis

字体公布的设计轴及最小值、默认值、最大值。由 InstalledFontFace.axes() 查询；支持的具体轴由字体文件决定。

## 声明与成员

```cangjie
public struct FontAxis
public let tag: String
public let minimum: Float32
public let defaultValue: Float32
public let maximum: Float32
public init(tag: String, minimum: Float32, defaultValue: Float32, maximum: Float32)
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
