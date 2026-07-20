[sdl](../index.md) › [sdl](index.md) › WindowPosition

# WindowPosition

`sdl` 包中的 public struct

窗口左上角在屏幕坐标系中的位置，由 [`SdlWindow.position`](SdlWindow.md#position) 返回。

## 声明

```cangjie
public struct WindowPosition
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowPosition, WindowSpec}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时打印窗口在屏幕上的坐标。
    try (window = SdlWindow(WindowSpec("位置", 640, 480))) {
        let at: WindowPosition = window.position()
        println("窗口位于 (${at.x}, ${at.y})")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(x: Int32, y: Int32)`](#init) | 由屏幕坐标构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`x`](#x) | 横坐标，屏幕像素。 |
| [`y`](#y) | 纵坐标，屏幕像素。 |

## 构造函数

### init

由屏幕坐标构造。

```cangjie
public init(x: Int32, y: Int32)
```

**参数**

- `x`、`y`: `Int32` — 屏幕坐标。

## 字段

### x

横坐标，屏幕像素。

```cangjie
public let x: Int32
```

### y

纵坐标，屏幕像素。

```cangjie
public let y: Int32
```

## 另请参阅

- [SdlWindow.position](SdlWindow.md#position) · [SdlWindow.setPosition](SdlWindow.md#setposition)
