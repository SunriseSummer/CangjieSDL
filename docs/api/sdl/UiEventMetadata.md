[sdl](../index.md) › [sdl](index.md) › UiEventMetadata

# UiEventMetadata

从 SDL 原生事件复制出的稳定元数据；SDL 复用事件队列存储后字段仍有效。

```cangjie
public struct UiEventMetadata {
    public let timestampNs: UInt64
    public let windowId: UInt32
    public let physicalScancode: Int32
    public let logicalKeycode: UInt32
    public let modifiers: EventKeyModifiers
    public init(
        timestampNs!: UInt64 = UInt64(0),
        windowId!: UInt32 = UInt32(0),
        physicalScancode!: Int32 = 0,
        logicalKeycode!: UInt32 = UInt32(0),
        modifiers!: EventKeyModifiers = EventKeyModifiers()
    )
}
```

- `timestampNs` 是 SDL 事件时间戳；测试或手工构造记录时默认 0。
- `windowId` 用于多窗口路由；进程级或合成事件可能为 0。
- `physicalScancode` 表示布局无关的物理键位，`logicalKeycode` 表示当前布局解释后的键值。
- `modifiers` 是同一键盘事件发生时的修饰键，而不是分发时的当前状态。

使用 [`SdlWindow.pollEventRecord`](SdlWindow.md#polleventrecord) 或 [`SdlEventPump`](SdlEventPump.md) 获得本类型；只需要兼容的简化事件时可继续使用 `pollEvent()`。

