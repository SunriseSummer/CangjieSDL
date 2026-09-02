[sdl](../index.md) › [sdl](index.md) › WindowDisplayMetrics

# WindowDisplayMetrics

窗口当前的动态 DPI 信息，分别记录应用缩放、窗口坐标和后备像素，避免重复计算系统 DPI 与应用缩放。

```cangjie
public struct WindowDisplayMetrics {
    public let contentScale: Float32
    public let pixelDensity: Float32
    public let renderScale: Float32
    public let displayScale: Float32
    public init(contentScale: Float32, pixelDensity: Float32,
        renderScale: Float32, displayScale: Float32)
}
```

- `contentScale`：一个应用逻辑单位对应多少窗口坐标单位，包含 `WindowSpec.scale` 指定的应用缩放。
- `pixelDensity`：一个原生窗口坐标单位对应多少后备像素。
- `renderScale`：逻辑单位到后备像素的总尺度，即渲染器实际使用的缩放。
- `displayScale`：SDL 报告的显示缩放，尚未叠加应用缩放。

[`SdlWindow.refreshDisplayMetrics`](SdlWindow.md#refreshdisplaymetrics) 会返回该结构体；尺度变化时还会同步逻辑尺寸、更新渲染缩放、清理相关缓存并使旧命令缓冲失效。`SdlWindow` 和 [`SdlEventPump`](SdlEventPump.md) 的标准事件入口会在处理 `WindowDisplayScaleChanged` 或 `WindowPixelSizeChanged` 时自动刷新。
