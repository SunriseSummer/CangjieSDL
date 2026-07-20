[sdl](../index.md) › [sdl](index.md) › SdlWindow

# SdlWindow

`sdl` 包中的 public class

与自己的[渲染器](Renderer.md)成对创建、成对关闭的 SDL 窗口。`width`/`height` 与全部事件、绘制坐标都是逻辑像素，`scale` 把它们映射到窗口像素。构造函数初始化视频子系统并开启文本输入，失败抛 `CuiException`；[`close`](#close) 幂等，释放渲染器、窗口与一个视频子系统引用——SDL3 对子系统初始化计数，关掉一个窗口不会拆掉另一个仍开着的窗口的子系统。除明确以空值或布尔值表示状态的查询外，SDL 拒绝窗口设置或无法完成带错误状态的查询时，方法会把失败状态转换为 `CuiException`。

## 声明

```cangjie
public class SdlWindow <: Resource
```

## 继承

- `Resource`（标准库 `std.core`）——支持 `try (…)` 资源语法。

## 示例

```cangjie verify
package docexample

import sdl.{Color, SdlWindow, UiEvent, WindowSpec}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时打开窗口并跑最小事件循环，
    // 点击关闭按钮后退出。
    try (window = SdlWindow(WindowSpec("演示", 800, 600))) {
        var running = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case _ => ()
                }
            }
            let r = window.renderer
            r.beginScene(Float32(window.width), Float32(window.height), Color.rgb(30, 30, 46))
            r.endScene()
            r.present()
            window.delay(16)
        }
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(spec: WindowSpec)`](#init) | 按 `WindowSpec` 创建窗口与渲染器，并开启文本输入。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`width`](#width) | 逻辑宽度；`setSize`/`refreshSize` 时更新。 |
| [`height`](#height) | 逻辑高度；`setSize`/`refreshSize` 时更新。 |
| [`scale`](#scale) | 逻辑像素到窗口像素的缩放比，创建后固定。 |
| [`renderer`](#renderer) | 与窗口同生命周期的`渲染器`；`close` 时随窗口一同释放。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`setTitle(title: String)`](#settitle) | 设置窗口标题。 |
| [`setSize(width: Int32, height: Int32)`](#setsize) | 按逻辑尺寸调整窗口大小（内部乘以 `scale` 转为窗口像素），并更新 `width`/`height` 字段。 |
| [`refreshSize()`](#refreshsize) | 从 SDL 重新读取窗口尺寸（除以 `scale` 转回逻辑像素）并更新 `width`/`height` 字段。 |
| [`setTextInputArea(rect: Rect)`](#settextinputarea) | 告知系统文本光标所在区域（窗口逻辑像素，与事件、绘制同空间），输入法候选窗随之出现在光标旁而不是屏幕角落。 |
| [`pollEvent()`](#pollevent) | 取出一条已解码事件；队列空时为 `None`。 |
| [`ticks()`](#ticks) | SDL 初始化以来的毫秒数。 |
| [`delay(ms: UInt32)`](#delay) | 阻塞等待指定毫秒。 |
| [`isClosed()`](#isclosed) | 判断窗口是否已关闭。 |
| [`close()`](#close) | 关闭窗口：释放渲染器资源、停止文本输入、销毁渲染器与窗口，并归还一个视频子系统引用。 |

**扩展成员**

| 成员 | 说明 |
|---|---|
| [`setPosition(x: Int32, y: Int32)`](#setposition) | 移动窗口到屏幕坐标。 |
| [`position()`](#position) | 查询窗口左上角的屏幕坐标。 |
| [`setMinimumSize(width: Int32, height: Int32)`](#setminimumsize) | 设置最小逻辑尺寸（内部乘以 `scale`）。 |
| [`setMaximumSize(width: Int32, height: Int32)`](#setmaximumsize) | 设置最大逻辑尺寸（内部乘以 `scale`）。 |
| [`setBordered(bordered: Bool)`](#setbordered) | 显示或隐藏窗口边框。 |
| [`setResizable(resizable: Bool)`](#setresizable) | 允许或禁止调节大小。 |
| [`setAlwaysOnTop(onTop: Bool)`](#setalwaysontop) | 置顶或取消置顶。 |
| [`setOpacity(opacity: Float32)`](#setopacity) | 设置整窗不透明度，输入限制在 [0, 1]。 |
| [`show()`](#show) | 显示窗口。 |
| [`hide()`](#hide) | 隐藏窗口。 |
| [`raiseWindow()`](#raisewindow) | 把窗口提到前台并请求焦点。 |
| [`maximize()`](#maximize) | 最大化。 |
| [`minimize()`](#minimize) | 最小化。 |
| [`restore()`](#restore) | 从最大化/最小化恢复。 |
| [`setFullscreen(fullscreen: Bool)`](#setfullscreen) | 进入或退出全屏。 |
| [`sync()`](#sync) | 等待窗口状态操作（移动、缩放、全屏切换等异步请求）真正落地。 |
| [`flash(operation!: WindowFlash)`](#flash) | 闪烁窗口/任务栏图标提醒用户。 |
| [`setRelativeMouseMode(enabled: Bool)`](#setrelativemousemode) | 开关相对鼠标模式：隐藏光标并报告相对位移，第一人称视角控制的输入形态。 |
| [`title()`](#title) | 查询窗口标题；SDL 未返回时为空串。 |
| [`windowFlags()`](#windowflags) | 查询窗口状态标志位快照。 |
| [`sizeInPixels()`](#sizeinpixels) | 查询后备缓冲的像素尺寸（高像素密度下大于逻辑尺寸 × `scale`）。 |
| [`safeArea()`](#safearea) | 查询可安全放置交互内容的区域（避开刘海、圆角等遮挡），窗口像素坐标。 |
| [`minimumSize()`](#minimumsize) | 查询最小逻辑尺寸（内部除以 `scale`）；未设置时为 0。 |
| [`maximumSize()`](#maximumsize) | 查询最大逻辑尺寸（内部除以 `scale`）；未设置时为 0。 |
| [`borderSize()`](#bordersize) | 查询窗口装饰四向尺寸。 |
| [`setAspectRatio(minimum: Float32, maximum: Float32)`](#setaspectratio) | 约束窗口宽高比。 |
| [`aspectRatio()`](#aspectratio) | 查询宽高比约束。 |
| [`opacity()`](#opacity) | 查询整窗不透明度。 |
| [`pixelDensity()`](#pixeldensity) | 查询像素密度（窗口像素 / 逻辑单位，HiDPI 下大于 1）。 |
| [`displayScale()`](#displayscale) | 查询窗口所在显示器建议的内容缩放。 |
| [`setFillDocument(fill: Bool)`](#setfilldocument) | 开关填充文档模式（SDL_WINDOW_FILL_DOCUMENT）。 |
| [`setKeyboardGrab(grabbed: Bool)`](#setkeyboardgrab) | 独占或释放键盘（连系统快捷键一并送达窗口）。 |
| [`setMouseGrab(grabbed: Bool)`](#setmousegrab) | 把鼠标约束在窗口内或释放。 |
| [`keyboardGrabbed()`](#keyboardgrabbed) | 查询键盘是否被独占。 |
| [`mouseGrabbed()`](#mousegrabbed) | 查询鼠标是否被约束。 |
| [`setMouseGrabRect(rect: ?Rect)`](#setmousegrabrect) | 把鼠标约束到窗口内的矩形；`None` 取消矩形约束。 |
| [`mouseGrabRect()`](#mousegrabrect) | 查询鼠标约束矩形；未设置时为 `None`。 |
| [`setFocusable(focusable: Bool)`](#setfocusable) | 允许或禁止窗口获得焦点。 |
| [`showSystemMenu(x: Int32, y: Int32)`](#showsystemmenu) | 在指定位置弹出系统窗口菜单（标题栏右键菜单）。 |
| [`setProgressState(state: WindowProgressState)`](#setprogressstate) | 设置任务栏进度指示状态。 |
| [`progressState()`](#progressstate) | 查询任务栏进度指示状态。 |
| [`setProgressValue(value: Float32)`](#setprogressvalue) | 设置任务栏进度值，输入限制在 [0, 1]。 |
| [`progressValue()`](#progressvalue) | 查询任务栏进度值。 |

## 构造函数

### init

按 [`WindowSpec`](WindowSpec.md) 创建窗口与渲染器，并开启文本输入。内部完成 `SDL_Init(VIDEO)`、窗口与渲染器创建、混合模式与 vsync 配置；任何一步失败都先释放已创建的资源再抛出。

```cangjie
public init(spec: WindowSpec)
```

**参数**

- `spec`: `WindowSpec` — 标题、逻辑尺寸、缩放、vsync 与超采样等一次性选项。

**异常**

- `CuiException` — SDL 无法创建或初始化窗口、渲染器或文本输入时。

## 字段

### width

逻辑宽度；[`setSize`](#setsize)/[`refreshSize`](#refreshsize) 时更新。

```cangjie
public var width: Int32
```

### height

逻辑高度；[`setSize`](#setsize)/[`refreshSize`](#refreshsize) 时更新。

```cangjie
public var height: Int32
```

### scale

逻辑像素到窗口像素的缩放比，创建后固定。事件坐标已除以该值。

```cangjie
public let scale: Float32
```

### renderer

与窗口同生命周期的[渲染器](Renderer.md)；[`close`](#close) 时随窗口一同释放。

```cangjie
public let renderer: Renderer
```

## 方法

### setTitle

设置窗口标题。

```cangjie
public func setTitle(title: String): Unit
```

**参数**

- `title`: `String` — 新标题，UTF-8。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setSize

按逻辑尺寸调整窗口大小（内部乘以 `scale` 转为窗口像素），并更新 `width`/`height` 字段。

```cangjie
public func setSize(width: Int32, height: Int32): Unit
```

**参数**

- `width`、`height`: `Int32` — 新的逻辑尺寸。

**异常**

- `CuiException` — SDL 拒绝调整时。

### refreshSize

从 SDL 重新读取窗口尺寸（除以 `scale` 转回逻辑像素）并更新 `width`/`height` 字段。处理 [`UiEvent.WindowResized`](UiEvent.md#windowresized) 后调用。

```cangjie
public func refreshSize(): Size
```

**返回值** `Size` — 刷新后的逻辑尺寸。

**异常**

- `CuiException` — SDL 查询失败时。

### setTextInputArea

告知系统文本光标所在区域（窗口逻辑像素，与事件、绘制同空间），输入法候选窗随之出现在光标旁而不是屏幕角落。到窗口像素的换算在方法内部完成。

```cangjie
public func setTextInputArea(rect: Rect): Unit
```

**参数**

- `rect`: `Rect` — 光标区域，逻辑像素。

**异常**

- `CuiException` — SDL 拒绝设置时。

### pollEvent

取出一条已解码事件；队列空时为 `None`。指针坐标已除以 `scale`，与布局、绘制处于同一逻辑像素空间。

```cangjie
public func pollEvent(): ?UiEvent
```

**返回值** `?UiEvent` — 下一条事件，或 `None`。

### ticks

SDL 初始化以来的毫秒数。

```cangjie
public func ticks(): UInt64
```

**返回值** `UInt64` — 毫秒计时。

### delay

阻塞等待指定毫秒。

```cangjie
public func delay(ms: UInt32): Unit
```

**参数**

- `ms`: `UInt32` — 等待的毫秒数。

### isClosed

判断窗口是否已关闭。

```cangjie
public func isClosed(): Bool
```

**返回值** `Bool` — [`close`](#close) 调用之后为 `true`。

### close

关闭窗口：释放渲染器资源、停止文本输入、销毁渲染器与窗口，并归还一个视频子系统引用。幂等，重复调用为空操作；两个窗口并存时关掉一个不影响另一个。

```cangjie
public func close(): Unit
```

## 扩展成员

### setPosition

移动窗口到屏幕坐标。

```cangjie
public func setPosition(x: Int32, y: Int32): Unit
```

**参数**

- `x`、`y`: `Int32` — 屏幕坐标。

**异常**

- `CuiException` — SDL 拒绝移动时。

### position

查询窗口左上角的屏幕坐标。

```cangjie
public func position(): WindowPosition
```

**返回值** `WindowPosition` — 屏幕坐标。

**异常**

- `CuiException` — SDL 查询失败时。

### setMinimumSize

设置最小逻辑尺寸（内部乘以 `scale`）。

```cangjie
public func setMinimumSize(width: Int32, height: Int32): Unit
```

**参数**

- `width`、`height`: `Int32` — 最小逻辑尺寸。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setMaximumSize

设置最大逻辑尺寸（内部乘以 `scale`）。

```cangjie
public func setMaximumSize(width: Int32, height: Int32): Unit
```

**参数**

- `width`、`height`: `Int32` — 最大逻辑尺寸。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setBordered

显示或隐藏窗口边框。

```cangjie
public func setBordered(bordered: Bool): Unit
```

**参数**

- `bordered`: `Bool` — `false` 为无边框。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setResizable

允许或禁止调节大小。

```cangjie
public func setResizable(resizable: Bool): Unit
```

**参数**

- `resizable`: `Bool` — 是否可调节。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setAlwaysOnTop

置顶或取消置顶。

```cangjie
public func setAlwaysOnTop(onTop: Bool): Unit
```

**参数**

- `onTop`: `Bool` — 是否置顶。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setOpacity

设置整窗不透明度，输入限制在 [0, 1]。

```cangjie
public func setOpacity(opacity: Float32): Unit
```

**参数**

- `opacity`: `Float32` — 0 全透明、1 不透明；小于 0 按 0、大于 1 按 1 处理。

**异常**

- `CuiException` — SDL 拒绝设置时。

### show

显示窗口。

```cangjie
public func show(): Unit
```

**异常**

- `CuiException` — SDL 拒绝操作时。

### hide

隐藏窗口。

```cangjie
public func hide(): Unit
```

**异常**

- `CuiException` — SDL 拒绝操作时。

### raiseWindow

把窗口提到前台并请求焦点。

```cangjie
public func raiseWindow(): Unit
```

**异常**

- `CuiException` — SDL 拒绝操作时。

### maximize

最大化。

```cangjie
public func maximize(): Unit
```

**异常**

- `CuiException` — SDL 拒绝操作时。

### minimize

最小化。

```cangjie
public func minimize(): Unit
```

**异常**

- `CuiException` — SDL 拒绝操作时。

### restore

从最大化/最小化恢复。

```cangjie
public func restore(): Unit
```

**异常**

- `CuiException` — SDL 拒绝操作时。

### setFullscreen

进入或退出全屏。

```cangjie
public func setFullscreen(fullscreen: Bool): Unit
```

**参数**

- `fullscreen`: `Bool` — `true` 进入全屏。

**异常**

- `CuiException` — SDL 拒绝切换时。

### sync

等待窗口状态操作（移动、缩放、全屏切换等异步请求）真正落地。

```cangjie
public func sync(): Unit
```

**异常**

- `CuiException` — SDL 同步失败时。

### flash

闪烁窗口/任务栏图标提醒用户。

```cangjie
public func flash(operation!: WindowFlash = WindowFlash.Briefly): Unit
```

**参数**

- `operation!`: `WindowFlash` — 闪烁方式；默认值为 `WindowFlash.Briefly`，即短促闪烁一次。

**异常**

- `CuiException` — SDL 拒绝操作时。

### setRelativeMouseMode

开关相对鼠标模式：隐藏光标并报告相对位移，第一人称视角控制的输入形态。

```cangjie
public func setRelativeMouseMode(enabled: Bool): Unit
```

**参数**

- `enabled`: `Bool` — 是否开启。

**异常**

- `CuiException` — SDL 拒绝切换时。

### title

查询窗口标题；SDL 未返回时为空串。

```cangjie
public func title(): String
```

**返回值** `String` — 当前标题。

### windowFlags

查询窗口状态标志位快照。

```cangjie
public func windowFlags(): WindowFlags
```

**返回值** `WindowFlags` — 展开为逐项布尔的标志位。

### sizeInPixels

查询后备缓冲的像素尺寸（高像素密度下大于逻辑尺寸 × `scale`）。

```cangjie
public func sizeInPixels(): Size
```

**返回值** `Size` — 像素尺寸。

**异常**

- `CuiException` — SDL 查询失败时。

### safeArea

查询可安全放置交互内容的区域（避开刘海、圆角等遮挡），窗口像素坐标。

```cangjie
public func safeArea(): Rect
```

**返回值** `Rect` — 安全区域。

**异常**

- `CuiException` — SDL 查询失败时。

### minimumSize

查询最小逻辑尺寸（内部除以 `scale`）；未设置时为 0。

```cangjie
public func minimumSize(): Size
```

**返回值** `Size` — 最小逻辑尺寸。

**异常**

- `CuiException` — SDL 查询失败时。

### maximumSize

查询最大逻辑尺寸（内部除以 `scale`）；未设置时为 0。

```cangjie
public func maximumSize(): Size
```

**返回值** `Size` — 最大逻辑尺寸。

**异常**

- `CuiException` — SDL 查询失败时。

### borderSize

查询窗口装饰四向尺寸。

```cangjie
public func borderSize(): WindowBorderSize
```

**返回值** `WindowBorderSize` — 标题栏与边框的像素尺寸。

**异常**

- `CuiException` — SDL 查询失败时。

### setAspectRatio

约束窗口宽高比。两个参数皆为 0 表示取消约束。

```cangjie
public func setAspectRatio(minimum: Float32, maximum: Float32): Unit
```

**参数**

- `minimum`: `Float32` — 最小宽高比；0 为不限制，不可为负。
- `maximum`: `Float32` — 最大宽高比；0 为不限制，不可为负。

**异常**

- `CuiException` — 任一值为负、`minimum` 超过 `maximum`（两者皆为正时），或 SDL 拒绝设置时。

### aspectRatio

查询宽高比约束。

```cangjie
public func aspectRatio(): WindowAspectRatio
```

**返回值** `WindowAspectRatio` — 当前约束；0 表示对应方向不限制。

**异常**

- `CuiException` — SDL 查询失败时。

### opacity

查询整窗不透明度。

```cangjie
public func opacity(): Float32
```

**返回值** `Float32` — 0–1 的不透明度。

**异常**

- `CuiException` — SDL 查询失败时。

### pixelDensity

查询像素密度（窗口像素 / 逻辑单位，HiDPI 下大于 1）。

```cangjie
public func pixelDensity(): Float32
```

**返回值** `Float32` — 像素密度，恒为正。

**异常**

- `CuiException` — SDL 报告非正值时。

### displayScale

查询窗口所在显示器建议的内容缩放。

```cangjie
public func displayScale(): Float32
```

**返回值** `Float32` — 建议缩放，恒为正。

**异常**

- `CuiException` — SDL 报告非正值时。

### setFillDocument

开关填充文档模式（SDL_WINDOW_FILL_DOCUMENT）。

```cangjie
public func setFillDocument(fill: Bool): Unit
```

**参数**

- `fill`: `Bool` — 是否开启。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setKeyboardGrab

独占或释放键盘（连系统快捷键一并送达窗口）。

```cangjie
public func setKeyboardGrab(grabbed: Bool): Unit
```

**参数**

- `grabbed`: `Bool` — 是否独占。

**异常**

- `CuiException` — SDL 拒绝设置时。

### setMouseGrab

把鼠标约束在窗口内或释放。

```cangjie
public func setMouseGrab(grabbed: Bool): Unit
```

**参数**

- `grabbed`: `Bool` — 是否约束。

**异常**

- `CuiException` — SDL 拒绝设置时。

### keyboardGrabbed

查询键盘是否被独占。

```cangjie
public func keyboardGrabbed(): Bool
```

**返回值** `Bool` — 独占中为 `true`。

### mouseGrabbed

查询鼠标是否被约束。

```cangjie
public func mouseGrabbed(): Bool
```

**返回值** `Bool` — 约束中为 `true`。

### setMouseGrabRect

把鼠标约束到窗口内的矩形；`None` 取消矩形约束。

```cangjie
public func setMouseGrabRect(rect: ?Rect): Unit
```

**参数**

- `rect`: `?Rect` — 约束矩形（窗口坐标）；`None` 取消。

**异常**

- `CuiException` — SDL 拒绝设置时。

### mouseGrabRect

查询鼠标约束矩形；未设置时为 `None`。

```cangjie
public func mouseGrabRect(): ?Rect
```

**返回值** `?Rect` — 约束矩形，或 `None`。

### setFocusable

允许或禁止窗口获得焦点。

```cangjie
public func setFocusable(focusable: Bool): Unit
```

**参数**

- `focusable`: `Bool` — 是否可获得焦点。

**异常**

- `CuiException` — SDL 拒绝设置时。

### showSystemMenu

在指定位置弹出系统窗口菜单（标题栏右键菜单）。

```cangjie
public func showSystemMenu(x: Int32, y: Int32): Unit
```

**参数**

- `x`、`y`: `Int32` — 弹出位置，窗口坐标。

**异常**

- `CuiException` — SDL 拒绝操作时。

### setProgressState

设置任务栏进度指示状态。

```cangjie
public func setProgressState(state: WindowProgressState): Unit
```

**参数**

- `state`: `WindowProgressState` — 目标状态。

**异常**

- `CuiException` — SDL 拒绝设置时。

### progressState

查询任务栏进度指示状态。

```cangjie
public func progressState(): WindowProgressState
```

**返回值** `WindowProgressState` — 当前状态。

**异常**

- `CuiException` — SDL 返回无效状态时。

### setProgressValue

设置任务栏进度值，输入限制在 [0, 1]。

```cangjie
public func setProgressValue(value: Float32): Unit
```

**参数**

- `value`: `Float32` — 进度；小于 0 按 0、大于 1 按 1 处理。

**异常**

- `CuiException` — SDL 拒绝设置时。

### progressValue

查询任务栏进度值。

```cangjie
public func progressValue(): Float32
```

**返回值** `Float32` — 0–1 的进度。

**异常**

- `CuiException` — SDL 查询失败时。

## 另请参阅

- [WindowSpec](WindowSpec.md) — 创建选项。
- [Renderer](Renderer.md) — 窗口的二维绘制入口。
- [UiEvent](UiEvent.md) — `pollEvent` 返回的事件。
- [WindowFlash](WindowFlash.md) · [WindowFlags](WindowFlags.md) · [WindowProgressState](WindowProgressState.md) — 扩展成员的参数与返回类型。
