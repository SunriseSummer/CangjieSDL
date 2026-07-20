[sdl](../../index.md) › [sdl.input](index.md) › MouseState

# MouseState

`sdl.input` 包中的 public struct

某一时刻的鼠标快照：指针位置（已按窗口缩放折算为逻辑像素）、左中右三键的按下状态与原始按键掩码。由 [`Mouse.state`](Mouse.md#state) 返回。

## 声明

```cangjie
public struct MouseState
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowSpec}
import sdl.input.{Mouse, MouseState}

main(): Unit {
    // 需要视频子系统，本示例仅作编译验证；
    // 运行时打印指针位置与左键是否按下。
    try (window = SdlWindow(WindowSpec("鼠标", 320, 240))) {
        let state: MouseState = Mouse.state(scale: window.scale)
        println("(${Int64(state.x)}, ${Int64(state.y)}) 左键=${state.left}")
        window.delay(1)
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(x: Float32, y: Float32, left: Bool, middle: Bool, right: Bool, buttons: UInt32)`](#init) | 逐项构造快照。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`x`](#x) | 指针横坐标，逻辑像素。 |
| [`y`](#y) | 指针纵坐标，逻辑像素。 |
| [`left`](#left) | 左键按下。 |
| [`middle`](#middle) | 中键按下。 |
| [`right`](#right) | 右键按下。 |
| [`buttons`](#buttons) | SDL 原始按键掩码，含左中右之外的按键。 |

## 构造函数

### init

逐项构造快照。

```cangjie
public init(x: Float32, y: Float32, left: Bool, middle: Bool, right: Bool, buttons: UInt32)
```

**参数**

- `x`、`y`: `Float32` — 指针位置。
- `left`、`middle`、`right`: `Bool` — 三键状态。
- `buttons`: `UInt32` — 原始按键掩码。

## 字段

### x

指针横坐标，逻辑像素。

```cangjie
public let x: Float32
```

### y

指针纵坐标，逻辑像素。

```cangjie
public let y: Float32
```

### left

左键按下。

```cangjie
public let left: Bool
```

### middle

中键按下。

```cangjie
public let middle: Bool
```

### right

右键按下。

```cangjie
public let right: Bool
```

### buttons

SDL 原始按键掩码，含左中右之外的按键。

```cangjie
public let buttons: UInt32
```

## 另请参阅

- [Mouse.state](Mouse.md#state) — 查询入口。
- [sdl 的 UiEvent](../UiEvent.md) — 事件式的鼠标输入。
