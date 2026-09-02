[sdl](../index.md) › [sdl](index.md) › TextMeasureSession

# TextMeasureSession

`Renderer.textMeasureSession` 创建的文字测量资源。会话只准备一次 UTF-8 数据，并固定字体、字号和样式，适合为同一段文字反复测量范围、寻找换行位置或定位光标。使用后必须 `close()`，且不能超过所属 `Renderer` 的生命周期。

```cangjie
public class TextMeasureSession <: Resource {
    public prop byteLength: Int64
    public func fit(startByte: Int64, maxWidth: Float32): TextFitResult
    public func measure(startByte: Int64, length: Int64): Float32
    public func hitTest(x: Float32, y!: Float32 = 0.0): TextHitResult
    public func close(): Unit
    public func isClosed(): Bool
}
```

- `fit` 返回指定起点后不超过 `maxWidth` 的最宽 UTF-8 前缀。实现从有限范围开始，只有当前范围可以完整容纳时才继续扩展，避免重复处理整段剩余文字。
- `measure` 测量一个精确字节范围。
- `hitTest` 返回离指定坐标最近的 UTF-8 插入位置，以及命中字形簇的矩形。它不需要逐个测量文字前缀，也能处理连字和从右向左文字。
- 起点与终点若切开 UTF-8 码点会抛 `IllegalArgumentException`；关闭后调用会抛 `IllegalStateException`。
- `fit` 只保证结果位于 UTF-8 码点边界，不保证符合语言换行规则。上层排版仍需处理组合字符、ZWJ、区域指示符和标点规则。
