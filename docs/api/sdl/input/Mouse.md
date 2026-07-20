[sdl](../../index.md) › [sdl.input](index.md) › Mouse

# Mouse

`sdl.input` 包中的 public class

鼠标的轮询式查询与捕获控制。事件式的鼠标输入经 [`UiEvent`](../UiEvent.md) 到达；这里的 [`state`](#state) 适合每帧读取的即时状态（拖动、悬停跟踪）。SDL 拒绝更改鼠标捕获状态时，`capture` 把失败状态转换为 `CuiException`。

## 声明

```cangjie
public class Mouse
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowSpec}
import sdl.input.Mouse

main(): Unit {
    // 需要视频子系统，本示例仅作编译验证；
    // 运行时按窗口缩放读取指针状态。
    try (window = SdlWindow(WindowSpec("拖拽", 320, 240))) {
        let state = Mouse.state(scale: window.scale)
        if (state.left) {
            println("拖拽中 @ (${Int64(state.x)}, ${Int64(state.y)})")
        }
        window.delay(1)
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `Mouse` 对象；鼠标操作由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static state(scale!: Float32)`](#state) | 返回当前鼠标快照，坐标除以 `scale` 折算为逻辑像素。 |
| [`static capture(enabled: Bool)`](#capture) | 开关全局鼠标捕获，让拖拽越出窗口仍收到事件（按住拖动滚动条、拖放）。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `Mouse` 对象；鼠标操作由静态方法提供。

```cangjie
public init()
```

## 方法

### state

返回当前鼠标快照，坐标除以 `scale` 折算为逻辑像素。

```cangjie
public static func state(scale!: Float32 = 1.0): MouseState
```

**参数**

- `scale!`: `Float32` — 窗口的逻辑缩放（传 [`SdlWindow.scale`](../SdlWindow.md#scale)）；默认 1.0，非正值按 1.0 处理。

**返回值** `MouseState` — 指针位置与按键状态。

### capture

开关全局鼠标捕获，让拖拽越出窗口仍收到事件（按住拖动滚动条、拖放）。

```cangjie
public static func capture(enabled: Bool): Unit
```

**参数**

- `enabled`: `Bool` — 是否捕获。

**异常**

- `CuiException` — SDL 拒绝捕获时。

## 另请参阅

- [MouseState](MouseState.md) — 快照类型。
- [SdlWindow.setMouseGrab](../SdlWindow.md#setmousegrab) — 把鼠标约束在窗口内（不同于捕获）。
