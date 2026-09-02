[sdl](../index.md) › [sdl](index.md) › WindowSpec

# WindowSpec

位于 `sdl` 包的公开结构体。

创建窗口时使用的一次性选项，包括标题、逻辑尺寸、DPI、应用缩放、垂直同步和超采样。它是值类型，[`SdlWindow`](SdlWindow.md) 构造时读取一次。

## 声明

```cangjie
public struct WindowSpec
```

## 关键选项

- `scale` 是应用层的逻辑缩放，非正值按 1.0 处理。
- `highDpi` 决定是否请求高像素密度窗口，实际密度仍由平台和显示器决定。
- `vsync` 默认开启，使画面提交等待垂直回扫并减少撕裂。性能基准可以关闭它，避免刷新周期掩盖每帧耗时差异。
- `supersample` 默认是 0，表示自动选择。物理密度不足 2 像素/逻辑单位时尝试 2 倍，否则使用 1 倍；自动方案还必须满足 32 Mi 个目标像素和硬件最大纹理边长限制。
- 正的 `supersample` 是显式倍率，`1` 表示关闭。显式值不受框架像素预算限制，但尺寸溢出、硬件限制或资源分配失败时仍会安全退回直接绘制。负值按 1 倍处理。

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
| [`vsync`](#vsync) | 画面提交是否等待垂直回扫；默认 `true`。 |
| [`supersample`](#supersample) | 每轴超采样请求；默认 0 表示自动选择，正数表示显式倍率。 |

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
- `supersample!`: `Int32` — 每轴超采样请求；默认 0 表示有 32 Mi 像素预算的自动模式，正数表示显式倍率，负值按 1 倍处理。

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
