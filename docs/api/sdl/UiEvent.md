[sdl](../index.md) › [sdl](index.md) › UiEvent

# UiEvent

`sdl` 包中的 public enum

解码后的 SDL 输入事件，按到达顺序交给应用处理。指针坐标为逻辑像素——窗口已除去缩放比例，事件与布局、绘制处于同一坐标空间。`MouseWheel` 的字段顺序是（滚动量 X、滚动量 Y、指针 X、指针 Y）：两个滚动增量在前、指针位置在后，按位置在前的顺序解构会把滚动误当成命中测试。`KeyDown` 的 `Bool` 是按键重复标志。`Frame` 由应用的帧循环合成而非从 SDL 轮询；`Unknown` 携带未解码事件的原始 SDL 事件类型码。

## 声明

```cangjie
public enum UiEvent
```

## 示例

```cangjie verify
package docexample

import sdl.{FrameInfo, Key, MouseButton, UiEvent}

main(): Unit {
    let events = [
        UiEvent.Frame(FrameInfo(32, 16)),
        UiEvent.KeyDown(Key.Enter, false),
        UiEvent.MouseDown(MouseButton.Left, 120.0, 80.0),
        UiEvent.TextInput("你好")
    ]
    for (event in events) {
        match (event) {
            case UiEvent.Frame(info) => println("帧间隔 ${info.deltaMs} 毫秒")
            case UiEvent.KeyDown(_, repeat) => println("按键按下，重复=${repeat}")
            case UiEvent.MouseDown(_, x, y) => println("按下于 (${Int64(x)}, ${Int64(y)})")
            case UiEvent.TextInput(text) => println("输入 ${text}")
            case _ => ()
        }
    }
    // 输出:
    // 帧间隔 16 毫秒
    // 按键按下，重复=false
    // 按下于 (120, 80)
    // 输入 你好
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`Frame(FrameInfo)`](#frame) | 每渲染帧一次的合成计时事件。 |
| [`Quit`](#quit) | 应用退出请求。 |
| [`WindowResized(Int32, Int32)`](#windowresized) | 窗口尺寸变化，携带新的宽与高（窗口像素）。 |
| [`KeyDown(Key, Bool)`](#keydown) | 按键按下，`Bool` 为按键重复标志——按住按键产生的自动重复为 `true`。 |
| [`KeyUp(Key)`](#keyup) | 按键抬起。 |
| [`TextInput(String)`](#textinput) | 已合成的文本输入（含输入法），携带 UTF-8 字符串。 |
| [`MouseMove(Float32, Float32)`](#mousemove) | 指针移动到（x, y），逻辑像素。 |
| [`MouseDown(MouseButton, Float32, Float32)`](#mousedown) | 鼠标按键在（x, y）按下，坐标为逻辑像素。 |
| [`MouseUp(MouseButton, Float32, Float32)`](#mouseup) | 鼠标按键在（x, y）抬起，坐标为逻辑像素。 |
| [`MouseWheel(Float32, Float32, Float32, Float32)`](#mousewheel) | 滚轮滚动：字段顺序为（滚动量 X、滚动量 Y、指针 X、指针 Y）——两个滚动增量在前，指针位置在后。 |
| [`DropBegin`](#dropbegin) | 一组拖放开始。 |
| [`DropFile(String, Float32, Float32)`](#dropfile) | 文件被拖入，携带文件路径与落点坐标（逻辑像素）。 |
| [`DropText(String, Float32, Float32)`](#droptext) | 文本被拖入，携带文本内容与落点坐标（逻辑像素）。 |
| [`DropPosition(Float32, Float32)`](#dropposition) | 拖动过程中指针位置更新（逻辑像素）。 |
| [`DropComplete`](#dropcomplete) | 一组拖放结束。 |
| [`Unknown(UInt32)`](#unknown) | 未解码事件，携带原始 SDL 事件类型码，不会有事件被静默丢弃。 |

## 枚举值

### Frame

每渲染帧一次的合成计时事件。由应用的帧循环合成而非从 SDL 轮询，携带 [`FrameInfo`](FrameInfo.md)。

```cangjie
Frame(FrameInfo)
```

### Quit

应用退出请求。单窗口桌面应用在最后一个窗口的关闭按钮被按下时收到；窗口创建期间的 `SDL_EVENT_WINDOW_CLOSE_REQUESTED` 不映射为本事件（Windows 可能在创建时发出伪关闭请求）。

```cangjie
Quit
```

### WindowResized

窗口尺寸变化，携带新的宽与高（窗口像素）。

```cangjie
WindowResized(Int32, Int32)
```

### KeyDown

按键按下，`Bool` 为按键重复标志——按住按键产生的自动重复为 `true`。

```cangjie
KeyDown(Key, Bool)
```

### KeyUp

按键抬起。

```cangjie
KeyUp(Key)
```

### TextInput

已合成的文本输入（含输入法），携带 UTF-8 字符串。物理按键请通过 [`KeyDown`](#keydown) 处理。

```cangjie
TextInput(String)
```

### MouseMove

指针移动到（x, y），逻辑像素。

```cangjie
MouseMove(Float32, Float32)
```

### MouseDown

鼠标按键在（x, y）按下，坐标为逻辑像素。

```cangjie
MouseDown(MouseButton, Float32, Float32)
```

### MouseUp

鼠标按键在（x, y）抬起，坐标为逻辑像素。

```cangjie
MouseUp(MouseButton, Float32, Float32)
```

### MouseWheel

滚轮滚动：字段顺序为（滚动量 X、滚动量 Y、指针 X、指针 Y）——两个滚动增量在前，指针位置在后。

```cangjie
MouseWheel(Float32, Float32, Float32, Float32)
```

### DropBegin

一组拖放开始。其后跟随若干 `DropFile` / `DropText` / `DropPosition`，以 `DropComplete` 结束。

```cangjie
DropBegin
```

### DropFile

文件被拖入，携带文件路径与落点坐标（逻辑像素）。

```cangjie
DropFile(String, Float32, Float32)
```

### DropText

文本被拖入，携带文本内容与落点坐标（逻辑像素）。

```cangjie
DropText(String, Float32, Float32)
```

### DropPosition

拖动过程中指针位置更新（逻辑像素）。

```cangjie
DropPosition(Float32, Float32)
```

### DropComplete

一组拖放结束。

```cangjie
DropComplete
```

### Unknown

未解码事件，携带原始 SDL 事件类型码，不会有事件被静默丢弃。

```cangjie
Unknown(UInt32)
```

## 另请参阅

- [SdlWindow.pollEvent](SdlWindow.md#pollevent) — 事件的获取入口。
- [Key](Key.md) · [MouseButton](MouseButton.md) · [FrameInfo](FrameInfo.md) — 事件携带的数据类型。
