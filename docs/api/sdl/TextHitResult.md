[sdl](../index.md) › [sdl](index.md) › TextHitResult

# TextHitResult

```cangjie
public struct TextHitResult {
    public let byteOffset: Int64
    public let clusterByteLength: Int64
    public let bounds: Rect
    public init(byteOffset: Int64, clusterByteLength: Int64, bounds: Rect)
}
```

`byteOffset` 是离查询点最近的 UTF-8 插入位置；`clusterByteLength` 与 `bounds` 描述命中的字形簇。它适合实现文字光标定位和选择，不会把连字或从右向左文字的字形簇从中间拆开。

## 构造函数

```cangjie
public init(byteOffset: Int64, clusterByteLength: Int64, bounds: Rect)
```

- `byteOffset`：最近插入位置相对字符串开头的 UTF-8 字节偏移。
- `clusterByteLength`：命中字形簇的 UTF-8 字节长度。
- `bounds`：字形簇在逻辑坐标中的矩形。
