[sdl](../index.md) › [sdl](index.md) › WindowFlags

# WindowFlags

`sdl` 包中的 public struct

窗口状态标志位快照：把 SDL 的 64 位标志掩码展开为逐项布尔字段，同时保留原始掩码。由 [`SdlWindow.windowFlags`](SdlWindow.md#windowflags) 返回。

## 声明

```cangjie
public struct WindowFlags
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowFlags, WindowSpec}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时打印窗口是否可调节大小、是否高像素密度。
    try (window = SdlWindow(WindowSpec("状态", 640, 480))) {
        let flags: WindowFlags = window.windowFlags()
        println("resizable=${flags.resizable} highDpi=${flags.highPixelDensity}")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(raw: UInt64)`](#init) | 由 SDL 原始标志掩码展开构造，每个布尔字段对应一个 SDL_WINDOW_* 位。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`raw`](#raw) | SDL 原始 64 位标志掩码，供未展开的位使用。 |
| [`fullscreen`](#fullscreen) | 处于全屏状态。 |
| [`opengl`](#opengl) | 窗口带 OpenGL 上下文。 |
| [`occluded`](#occluded) | 窗口被遮挡。 |
| [`hidden`](#hidden) | 窗口被隐藏。 |
| [`borderless`](#borderless) | 无边框窗口。 |
| [`resizable`](#resizable) | 可调节大小。 |
| [`minimized`](#minimized) | 已最小化。 |
| [`maximized`](#maximized) | 已最大化。 |
| [`mouseGrabbed`](#mousegrabbed) | 鼠标被约束在窗口内。 |
| [`inputFocus`](#inputfocus) | 拥有键盘焦点。 |
| [`mouseFocus`](#mousefocus) | 指针位于窗口上方。 |
| [`external`](#external) | 由外部窗口句柄包装而来。 |
| [`modal`](#modal) | 模态窗口。 |
| [`highPixelDensity`](#highpixeldensity) | 以高像素密度（HiDPI）创建。 |
| [`mouseCaptured`](#mousecaptured) | 鼠标被捕获（拖拽越界跟踪）。 |
| [`relativeMouseMode`](#relativemousemode) | 相对鼠标模式开启。 |
| [`alwaysOnTop`](#alwaysontop) | 置顶显示。 |
| [`utility`](#utility) | 工具窗口。 |
| [`tooltip`](#tooltip) | 提示气泡窗口。 |
| [`popupMenu`](#popupmenu) | 弹出菜单窗口。 |
| [`keyboardGrabbed`](#keyboardgrabbed) | 键盘被独占。 |
| [`fillDocument`](#filldocument) | 填充文档区域（SDL_WINDOW_FILL_DOCUMENT）。 |
| [`vulkan`](#vulkan) | 窗口带 Vulkan 表面。 |
| [`metal`](#metal) | 窗口带 Metal 层。 |
| [`transparent`](#transparent) | 背景透明。 |
| [`notFocusable`](#notfocusable) | 不可获得焦点。 |

## 构造函数

### init

由 SDL 原始标志掩码展开构造，每个布尔字段对应一个 SDL_WINDOW_* 位。

```cangjie
public init(raw: UInt64)
```

**参数**

- `raw`: `UInt64` — SDL_GetWindowFlags 返回的掩码。

## 字段

### raw

SDL 原始 64 位标志掩码，供未展开的位使用。

```cangjie
public let raw: UInt64
```

### fullscreen

处于全屏状态。

```cangjie
public let fullscreen: Bool
```

### opengl

窗口带 OpenGL 上下文。

```cangjie
public let opengl: Bool
```

### occluded

窗口被遮挡。

```cangjie
public let occluded: Bool
```

### hidden

窗口被隐藏。

```cangjie
public let hidden: Bool
```

### borderless

无边框窗口。

```cangjie
public let borderless: Bool
```

### resizable

可调节大小。

```cangjie
public let resizable: Bool
```

### minimized

已最小化。

```cangjie
public let minimized: Bool
```

### maximized

已最大化。

```cangjie
public let maximized: Bool
```

### mouseGrabbed

鼠标被约束在窗口内。

```cangjie
public let mouseGrabbed: Bool
```

### inputFocus

拥有键盘焦点。

```cangjie
public let inputFocus: Bool
```

### mouseFocus

指针位于窗口上方。

```cangjie
public let mouseFocus: Bool
```

### external

由外部窗口句柄包装而来。

```cangjie
public let external: Bool
```

### modal

模态窗口。

```cangjie
public let modal: Bool
```

### highPixelDensity

以高像素密度（HiDPI）创建。

```cangjie
public let highPixelDensity: Bool
```

### mouseCaptured

鼠标被捕获（拖拽越界跟踪）。

```cangjie
public let mouseCaptured: Bool
```

### relativeMouseMode

相对鼠标模式开启。

```cangjie
public let relativeMouseMode: Bool
```

### alwaysOnTop

置顶显示。

```cangjie
public let alwaysOnTop: Bool
```

### utility

工具窗口。

```cangjie
public let utility: Bool
```

### tooltip

提示气泡窗口。

```cangjie
public let tooltip: Bool
```

### popupMenu

弹出菜单窗口。

```cangjie
public let popupMenu: Bool
```

### keyboardGrabbed

键盘被独占。

```cangjie
public let keyboardGrabbed: Bool
```

### fillDocument

填充文档区域（SDL_WINDOW_FILL_DOCUMENT）。

```cangjie
public let fillDocument: Bool
```

### vulkan

窗口带 Vulkan 表面。

```cangjie
public let vulkan: Bool
```

### metal

窗口带 Metal 层。

```cangjie
public let metal: Bool
```

### transparent

背景透明。

```cangjie
public let transparent: Bool
```

### notFocusable

不可获得焦点。

```cangjie
public let notFocusable: Bool
```

## 另请参阅

- [SdlWindow.windowFlags](SdlWindow.md#windowflags) — 查询入口。
