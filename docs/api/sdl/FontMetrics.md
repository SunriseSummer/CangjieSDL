[sdl](index.md) › FontMetrics

# FontMetrics

主字体的垂直度量，单位为逻辑像素。`ascent` 在基线上方，`descent` 是基线下方的正距离；`lineHeight` 为字体行框高度，`lineSkip` 为推荐行间推进。混合 fallback 字体的实际文字框应另查 `Renderer.textBounds`。

## 声明与成员

```cangjie
public struct FontMetrics
public let ascent: Float32
public let descent: Float32
public let lineHeight: Float32
public let lineSkip: Float32
public init(ascent: Float32, descent: Float32, lineHeight: Float32, lineSkip: Float32)
```

通过 [`Fonts`](Fonts.md)、[`Renderer`](Renderer.md) 使用；完整流程见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
