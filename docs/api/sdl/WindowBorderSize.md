[sdl](../index.md) › [sdl](index.md) › WindowBorderSize

# WindowBorderSize

`sdl` 包中的 public struct

窗口装饰（标题栏与边框）在四个方向占用的像素数，由 [`SdlWindow.borderSize`](SdlWindow.md#bordersize) 返回。

## 声明

```cangjie
public struct WindowBorderSize
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowBorderSize, WindowSpec}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时打印标题栏高度。
    try (window = SdlWindow(WindowSpec("边框", 640, 480))) {
        let border: WindowBorderSize = window.borderSize()
        println("标题栏高 ${border.top} 像素")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(top: Int32, left: Int32, bottom: Int32, right: Int32)`](#init) | 由四向尺寸构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`top`](#top) | 上侧装饰高度（通常是标题栏），像素。 |
| [`left`](#left) | 左侧边框宽度，像素。 |
| [`bottom`](#bottom) | 下侧边框高度，像素。 |
| [`right`](#right) | 右侧边框宽度，像素。 |

## 构造函数

### init

由四向尺寸构造。

```cangjie
public init(top: Int32, left: Int32, bottom: Int32, right: Int32)
```

**参数**

- `top`、`left`、`bottom`、`right`: `Int32` — 各方向装饰尺寸，像素。

## 字段

### top

上侧装饰高度（通常是标题栏），像素。

```cangjie
public let top: Int32
```

### left

左侧边框宽度，像素。

```cangjie
public let left: Int32
```

### bottom

下侧边框高度，像素。

```cangjie
public let bottom: Int32
```

### right

右侧边框宽度，像素。

```cangjie
public let right: Int32
```

## 另请参阅

- [SdlWindow.borderSize](SdlWindow.md#bordersize) — 查询入口。
