[sdl](../index.md) › [sdl](index.md) › WindowDisplayMetrics

# WindowDisplayMetrics

一个窗口当前的动态 DPI 尺度快照，明确分开应用缩放、原生窗口坐标和后备像素，避免把系统 DPI 与用户 zoom 重复相乘。

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

- `contentScale`：一个应用逻辑单位对应多少原生窗口坐标单位，包含 `WindowSpec.scale` 请求的 zoom。
- `pixelDensity`：一个原生窗口坐标单位对应多少后备像素。
- `renderScale`：逻辑单位到后备像素的总尺度，即 Renderer 实际使用的缩放。
- `displayScale`：SDL 报告的综合显示缩放，尚未叠加应用 zoom。

[`SdlWindow.refreshDisplayMetrics`](SdlWindow.md#refreshdisplaymetrics) 会返回此快照，并在尺度变化时更新 Renderer epoch、清理相关缓存及同步逻辑尺寸。窗口跨显示器时处理 `WindowDisplayScaleChanged` / `WindowPixelSizeChanged`；`SdlWindow` 和 [`SdlEventPump`](SdlEventPump.md) 的标准事件入口会自动执行刷新。

