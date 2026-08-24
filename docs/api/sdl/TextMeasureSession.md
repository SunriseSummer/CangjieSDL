[sdl](../index.md) › [sdl](index.md) › TextMeasureSession

# TextMeasureSession

`Renderer.textMeasureSession` 创建的同串文本测量资源。会话只建立一次 UTF-8 原生缓冲并固定字体/字号/样式，适合段落逐行适配；用完必须 `close()`，且不得活过所属 `Renderer`。

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

- `fit` 返回指定起点后不宽于 `maxWidth` 的最宽 UTF-8 前缀；真实后端以边界对齐的有限 shaping window 起步，只有整窗容纳时才扩张，避免长余串的重复整段处理。
- `measure` 测量一个精确字节范围。
- `hitTest` 由 SDL_ttf 已 shaping 的 cluster 直接返回最近 UTF-8 插入边界及 cluster 矩形；真实后端避免长行点击时逐前缀测量，也正确覆盖连字与 RTL 视觉方向。
- 起点与终点若切开 UTF-8 码点会抛 `IllegalArgumentException`；关闭后调用会抛 `IllegalStateException`。
- `fit` 返回码点安全边界，不承诺 UAX #14 合法断点；`hitTest` 则返回 shaping cluster 边界。上层段落断行仍须处理组合字符、ZWJ、区域指示符和语言标点规则。
