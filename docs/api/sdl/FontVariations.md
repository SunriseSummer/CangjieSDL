[sdl](index.md) › FontVariations

# FontVariations

不可变轴坐标集合，最多 64 项，按 tag 排序，拒绝重复 tag，输入及返回数组均复制。空集合使用字体默认轴值；key 可用于应用缓存。

## 声明与成员

```cangjie
public class FontVariations <: Equatable<FontVariations>
public init()
public init(values: Array<FontVariation>)
public func values(): Array<FontVariation>
public func key(): String
public operator func ==(other: FontVariations): Bool
public operator func !=(other: FontVariations): Bool
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
