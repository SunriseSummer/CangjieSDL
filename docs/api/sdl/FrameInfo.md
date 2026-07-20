[sdl](../index.md) › [sdl](index.md) › FrameInfo

# FrameInfo

`sdl` 包中的 public struct

以毫秒计的帧计时信息：`elapsedMs` 为 SDL 初始化以来的总时长，`deltaMs` 为距上一帧的间隔。动画按 `deltaMs` 推进，可避免动画速度随帧率变化。

## 声明

```cangjie
public struct FrameInfo
```

## 示例

```cangjie verify
package docexample

import sdl.{FrameInfo, UiEvent}

main(): Unit {
    let event = UiEvent.Frame(FrameInfo(1024, 16))
    match (event) {
        case UiEvent.Frame(info) => println("第 ${info.elapsedMs} 毫秒，帧间隔 ${info.deltaMs} 毫秒")
        case _ => ()
    }
    // 输出: 第 1024 毫秒，帧间隔 16 毫秒
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(elapsedMs: UInt64, deltaMs: UInt64)`](#init) | 由总时长与帧间隔构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`elapsedMs`](#elapsedms) | SDL 初始化以来的毫秒数。 |
| [`deltaMs`](#deltams) | 距上一帧的毫秒数。 |

## 构造函数

### init

由总时长与帧间隔构造。

```cangjie
public init(elapsedMs: UInt64, deltaMs: UInt64)
```

**参数**

- `elapsedMs`: `UInt64` — SDL 初始化以来的毫秒数。
- `deltaMs`: `UInt64` — 距上一帧的毫秒数。

## 字段

### elapsedMs

SDL 初始化以来的毫秒数。

```cangjie
public let elapsedMs: UInt64
```

### deltaMs

距上一帧的毫秒数。

```cangjie
public let deltaMs: UInt64
```

## 另请参阅

- [UiEvent](UiEvent.md) — `Frame` 事件携带本类型。
