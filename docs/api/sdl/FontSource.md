[sdl](index.md) › FontSource

# FontSource

字体文件、集合面号、命名实例与可选源坐标。collectionIndex 是低 16 位集合面号；instanceIndex 为 0～32767，0 表示默认实例。旧 faceIndex 保留 FreeType 编码的兼容语义；同时传非零 instanceIndex 时 faceIndex 必须为 0～65535。显式命名实例及源 wght 坐标固定该源的字重；要由 fontWeight 自动选择，应注册基础文件。显式样式 variations 可覆盖源坐标。

## 声明与成员

```cangjie
public struct FontSource
public let path: String
public let faceIndex: Int64
public let variations: FontVariations
public init(path: String, faceIndex!: Int64 = 0, instanceIndex!: Int64 = 0, variations!: FontVariations = FontVariations())
public prop collectionIndex: Int64
public prop instanceIndex: Int64
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
