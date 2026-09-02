[API 参考](../index.md) › [sdl](index.md) › UiEvent

# UiEvent

由 SDL 事件解码得到的仓颉枚举。指针和拖放坐标使用逻辑像素；输入法提交的文字由 `TextInput` 提供。`Frame` 由应用合成，`Wake` 用于中断事件等待，`Unknown` 保留尚未解码的 SDL 事件类型。

```cangjie
public enum UiEvent {
    | Frame(FrameInfo)
    | Wake
    | Quit
    | WindowExposed
    | WindowResized(Int32, Int32)
    | WindowPixelSizeChanged(Int32, Int32)
    | WindowDisplayScaleChanged
    | WindowMinimized
    | WindowRestored
    | WindowFocusGained
    | WindowFocusLost
    | WindowCloseRequested
    | WindowOccluded
    | KeyDown(Key, Bool)
    | KeyUp(Key)
    | TextEditing(String, Int32, Int32)
    | TextEditingCandidates(Array<String>, Int32, Bool)
    | TextInput(String)
    | MouseMove(Float32, Float32)
    | MouseDown(MouseButton, Float32, Float32)
    | MouseUp(MouseButton, Float32, Float32)
    | MouseWheel(Float32, Float32, Float32, Float32)
    | DropBegin
    | DropFile(String, Float32, Float32)
    | DropText(String, Float32, Float32)
    | DropPosition(Float32, Float32)
    | DropComplete
    | RenderTargetsReset
    | RenderDeviceReset
    | RenderDeviceLost
    | Unknown(UInt32)
}
```

## 示例

```cangjie verify role=complete
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
            case UiEvent.KeyDown(_, repeat) => println("按键重复=${repeat}")
            case UiEvent.MouseDown(_, x, y) => println("按下于 ${x},${y}")
            case UiEvent.TextInput(text) => println("输入 ${text}")
            case _ => ()
        }
    }
}
```

## 生命周期与窗口事件

| 值 | 含义 |
|---|---|
| `Frame(FrameInfo)` | 应用为每个渲染帧合成的计时事件。 |
| `Wake` | `SdlWindow.wake()` 推送的唤醒信号；收到跨线程动作后可忽略事件本身。 |
| `Quit` | 进程级退出请求。 |
| `WindowExposed` | 窗口重新可见，按需渲染循环应安排重绘。 |
| `WindowResized(Int32, Int32)` | 窗口坐标尺寸变化；标准事件入口会先刷新 `window.width` 和 `height`。 |
| `WindowPixelSizeChanged(Int32, Int32)` | 后备像素尺寸变化；标准入口会同步显示尺度与渲染器状态。 |
| `WindowDisplayScaleChanged` | 窗口所在显示器的缩放发生变化。 |
| `WindowMinimized`、`WindowRestored` | 窗口最小化或恢复。 |
| `WindowFocusGained`、`WindowFocusLost` | 输入焦点变化；失焦时通常清理按压、拖拽和输入法临时状态。 |
| `WindowCloseRequested` | 当前窗口的关闭请求；多窗口程序按事件元数据的窗口 ID 路由。 |
| `WindowOccluded` | 窗口被完全遮挡，可暂停昂贵的连续绘制。 |

## 键盘与文字

| 值 | 含义 |
|---|---|
| `KeyDown(Key, Bool)` | 按键按下；`Bool` 表示是否为系统自动重复。 |
| `KeyUp(Key)` | 按键抬起。 |
| `TextEditing(String, Int32, Int32)` | 输入法尚未提交的临时文字及编辑范围。 |
| `TextEditingCandidates(Array<String>, Int32, Bool)` | 输入法候选列表、当前索引和排列方向。 |
| `TextInput(String)` | 已由键盘布局或输入法合成的 UTF-8 文字。 |

## 指针与拖放

| 值 | 含义 |
|---|---|
| `MouseMove(Float32, Float32)` | 指针移动到逻辑坐标 `(x, y)`。 |
| `MouseDown(MouseButton, Float32, Float32)` | 按键在逻辑坐标按下。 |
| `MouseUp(MouseButton, Float32, Float32)` | 按键在逻辑坐标抬起。 |
| `MouseWheel(Float32, Float32, Float32, Float32)` | 依次携带滚动量 X、滚动量 Y、指针 X、指针 Y。 |
| `DropBegin` | 一组拖放开始。 |
| `DropFile(String, Float32, Float32)` | 文件路径及落点。 |
| `DropText(String, Float32, Float32)` | 文字及落点。 |
| `DropPosition(Float32, Float32)` | 拖动过程中的位置。 |
| `DropComplete` | 一组拖放结束，此时再处理已收集的数据。 |

## 渲染设备事件

| 值 | 含义 |
|---|---|
| `RenderTargetsReset` | 渲染目标内容失效，应安排完整重绘。 |
| `RenderDeviceReset` | 渲染设备已重置，应从普通应用数据重建纹理和命令。 |
| `RenderDeviceLost` | 渲染设备丢失，处理方式与设备重置相同。 |
| `Unknown(UInt32)` | 未解码事件，保留 SDL 原始类型码。 |

`SdlWindow.pollEvent*`、`waitEvent*` 和 `SdlEventPump` 会在返回尺寸、DPI 或设备变化事件前更新窗口与渲染器状态。需要事件时间、来源窗口、原始键值或修饰键时，使用 [`UiEventRecord`](UiEventRecord.md)。
