[sdl](../index.md) › [sdl](index.md) › SdlEventPump

# SdlEventPump

多窗口应用的进程级事件泵。SDL 每个进程只有一个事件队列；把各窗口分别轮询会让先轮询者取走其它窗口事件，并可能按错误 DPI 换算坐标。将所有活动 `SdlWindow` 注册到一个 pump 后，从 `poll` / `waitTimeout` 单点消费，再按 `UiEventRecord.metadata.windowId` 路由。

```cangjie
public class SdlEventPump {
    public init(windows!: Array<SdlWindow> = [])
    public func register(window: SdlWindow): Unit
    public func unregister(window: SdlWindow): Unit
    public func poll(): ?UiEventRecord
    public func waitTimeout(timeoutMs: Int32): ?UiEventRecord
}
```

Pump 会用目标窗口的动态内容缩放转换指针/拖放坐标，并把 DPI 与 Renderer reset 事件应用到目标窗口。单窗口小程序可继续使用 `SdlWindow.pollEventRecord`。
