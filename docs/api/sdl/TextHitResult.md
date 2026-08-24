[sdl](../index.md) › [sdl](index.md) › TextHitResult

# TextHitResult

```cangjie
public struct TextHitResult {
    public let byteOffset: Int64
    public let clusterByteLength: Int64
    public let bounds: Rect
}
```

`byteOffset` 是离查询点最近的 UTF-8 插入边界；`clusterByteLength` 与 `bounds` 描述命中的 shaping cluster。用于文本编辑器 hit testing、选择和 caret 几何。
