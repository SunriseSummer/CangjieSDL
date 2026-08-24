[sdl](../index.md) › [sdl](index.md) › EventKeyModifiers

# EventKeyModifiers

键盘事件发生时的修饰键快照。左右同类键合并为 `shift`、`ctrl`、`alt`、`gui`；`command` 在 Ctrl 或 GUI 任一按下时为 `true`，便于跨平台快捷键。它不同于 `sdl.input.Keyboard.modifiers()`：本类型随事件复制，延迟分发仍保持原时刻语义。

```cangjie
public struct EventKeyModifiers {
    public let raw: UInt16
    public let shift: Bool
    public let ctrl: Bool
    public let alt: Bool
    public let gui: Bool
    public let command: Bool
    public init(raw!: UInt16 = UInt16(0))
}
```

从 [`UiEventRecord.metadata`](UiEventRecord.md) 的 `modifiers` 读取。`raw` 保留 SDL 掩码；普通应用优先使用展开字段，不要在事件排队后重新查询全局键盘状态。

