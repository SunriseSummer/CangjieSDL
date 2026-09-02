[sdl](../index.md) › [sdl](index.md) › TextFitResult

# TextFitResult

一次前缀适配的结果；宽度为逻辑像素，长度为相对起点的 UTF-8 字节数。

```cangjie
public struct TextFitResult {
    public let width: Float32
    public let byteLength: Int64
    public init(width: Float32, byteLength: Int64)
}
```

`byteLength` 总在码点边界结束，但段落引擎仍需按 Unicode 字素簇与换行规则收紧该边界；字体测量不等于断行策略。

## 构造函数

```cangjie
public init(width: Float32, byteLength: Int64)
```

- `width`：已适配前缀的逻辑像素宽度。
- `byteLength`：相对测量起点的 UTF-8 字节数。
