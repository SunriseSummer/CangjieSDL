[sdl](../index.md) › [sdl](index.md) › WindowSpec

# WindowSpec

`sdl` 包中的 public struct

创建窗口时的一次性选项：标题、逻辑尺寸、DPI 与缩放行为、垂直同步和渲染器的超采样倍数。纯值类型，[`SdlWindow`](SdlWindow.md) 构造时读取一次；创建之后修改 spec 对窗口无影响。

## 声明

```cangjie
public struct WindowSpec
```

## 说明

`vsync` 控制渲染器 present 时是否等待垂直回扫：开（默认）避免撕裂，是真实应用的正确选择；关让帧循环不设上限地运行——基准测量真实每帧开销时用，因为 vsync 开启时每帧周期都吸附到刷新周期的整数倍，小于一个刷新间隔的改进不可见。`supersample` 是每轴超采样请求：默认 `0` 为 Auto，在每逻辑单位不足 2 个物理后备像素时尝试 2x，否则选择 1x；2x 目标还必须不超过 32 Mi 像素和 SDL 报告的最大纹理边长，尺寸/DPI 变化时会重新选择。正数是精确覆盖（`1` = 关闭，`2` = 4 倍像素），不受框架像素预算限制，适合质量对照与有明确画质策略的应用；算术、硬件或分配不可行时仍安全回退。负值为兼容起见按 1x 处理。`scale` 非正时按 1.0 处理。

## 示例

```cangjie verify
package docexample

import sdl.{Color, Rect, SdlWindow, UiEvent, WindowSpec}

main(): Unit {
    let spec = WindowSpec("绘图板", 1024, 640, resizable: false, vsync: false, supersample: 1)
    try (window = SdlWindow(spec)) {
        var running = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case _ => ()
                }
            }
            if (!running) {
                break
            }
            let renderer = window.renderer
            renderer.beginScene(Float32(window.width), Float32(window.height), Color.rgb(30, 30, 46))
            renderer.fillRoundedRect(Rect(48.0, 48.0, 240.0, 120.0), 16.0, Color.rgb(64, 128, 255))
            renderer.endScene()
            renderer.present()
            window.delay(16)
        }
    }
    // 运行后会打开不可调整大小的绘图板窗口；点击关闭按钮退出。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(title: String, width: Int32, height: Int32, ...)`](#init) | 由标题与逻辑尺寸构造，其余项为带默认值的命名参数。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`title`](#title) | 窗口标题。 |
| [`width`](#width) | 逻辑宽度。 |
| [`height`](#height) | 逻辑高度。 |
| [`resizable`](#resizable) | 是否可调节大小；默认 `true`。 |
| [`highDpi`](#highdpi) | 是否请求高像素密度后备缓冲；默认 `true`。 |
| [`scale`](#scale) | 逻辑像素到窗口像素的缩放比；默认 1.0，非正值按 1.0 处理。 |
| [`vsync`](#vsync) | present 是否等待垂直回扫；默认 `true`。 |
| [`supersample`](#supersample) | 每轴超采样请求；默认 0（按物理密度 Auto），正数为精确倍数。 |

## 构造函数

### init

由标题与逻辑尺寸构造，其余项为带默认值的命名参数。

```cangjie
public init(title: String, width: Int32, height: Int32, resizable!: Bool = true, highDpi!: Bool = true, scale!: Float32 = 1.0, vsync!: Bool = true, supersample!: Int32 = 0)
```

**参数**

- `title`: `String` — 窗口标题。
- `width`、`height`: `Int32` — 逻辑尺寸；窗口像素 = 逻辑尺寸 × `scale`。
- `resizable!`: `Bool` — 可调节大小；默认 `true`。
- `highDpi!`: `Bool` — 请求高像素密度；默认 `true`。
- `scale!`: `Float32` — 逻辑到窗口像素的缩放比；默认 1.0，非正值按 1.0 处理。
- `vsync!`: `Bool` — 等待垂直回扫；默认 `true`。
- `supersample!`: `Int32` — 每轴超采样请求；默认 0 为有 32 Mi 像素预算的 Auto（物理密度 < 2 时尝试 2x，否则 1x），正数为不受框架像素预算限制的精确覆盖，负值按 1x 处理。

## 字段

### title

窗口标题。

```cangjie
public let title: String
```

### width

逻辑宽度。

```cangjie
public let width: Int32
```

### height

逻辑高度。

```cangjie
public let height: Int32
```

### resizable

是否可调节大小；默认 `true`。

```cangjie
public let resizable: Bool
```

### highDpi

是否请求高像素密度后备缓冲；默认 `true`。

```cangjie
public let highDpi: Bool
```

### scale

逻辑像素到窗口像素的缩放比；默认 1.0，非正值按 1.0 处理。

```cangjie
public let scale: Float32
```

### vsync

present 是否等待垂直回扫；默认 `true`。关闭后帧循环不设上限，用于基准测量。

```cangjie
public let vsync: Bool
```

### supersample

渲染器每轴超采样请求。默认 `0` 让渲染器按动态物理后备密度、32 Mi 像素预算和硬件纹理边长选择 1x 或 2x；正数固定请求指定倍数，`1` 为关闭。字段保存的是请求值；实际选择与资源原因由 [`Renderer.supersampleFactor`](Renderer.md#supersamplefactor) 和 [`Renderer.renderSamplingStats`](Renderer.md#rendersamplingstats) 返回。

```cangjie
public let supersample: Int32
```

## 另请参阅

- [SdlWindow](SdlWindow.md) — 消费本选项创建窗口。
- [Renderer.supersampleFactor](Renderer.md#supersamplefactor) — 查询生效的超采样倍数。
- [Renderer.renderSamplingStats](Renderer.md#rendersamplingstats) — 查询目标尺寸、估算显存和降级原因。
