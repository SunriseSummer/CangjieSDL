[sdl](../index.md) › [sdl](index.md) › UiEvent

# UiEvent

`sdl` 包中的 public enum

解码后的 SDL 输入事件，按到达顺序交给应用处理。指针坐标为逻辑像素。`TextEditing` 保存尚未提交的 IME pre-edit；窗口曝光/像素尺寸/DPI/焦点/关闭、渲染 target/device reset/lost 均有类型化枚举值。`Frame` 由应用帧循环合成；`Wake` 是内部唤醒信号；`Unknown` 携带仍未解码的 SDL 类型码。

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
| [`Wake`](#wake) | 由 `SdlWindow.wake()` 推送的事件等待唤醒信号。 |
| [`Quit`](#quit) | 应用退出请求。 |
| [`WindowExposed`](#windowexposed) | 窗口重新暴露，需要重绘。 |
| [`WindowResized(Int32, Int32)`](#windowresized) | 窗口坐标尺寸变化；标准窗口入口会同步权威逻辑尺寸。 |
| [`WindowPixelSizeChanged(Int32, Int32)`](#windowpixelsizechanged) | 后备像素尺寸变化。 |
| [`WindowDisplayScaleChanged`](#windowdisplayscalechanged) | 窗口所在显示器的尺度变化。 |
| [`WindowMinimized`](#windowminimized) / [`WindowRestored`](#windowrestored) | 最小化或恢复。 |
| [`WindowFocusGained`](#windowfocusgained) / [`WindowFocusLost`](#windowfocuslost) | 获得或失去输入焦点。 |
| [`WindowCloseRequested`](#windowcloserequested) | 指定窗口的关闭请求。 |
| [`WindowOccluded`](#windowoccluded) | 窗口被完全遮挡。 |
| [`KeyDown(Key, Bool)`](#keydown) | 按键按下，`Bool` 为按键重复标志——按住按键产生的自动重复为 `true`。 |
| [`KeyUp(Key)`](#keyup) | 按键抬起。 |
| [`TextEditing(String, Int32, Int32)`](#textediting) | 尚未提交的 IME pre-edit 及 SDL 编辑范围。 |
| [`TextEditingCandidates(Array<String>, Int32, Bool)`](#texteditingcandidates) | IME 候选、选中项与排列方向。 |
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
| [`RenderTargetsReset`](#rendertargetsreset) | 渲染目标内容失效。 |
| [`RenderDeviceReset`](#renderdevicereset) | 渲染设备已重置。 |
| [`RenderDeviceLost`](#renderdevicelost) | 渲染设备丢失。 |
| [`Unknown(UInt32)`](#unknown) | 未解码事件，携带原始 SDL 事件类型码，不会有事件被静默丢弃。 |

## 枚举值

### Frame

每渲染帧一次的合成计时事件。由应用的帧循环合成而非从 SDL 轮询，携带 [`FrameInfo`](FrameInfo.md)。

```cangjie
Frame(FrameInfo)
```

### Wake

由 `SdlWindow.wake()` 推送；自定义 shell 可在收取跨线程动作后忽略该事件本身。

```cangjie
Wake
```

### Quit

进程级应用退出请求。某个具体窗口的标题栏关闭按钮使用 [`WindowCloseRequested`](#windowcloserequested)，多窗口程序应按事件元数据的 `windowId` 决定关闭哪一个窗口。

```cangjie
Quit
```

### WindowExposed

窗口从遮挡、移动或恢复状态重新暴露；按需渲染循环应安排重绘。

```cangjie
WindowExposed
```

### WindowResized

窗口坐标尺寸变化，携带 SDL 事件值。`SdlWindow.pollEvent*` / `waitEvent*` 和 `SdlEventPump` 会先调用权威尺寸查询并更新 `window.width` / `height`；布局应读取窗口字段，不要把事件载荷当后备像素。

```cangjie
WindowResized(Int32, Int32)
```

### WindowPixelSizeChanged

窗口后备像素尺寸变化。标准窗口事件入口会同时刷新动态显示尺度与 Renderer epoch。

```cangjie
WindowPixelSizeChanged(Int32, Int32)
```

### WindowDisplayScaleChanged

窗口跨显示器或系统设置变化导致显示尺度改变。标准入口会自动执行 `refreshDisplayMetrics()`。

```cangjie
WindowDisplayScaleChanged
```

### WindowMinimized

```cangjie
WindowMinimized
```

### WindowRestored

窗口从最小化或其它隐藏状态恢复；按需渲染循环应安排一帧。

```cangjie
WindowRestored
```

### WindowFocusGained

```cangjie
WindowFocusGained
```

### WindowFocusLost

窗口失去输入焦点。应用通常在这里取消按压、拖拽、持续按键和未提交 IME 状态。

```cangjie
WindowFocusLost
```

### WindowCloseRequested

指定窗口的关闭请求。多窗口程序读取 [`UiEventMetadata.windowId`](UiEventMetadata.md) 路由；不要把它无条件等同于整个进程退出。

```cangjie
WindowCloseRequested
```

### WindowOccluded

窗口被完全遮挡；可用于暂停昂贵的持续绘制，重新暴露时由 `WindowExposed` 恢复。

```cangjie
WindowOccluded
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

### TextEditing

输入法尚未提交的 pre-edit 文本，以及 SDL 提供的编辑/选择范围。只用于临时绘制，不要写入应用最终文本；提交内容随后以 `TextInput` 到达。

```cangjie
TextEditing(String, Int32, Int32)
```

### TextEditingCandidates

输入法候选字符串、选中索引及是否水平排列。候选数组可能为空，平台也可能不发送此事件。

```cangjie
TextEditingCandidates(Array<String>, Int32, Bool)
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

### RenderTargetsReset

渲染目标内容失效。标准窗口事件入口会推进 Renderer 设备 epoch；应用应重绘，不得继续依赖旧目标内容。

```cangjie
RenderTargetsReset
```

### RenderDeviceReset

渲染设备已重置。Renderer 创建的旧 Texture、命令缓冲和测量会话会因 owner/epoch 校验失效；应用从可重建的源资源重新创建 GPU 对象。

```cangjie
RenderDeviceReset
```

### RenderDeviceLost

渲染设备丢失，处理原则与 `RenderDeviceReset` 相同；安排恢复帧并重新上传应用拥有的资源。

```cangjie
RenderDeviceLost
```

### Unknown

未解码事件，携带原始 SDL 事件类型码，不会有事件被静默丢弃。

```cangjie
Unknown(UInt32)
```

## 另请参阅

- [SdlWindow.pollEvent](SdlWindow.md#pollevent) — 事件的获取入口。
- [UiEventRecord](UiEventRecord.md) — 保存事件时刻元数据，避免延迟派发时读取到后来变化的全局键盘状态。
- [SdlEventPump](SdlEventPump.md) — 多窗口应用的进程级事件入口。
- [Key](Key.md) · [MouseButton](MouseButton.md) · [FrameInfo](FrameInfo.md) — 事件携带的数据类型。
