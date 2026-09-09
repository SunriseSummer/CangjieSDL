[sdl](index.md) › FontVariation

# FontVariation

单个 OpenType 轴坐标。tag 必须是四个可打印 ASCII 字符，值须为有限 16.16 范围坐标；按 1/65536 规范化。具体字体的轴支持及范围在打开时校验。

## 声明与成员

```cangjie
public struct FontVariation
public let tag: String
public let value: Float32
public init(tag: String, value: Float32)
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
