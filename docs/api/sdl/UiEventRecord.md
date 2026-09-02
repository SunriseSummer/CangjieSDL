[sdl](../index.md) › [sdl](index.md) › UiEventRecord

# UiEventRecord

```cangjie
public struct UiEventRecord {
    public let event: UiEvent
    public let metadata: UiEventMetadata
    public init(event: UiEvent)
    public init(event: UiEvent, metadata: UiEventMetadata)
}
```

[`UiEventMetadata`](UiEventMetadata.md) 复制 SDL 事件的纳秒时间戳、窗口 id、物理 scancode、布局相关逻辑 keycode 和事件时刻修饰键快照。[`EventKeyModifiers`](EventKeyModifiers.md) 提供 `shift`、`ctrl`、`alt`、`gui` 与跨平台 `command`。延迟到下一帧分发时必须使用这里的快照，不应再查询当前全局键盘状态。

## 构造函数

```cangjie
public init(event: UiEvent)
```

只传事件时，`metadata` 使用零值快照。

```cangjie
public init(event: UiEvent, metadata: UiEventMetadata)
```

同时保存事件和已经复制的事件时元数据。
