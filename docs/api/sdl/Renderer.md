[sdl](../index.md) › [sdl](index.md) › Renderer

# Renderer

`sdl` 包中的 public class

窗口的二维绘制入口：绘制几何、文本和纹理，并管理视口与裁剪。所有坐标为逻辑像素。实例随 [`SdlWindow`](SdlWindow.md) 一同创建（`window.renderer`），或用 [`headless`](#headless) 得到无设备实例。

## 声明

```cangjie
public class Renderer
```

## 说明

[`beginScene`](#beginscene) / [`endScene`](#endscene) / [`present`](#present) 包住一帧。超采样开启时，场景先绘制到窗口 `supersampleFactor()` 倍大的离屏目标，present 前线性缩小一次回窗口——一步完成对全部图元的抗锯齿；文本按实际像素尺寸栅格化并 1:1 绘制，保持锐利。

无头渲染器（[`headless`](#headless)）没有 SDL 设备：全部绘制调用为空操作，文本测量回退到比例估算（粗体略加宽，结果确定可断言），这让布局与事件代码可以离屏测试。逻辑裁剪栈无头时依旧生效并可查询。

`Renderer` 由窗口持有，不单独关闭。关闭 [`SdlWindow`](SdlWindow.md#close) 时，会先释放渲染器内部的超采样目标、文本纹理缓存和几何缓冲，再销毁 SDL 渲染器；这一步可重复执行而不会重复释放资源。

SDL 的失败状态会影响本次设置、查询、纹理绘制或像素读回时，`Renderer` 将其转换为 `CuiException`；明确说明为空操作或返回估算值的无头路径不调用 SDL。

文本走独立的绘制通路：字形按有效像素尺寸（`pointSize` × 当前缩放）由 FreeType 栅格化，在对齐到物理像素的位置上 1:1 绘制——先按逻辑尺寸栅格化再被渲染缩放拉伸会让每个字形被重采样两次，明显发虚。旋转文本（[`textRotated`](#textrotated)）整串栅格化进纹理并跨帧缓存（键含文本/字号/样式/字体/缩放；颜色以颜色调制按次生效）。

## 示例

```cangjie verify
package docexample

import sdl.{Color, Pen, Rect, Renderer}

main(): Unit {
    // 无头渲染器：绘制为空操作、测量为估算，适合离屏演示与测试。
    // 真实窗口场景改用 SdlWindow(WindowSpec(...)).renderer，调用方式完全相同。
    let r = Renderer.headless()
    r.beginScene(320.0, 240.0, Color.rgb(30, 30, 46))
    r.fillRoundedRect(Rect(24.0, 24.0, 120.0, 60.0), 8.0, Color.rgb(64, 128, 255))
    r.strokeLine(24.0, 120.0, 296.0, 120.0, Pen(width: 2.0, color: Color.rgb(220, 220, 230)))
    r.text("你好，SDL", 24.0, 140.0, Color.rgb(220, 220, 230))
    let width = r.textWidth("你好，SDL")
    r.endScene()
    r.present()
    println("驱动 ${r.driverName()}，文本宽度为正：${width > 0.0}")
    // 输出: 驱动 headless，文本宽度为正：true
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`static headless()`](#headless) | 返回没有 SDL 设备的渲染器：绘制为空操作，供无窗口测试。 |
| [`driverName()`](#drivername) | 实际选中的 SDL 渲染后端名；无设备时为 `"headless"`。 |
| [`supersampleFactor()`](#supersamplefactor) | 每轴超采样倍数（1 = 关闭）。 |
| [`beginScene(logicalWidth: Float32, logicalHeight: Float32, clearColor: Color)`](#beginscene) | 开始一帧：建立绘制目标并清屏。 |
| [`endScene()`](#endscene) | 结束一帧：把超采样目标以线性过滤解析回窗口（实际的抗锯齿步骤）；未超采样或无头时为空操作。 |
| [`setColor(color: Color)`](#setcolor) | 设置底层 SDL 渲染器的当前绘制颜色。 |
| [`clear(color: Color)`](#clear) | 以纯色清空当前渲染目标。 |
| [`present()`](#present) | 把本帧提交上屏。 |
| [`setScale(scale: Float32)`](#setscale) | 设置渲染缩放；非正值抛异常。 |
| [`setVSync(vsync: Int32)`](#setvsync) | 设置垂直同步模式。 |
| [`vsync()`](#vsync) | 查询垂直同步模式；无头时为 0。 |
| [`setViewport(rect: Rect)`](#setviewport) | 设置视口矩形，之后的绘制以视口原点为原点。 |
| [`resetViewport()`](#resetviewport) | 恢复全窗口视口。 |
| [`viewport()`](#viewport) | 查询当前视口；无头时为零矩形。 |
| [`pushClip(rect: Rect)`](#pushclip) | 把裁剪收窄到 `rect` 与当前裁剪的交集，嵌套的滚动区与输入框因此各自在祖先内裁剪。 |
| [`popClip()`](#popclip) | 恢复匹配的 `pushClip` 之前的裁剪。 |
| [`currentClip()`](#currentclip) | 当前生效的裁剪；未裁剪时为 `None`。 |
| [`clipRect()`](#cliprect) | 查询设备裁剪矩形；无头时返回逻辑栈顶或零矩形。 |
| [`clipEnabled()`](#clipenabled) | 判断裁剪是否生效；无头时按逻辑栈非空判断。 |
| [`setColorScale(scale: Float32)`](#setcolorscale) | 设置颜色缩放（HDR 亮度系数）。 |
| [`colorScale()`](#colorscale) | 查询颜色缩放；无头时为 1.0。 |
| [`setColorFloat(r: Float32, g: Float32, b: Float32, a: Float32)`](#setcolorfloat) | 以浮点通道设置绘制颜色，各通道限制在 [0, 1]。 |
| [`point(x: Float32, y: Float32, color: Color)`](#point) | 画单个点。 |
| [`line(x1: Float32, y1: Float32, x2: Float32, y2: Float32, color: Color)`](#line) | 画 1 像素细线。 |
| [`rect(rect: Rect, color: Color)`](#rect) | 画 1 像素矩形轮廓。 |
| [`fill(rect: Rect, color: Color)`](#fill) | 填充矩形。 |
| [`strokeLine(x1: Float32, y1: Float32, x2: Float32, y2: Float32, pen: Pen)`](#strokeline) | 圆头粗线：整段构建为单个抗锯齿胶囊网格，任意角度都平滑，折线相邻段的接头不产生缺口。 |
| [`strokeRect(rect: Rect, pen: Pen)`](#strokerect) | 矩形描边，转角轻微圆润（内部按 `pen.width * 0.6` 的圆角描边），整圈为一个抗锯齿环形网格。 |
| [`strokeRoundedRect(rect: Rect, radius: Float32, pen: Pen)`](#strokeroundedrect) | 圆角矩形描边，环形网格居中于路径。 |
| [`strokeRoundedRectDashed(rect: Rect, radius: Float32, pen: Pen, dash!: Float32, gap!: Float32)`](#strokeroundedrectdashed) | 虚线圆角矩形描边——`dash` 像素画、`gap` 像素空，沿周长均匀行进。 |
| [`fillRoundedRect(rect: Rect, radius: Float32, color: Color)`](#fillroundedrect) | 填充圆角矩形；半径 ≤ 0.5 时退化为普通 `fill`。 |
| [`fillRoundedRectGradient(rect: Rect, radius: Float32, start: Color, end: Color, vertical!: Bool)`](#fillroundedrectgradient) | 线性渐变填充圆角矩形——默认自上而下（`start` 到 `end`），`vertical` 为 `false` 时自左向右。 |
| [`fillPerCornerRoundedRect(rect: Rect, color: Color, topLeft!: Float32, topRight!: Float32, bottomRight!: Float32, bottomLeft!: Float32)`](#fillpercornerroundedrect) | 四角独立半径的圆角矩形填充（左上、右上、右下、左下），适合聊天气泡、只圆上角的标签页和贴边面板。 |
| [`fillRoundedRectSoft(rect: Rect, radius: Float32, color: Color, feather!: Float32)`](#fillroundedrectsoft) | 边缘沿 `feather` 像素渐隐的圆角矩形——单趟渐变光晕，软阴影与聚焦光辉以此绘制而无色带。 |
| [`circle(cx: Float32, cy: Float32, radius: Float32, color: Color, segments!: Int64)`](#circle) | 1 像素圆轮廓（以 1.0 宽度的笔描边）。 |
| [`strokeCircle(cx: Float32, cy: Float32, radius: Float32, pen: Pen, segments!: Int64)`](#strokecircle) | 按笔宽描边的圆轮廓。 |
| [`fillCircle(cx: Float32, cy: Float32, radius: Float32, color: Color)`](#fillcircle) | 填充圆。 |
| [`fillConvexPolygon(points: ArrayList<Point>, color: Color)`](#fillconvexpolygon) | 填充以顶点列表给出的多边形，自动闭合，边缘与内置形状同款羽化抗锯齿。 |
| [`texturedStrip(texture: Texture, points: ArrayList<Point>, texPoints: ArrayList<Point>, alphas!: ?ArrayList<Float32>)`](#texturedstrip) | 纹理三角带，用于蒙皮或可形变精灵：`points` 沿带方向持有连续的（左、右）顶点对（绘制坐标），`texPoints` 持有一一对应的纹理坐标（源图像素）。 |
| [`text(text: String, x: Float32, y: Float32, color: Color, ...)`](#text) | 以平台 UI 字体绘制 UTF-8 文本（经 SDL3_ttf）。 |
| [`textWidth(text: String, ...)`](#textwidth) | 按绘制同款字体/字号/样式测量文本宽度。 |
| [`textHeight(...)`](#textheight) | 返回指定字号与样式的标准行高（以 `"国Ag"` 样本测量）。 |
| [`textCenter(text: String, rect: Rect, color: Color, ...)`](#textcenter) | 在矩形内居中绘制文本（水平垂直都以测量结果居中）。 |
| [`textRotated(text: String, centerX: Float32, centerY: Float32, angleDegrees: Float64, color: Color, ...)`](#textrotated) | 绕（`centerX`, `centerY`）旋转 `angleDegrees`（顺时针；-90 为自下而上阅读）绘制文本。 |
| [`textMeasureCount()`](#textmeasurecount) | 自上次重置以来的文本测量请求数，用于检查每帧的测量开销。 |
| [`textComputeCount()`](#textcomputecount) | 自上次重置以来的实际测量计算数（缓存未命中）——真实后端上即 SDL_ttf 调用数。 |
| [`textDrawCount()`](#textdrawcount) | 自上次重置以来的文本绘制次数——测量之外的另一个每帧文本瓶颈点。 |
| [`textShapeCount()`](#textshapecount) | 自上次重置以来的塑形操作数（塑形缓存未命中）——真实后端上的 TTF_CreateText 调用数，无头时为 0。 |
| [`resetTextMeasureCount()`](#resettextmeasurecount) | 重置测量、计算、绘制与塑形四个计数器；在帧边界调用以采样单帧。 |
| [`captureBmp(path: String)`](#capturebmp) | 读回当前渲染目标并写为 BMP 文件，用于自动化视觉快照与文档缩略图。 |

**扩展成员**

| 成员 | 说明 |
|---|---|
| [`textureFromSurface(surface: Surface)`](#texturefromsurface) | 把表面上传为 GPU 纹理。 |
| [`loadTexture(path: String)`](#loadtexture) | 从 BMP/PNG 文件加载纹理（内部经 `Surface.load` 中转并自动释放表面）。 |
| [`texture(texture: Texture, destination: Rect, source!: ?Rect)`](#texture) | 把纹理（或其 `source` 源区域）绘制到目标矩形，按需拉伸。 |
| [`textureRotated(texture: Texture, destination: Rect, angle: Float64, options!: TextureRenderOptions)`](#texturerotated) | 旋转绘制纹理，可选源区域、旋转中心与镜像（见 `TextureRenderOptions`）。 |

## 方法

### headless

返回没有 SDL 设备的渲染器：绘制为空操作，供无窗口测试。文本测量回退到确定性的比例估算，布局与事件处理代码因此可以离屏执行。

```cangjie
public static func headless(): Renderer
```

**返回值** `Renderer` — 无设备实例。

### driverName

实际选中的 SDL 渲染后端名；无设备时为 `"headless"`。例如 `"direct3d11"`、`"direct3d12"`、`"opengl"`、`"vulkan"` 或 `"software"`——`"software"` 意味着每个像素都在 CPU 上绘制，会主导超采样帧的开销；SDL 未返回名字时为 `"unknown"`。

```cangjie
public func driverName(): String
```

**返回值** `String` — 后端名。

### supersampleFactor

每轴超采样倍数（1 = 关闭）。渲染器创建后固定不变。

```cangjie
public func supersampleFactor(): Int32
```

**返回值** `Int32` — 生效的倍数，最小 1。

### beginScene

开始一帧：建立绘制目标并清屏。超采样可用时，场景被重定向到按 `logicalWidth`/`logicalHeight` 建立的高分辨率离屏目标；否则直接绘制到窗口。两种路径都把目标清为 `clearColor` 并重置设备裁剪，前一帧泄漏的 `pushClip` 不会波及后续帧。无头时仅清空逻辑裁剪栈。

```cangjie
public func beginScene(logicalWidth: Float32, logicalHeight: Float32, clearColor: Color): Unit
```

**参数**

- `logicalWidth`、`logicalHeight`: `Float32` — 本帧的逻辑尺寸；用于计算超采样目标的缩放。
- `clearColor`: `Color` — 清屏颜色。

### endScene

结束一帧：把超采样目标以线性过滤解析回窗口（实际的抗锯齿步骤）；未超采样或无头时为空操作。

```cangjie
public func endScene(): Unit
```

### setColor

设置底层 SDL 渲染器的当前绘制颜色。无头时为空操作；公开的 `point`、`line`、`rect`、`fill` 和 `clear` 都接收自己的颜色并在调用时覆盖该状态。

```cangjie
public func setColor(color: Color): Unit
```

**参数**

- `color`: `Color` — 写入底层渲染器状态的颜色；带颜色参数的公开绘制方法不会沿用它。

**异常**

- `CuiException` — SDL 拒绝颜色更新时。

### clear

以纯色清空当前渲染目标。无头时为空操作。

```cangjie
public func clear(color: Color): Unit
```

**参数**

- `color`: `Color` — 清空颜色。

**异常**

- `CuiException` — SDL 无法清空当前目标时。

### present

把本帧提交上屏。无头时为空操作。

```cangjie
public func present(): Unit
```

**异常**

- `CuiException` — SDL 提交失败时。

### setScale

设置渲染缩放；非正值抛异常。无头时仍记录逻辑缩放，文本测量保持一致。

```cangjie
public func setScale(scale: Float32): Unit
```

**参数**

- `scale`: `Float32` — 渲染坐标到目标像素的缩放，须大于 0。

**异常**

- `CuiException` — `scale` ≤ 0，或 SDL 拒绝缩放时。

### setVSync

设置垂直同步模式。无头时为空操作。

```cangjie
public func setVSync(vsync: Int32): Unit
```

**参数**

- `vsync`: `Int32` — 1 为每次垂直回扫同步，0 为关闭（不设上限地 present）。

**异常**

- `CuiException` — SDL 拒绝设置时。

### vsync

查询垂直同步模式；无头时为 0。

```cangjie
public func vsync(): Int32
```

**返回值** `Int32` — 当前 vsync 模式。

**异常**

- `CuiException` — SDL 查询失败时。

### setViewport

设置视口矩形，之后的绘制以视口原点为原点。无头时为空操作。

```cangjie
public func setViewport(rect: Rect): Unit
```

**参数**

- `rect`: `Rect` — 视口区域。

**异常**

- `CuiException` — SDL 拒绝设置时。

### resetViewport

恢复全窗口视口。无头时为空操作。

```cangjie
public func resetViewport(): Unit
```

**异常**

- `CuiException` — SDL 拒绝设置时。

### viewport

查询当前视口；无头时为零矩形。

```cangjie
public func viewport(): Rect
```

**返回值** `Rect` — 当前视口区域。

**异常**

- `CuiException` — SDL 查询失败时。

### pushClip

把裁剪收窄到 `rect` 与当前裁剪的交集，嵌套的滚动区与输入框因此各自在祖先内裁剪。每次调用与 [`popClip`](#popclip) 配对。

```cangjie
public func pushClip(rect: Rect): Unit
```

**参数**

- `rect`: `Rect` — 希望裁剪到的区域；实际生效的是它与当前裁剪的交集。

### popClip

恢复匹配的 `pushClip` 之前的裁剪。栈空时不弹出，仅重新应用设备裁剪。

```cangjie
public func popClip(): Unit
```

### currentClip

当前生效的裁剪；未裁剪时为 `None`。纯逻辑查询，无头同样可用。

```cangjie
public func currentClip(): ?Rect
```

**返回值** `?Rect` — 栈顶裁剪矩形，或 `None`。

### clipRect

查询设备裁剪矩形；无头时返回逻辑栈顶或零矩形。

```cangjie
public func clipRect(): Rect
```

**返回值** `Rect` — 当前裁剪区域。

**异常**

- `CuiException` — SDL 查询失败时。

### clipEnabled

判断裁剪是否生效；无头时按逻辑栈非空判断。

```cangjie
public func clipEnabled(): Bool
```

**返回值** `Bool` — 裁剪生效时为 `true`。

### setColorScale

设置颜色缩放（HDR 亮度系数）。无头时为空操作。

```cangjie
public func setColorScale(scale: Float32): Unit
```

**参数**

- `scale`: `Float32` — 绘制操作的颜色乘数。

**异常**

- `CuiException` — SDL 拒绝设置时。

### colorScale

查询颜色缩放；无头时为 1.0。

```cangjie
public func colorScale(): Float32
```

**返回值** `Float32` — 当前颜色缩放。

**异常**

- `CuiException` — SDL 查询失败时。

### setColorFloat

以浮点通道设置绘制颜色，各通道限制在 [0, 1]。无头时为空操作。

```cangjie
public func setColorFloat(r: Float32, g: Float32, b: Float32, a: Float32): Unit
```

**参数**

- `r`、`g`、`b`、`a`: `Float32` — 颜色通道；小于 0 按 0、大于 1 按 1 处理。

**异常**

- `CuiException` — SDL 拒绝设置时。

### point

画单个点。无头时为空操作。

```cangjie
public func point(x: Float32, y: Float32, color: Color): Unit
```

**参数**

- `x`、`y`: `Float32` — 点坐标，逻辑像素。
- `color`: `Color` — 颜色。

### line

画 1 像素细线。粗线请用 [`strokeLine`](#strokeline)。无头时为空操作。

```cangjie
public func line(x1: Float32, y1: Float32, x2: Float32, y2: Float32, color: Color): Unit
```

**参数**

- `x1`、`y1`、`x2`、`y2`: `Float32` — 线段端点，逻辑像素。
- `color`: `Color` — 颜色。

### rect

画 1 像素矩形轮廓。无头时为空操作。

```cangjie
public func rect(rect: Rect, color: Color): Unit
```

**参数**

- `rect`: `Rect` — 轮廓矩形。
- `color`: `Color` — 颜色。

### fill

填充矩形。无头时为空操作。

```cangjie
public func fill(rect: Rect, color: Color): Unit
```

**参数**

- `rect`: `Rect` — 填充区域。
- `color`: `Color` — 颜色。

### strokeLine

圆头粗线：整段构建为单个抗锯齿胶囊网格，任意角度都平滑，折线相邻段的接头不产生缺口。笔宽 ≤ 0 或无头时不绘制。

```cangjie
public func strokeLine(x1: Float32, y1: Float32, x2: Float32, y2: Float32, pen: Pen): Unit
```

**参数**

- `x1`、`y1`、`x2`、`y2`: `Float32` — 线段端点，逻辑像素。
- `pen`: `Pen` — 描边宽度与颜色。

### strokeRect

矩形描边，转角轻微圆润（内部按 `pen.width * 0.6` 的圆角描边），整圈为一个抗锯齿环形网格。

```cangjie
public func strokeRect(rect: Rect, pen: Pen): Unit
```

**参数**

- `rect`: `Rect` — 被描边的矩形。
- `pen`: `Pen` — 描边宽度与颜色。

### strokeRoundedRect

圆角矩形描边，环形网格居中于路径。半径最大取短边的一半；宽高或笔宽非正时不绘制。

```cangjie
public func strokeRoundedRect(rect: Rect, radius: Float32, pen: Pen): Unit
```

**参数**

- `rect`: `Rect` — 被描边的矩形。
- `radius`: `Float32` — 圆角半径，限制在 `[0, min(w, h) / 2]`。
- `pen`: `Pen` — 描边宽度与颜色。

### strokeRoundedRectDashed

虚线圆角矩形描边——`dash` 像素画、`gap` 像素空，沿周长均匀行进。`dash` 或 `gap` 非正时退化为实线描边。

```cangjie
public func strokeRoundedRectDashed(rect: Rect, radius: Float32, pen: Pen, dash!: Float32, gap!: Float32): Unit
```

**参数**

- `rect`: `Rect` — 被描边的矩形。
- `radius`: `Float32` — 圆角半径，限制在 `[0, min(w, h) / 2]`。
- `pen`: `Pen` — 描边宽度与颜色。
- `dash!`: `Float32` — 每段实线长度；非正值退化为实线。
- `gap!`: `Float32` — 每段空白长度；非正值退化为实线。

### fillRoundedRect

填充圆角矩形；半径 ≤ 0.5 时退化为普通 [`fill`](#fill)。网格按尺寸缓存并跨帧复用。

```cangjie
public func fillRoundedRect(rect: Rect, radius: Float32, color: Color): Unit
```

**参数**

- `rect`: `Rect` — 填充区域。
- `radius`: `Float32` — 圆角半径，限制在 `[0, min(w, h) / 2]`。
- `color`: `Color` — 填充色。

### fillRoundedRectGradient

线性渐变填充圆角矩形——默认自上而下（`start` 到 `end`），`vertical` 为 `false` 时自左向右。复用实心填充的缓存网格，不增加三角化开销；超出网格缓存预算的极端尺寸回退为 `start` 纯色填充。

```cangjie
public func fillRoundedRectGradient(rect: Rect, radius: Float32, start: Color, end: Color, vertical!: Bool = true): Unit
```

**参数**

- `rect`: `Rect` — 填充区域。
- `radius`: `Float32` — 圆角半径，限制在 `[0, min(w, h) / 2]`。
- `start`: `Color` — 渐变起点色（上或左）。
- `end`: `Color` — 渐变终点色（下或右）。
- `vertical!`: `Bool` — `true` 垂直渐变，`false` 水平；默认 `true`。

### fillPerCornerRoundedRect

四角独立半径的圆角矩形填充（左上、右上、右下、左下），适合聊天气泡、只圆上角的标签页和贴边面板。每个半径最大取短边的一半；逐次生成三角形，不占用统一半径的网格缓存。

```cangjie
public func fillPerCornerRoundedRect(rect: Rect, color: Color, topLeft!: Float32, topRight!: Float32, bottomRight!: Float32, bottomLeft!: Float32): Unit
```

**参数**

- `rect`: `Rect` — 填充区域。
- `color`: `Color` — 填充色。
- `topLeft!`、`topRight!`、`bottomRight!`、`bottomLeft!`: `Float32` — 各角半径，最大取短边的一半。

### fillRoundedRectSoft

边缘沿 `feather` 像素渐隐的圆角矩形——单趟渐变光晕，软阴影与聚焦光辉以此绘制而无色带。

```cangjie
public func fillRoundedRectSoft(rect: Rect, radius: Float32, color: Color, feather!: Float32): Unit
```

**参数**

- `rect`: `Rect` — 填充区域。
- `radius`: `Float32` — 圆角半径，限制在 `[0, min(w, h) / 2]`。
- `color`: `Color` — 填充色。
- `feather!`: `Float32` — 渐隐宽度，最大不超过短边。

### circle

1 像素圆轮廓（以 1.0 宽度的笔描边）。

```cangjie
public func circle(cx: Float32, cy: Float32, radius: Float32, color: Color, segments!: Int64 = 0): Unit
```

**参数**

- `cx`、`cy`: `Float32` — 圆心，逻辑像素。
- `radius`: `Float32` — 半径；非正值不绘制。
- `color`: `Color` — 颜色。
- `segments!`: `Int64` — 最小细分段数提示；默认 0（按半径自动取样）。

### strokeCircle

按笔宽描边的圆轮廓。`segments` 是最小细分提示；弧线总会按半径取足够的采样保持平滑。

```cangjie
public func strokeCircle(cx: Float32, cy: Float32, radius: Float32, pen: Pen, segments!: Int64 = 0): Unit
```

**参数**

- `cx`、`cy`: `Float32` — 圆心，逻辑像素。
- `radius`: `Float32` — 半径；非正值不绘制。
- `pen`: `Pen` — 描边宽度与颜色；笔宽非正不绘制。
- `segments!`: `Int64` — 最小细分段数提示；默认 0。

### fillCircle

填充圆。半径非正或无头时不绘制。

```cangjie
public func fillCircle(cx: Float32, cy: Float32, radius: Float32, color: Color): Unit
```

**参数**

- `cx`、`cy`: `Float32` — 圆心，逻辑像素。
- `radius`: `Float32` — 半径。
- `color`: `Color` — 填充色。

### fillConvexPolygon

填充以顶点列表给出的多边形，自动闭合，边缘与内置形状同款羽化抗锯齿。网格从首顶点扇形展开，轮廓须为凸多边形或对 `points[0]` 星形——楔形、正多边形与径向轨迹天然满足；一般凹多边形需先自行三角化。重复的闭合点会被丢弃；不足三个互异顶点不绘制。

```cangjie
public func fillConvexPolygon(points: ArrayList<Point>, color: Color): Unit
```

**参数**

- `points`: `ArrayList<Point>` — 顶点序列，逻辑像素；无须重复首点。
- `color`: `Color` — 填充色。

### texturedStrip

纹理三角带，用于蒙皮或可形变精灵：`points` 沿带方向持有连续的（左、右）顶点对（绘制坐标），`texPoints` 持有一一对应的纹理坐标（源图像素）。`alphas` 可选地给出每顶点不透明度，让交叠部分交叉淡化。全部列表须为相同的偶数长度且至少 4；长度非法时不绘制。

```cangjie
public func texturedStrip(texture: Texture, points: ArrayList<Point>, texPoints: ArrayList<Point>, alphas!: ?ArrayList<Float32> = None): Unit
```

**参数**

- `texture`: `Texture` — 采样的纹理。
- `points`: `ArrayList<Point>` — 带上连续（左、右）顶点对，绘制坐标。
- `texPoints`: `ArrayList<Point>` — 与 `points` 等长的纹理坐标，单位为源图像素。
- `alphas!`: `?ArrayList<Float32>` — 每顶点不透明度；默认 `None`（全部不透明）。

**异常**

- `CuiException` — 纹理已关闭时。

### text

以平台 UI 字体绘制 UTF-8 文本（经 SDL3_ttf）。字形按有效像素尺寸栅格化并在对齐到物理像素的位置 1:1 绘制，超采样下依旧锐利。无头时为空操作。

```cangjie
public func text(text: String, x: Float32, y: Float32, color: Color, pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular, font!: ?String = None): Unit
```

**参数**

- `text`: `String` — UTF-8 文本。
- `x`、`y`: `Float32` — 文本左上角，逻辑像素。
- `color`: `Color` — 文字颜色。
- `pointSize!`: `Float32` — 字号；默认 [`FontSizes.BODY`](FontSizes.md#body)。
- `style!`: `FontStyle` — 样式；默认 [`FontStyle.regular`](FontStyle.md#regular)。
- `font!`: `?String` — [`Fonts`](Fonts.md) 注册名；默认值为 `None`，使用平台 UI 字体；传入未注册的名称也回退到平台 UI 字体。

### textWidth

按绘制同款字体/字号/样式测量文本宽度。结果按字号/样式/字体缓存；无头时为确定性估算。

```cangjie
public func textWidth(text: String, pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular, font!: ?String = None): Float32
```

**参数**

- `text`: `String` — 被测文本。
- `pointSize!`: `Float32` — 字号；默认 `FontSizes.BODY`。
- `style!`: `FontStyle` — 样式；默认 `FontStyle.regular`。
- `font!`: `?String` — 字体注册名；默认 `None`。

**返回值** `Float32` — 文本宽度，逻辑像素。

### textHeight

返回指定字号与样式的标准行高（以 `"国Ag"` 样本测量）。

```cangjie
public func textHeight(pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular, font!: ?String = None): Float32
```

**参数**

- `pointSize!`: `Float32` — 字号；默认 `FontSizes.BODY`。
- `style!`: `FontStyle` — 样式；默认 `FontStyle.regular`。
- `font!`: `?String` — 字体注册名；默认 `None`。

**返回值** `Float32` — 行高，逻辑像素。

### textCenter

在矩形内居中绘制文本（水平垂直都以测量结果居中）。

```cangjie
public func textCenter(text: String, rect: Rect, color: Color, pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular, font!: ?String = None): Unit
```

**参数**

- `text`: `String` — UTF-8 文本。
- `rect`: `Rect` — 居中参照的矩形。
- `color`: `Color` — 文字颜色。
- `pointSize!`: `Float32` — 字号；默认 `FontSizes.BODY`。
- `style!`: `FontStyle` — 样式；默认 `FontStyle.regular`。
- `font!`: `?String` — 字体注册名；默认 `None`。

### textRotated

绕（`centerX`, `centerY`）旋转 `angleDegrees`（顺时针；-90 为自下而上阅读）绘制文本。整串按有效像素尺寸栅格化进纹理并经旋转纹理管线绘制，栅格化结果跨帧缓存（颜色以颜色调制按次生效），静态旋转标签只需栅格化一次。无头或空文本时为空操作。

```cangjie
public func textRotated(text: String, centerX: Float32, centerY: Float32, angleDegrees: Float64, color: Color, pointSize!: Float32 = FontSizes.BODY, style!: FontStyle = FontStyle.regular, font!: ?String = None): Unit
```

**参数**

- `text`: `String` — UTF-8 文本；空串不绘制。
- `centerX`、`centerY`: `Float32` — 旋转中心，逻辑像素。
- `angleDegrees`: `Float64` — 顺时针角度。
- `color`: `Color` — 文字颜色，含 alpha。
- `pointSize!`: `Float32` — 字号；默认 `FontSizes.BODY`。
- `style!`: `FontStyle` — 样式；默认 `FontStyle.regular`。
- `font!`: `?String` — 字体注册名；默认 `None`。

**异常**

- `CuiException` — SDL 旋转绘制失败时。

### textMeasureCount

自上次重置以来的文本测量请求数，用于检查每帧的测量开销。文本测量是每帧的主要开销之一；在帧边界重置计数后读取，便能看到一棵组件树每帧测量了多少次。

```cangjie
public func textMeasureCount(): UInt64
```

**返回值** `UInt64` — 测量请求总数。

### textComputeCount

自上次重置以来的实际测量计算数（缓存未命中）——真实后端上即 SDL_ttf 调用数。

```cangjie
public func textComputeCount(): UInt64
```

**返回值** `UInt64` — 缓存未命中数。

### textDrawCount

自上次重置以来的文本绘制次数——测量之外的另一个每帧文本瓶颈点。

```cangjie
public func textDrawCount(): UInt64
```

**返回值** `UInt64` — 绘制次数。

### textShapeCount

自上次重置以来的塑形操作数（塑形缓存未命中）——真实后端上的 TTF_CreateText 调用数，无头时为 0。滚动时热缓存下此值持平而 [`textDrawCount`](#textdrawcount) 随帧增长，即塑形缓存在生效。

```cangjie
public func textShapeCount(): UInt64
```

**返回值** `UInt64` — 塑形次数。

### resetTextMeasureCount

重置测量、计算、绘制与塑形四个计数器；在帧边界调用以采样单帧。

```cangjie
public func resetTextMeasureCount(): Unit
```

### captureBmp

读回当前渲染目标并写为 BMP 文件，用于自动化视觉快照与文档缩略图。无头时为空操作——没有可读的像素。

```cangjie
public func captureBmp(path: String): Unit
```

**参数**

- `path`: `String` — 输出 BMP 路径。

**异常**

- `CuiException` — SDL 无法读取像素或保存文件时。

## 扩展成员

### textureFromSurface

把[表面](Surface.md)上传为 GPU [纹理](Texture.md)。

```cangjie
public func textureFromSurface(surface: Surface): Texture
```

**参数**

- `surface`: `Surface` — 源表面；调用后仍归调用者所有。

**返回值** `Texture` — 新建的纹理。

**异常**

- `CuiException` — 表面已关闭，或 SDL 无法创建纹理时（无头渲染器亦抛出）。

### loadTexture

从 BMP/PNG 文件加载纹理（内部经 [`Surface.load`](Surface.md#load) 中转并自动释放表面）。

```cangjie
public func loadTexture(path: String): Texture
```

**参数**

- `path`: `String` — 图像文件路径；按扩展名推断格式。

**返回值** `Texture` — 新建的纹理。

**异常**

- `CuiException` — 图像无法加载或无法创建纹理时。

### texture

把纹理（或其 `source` 源区域）绘制到目标矩形，按需拉伸。

```cangjie
public func texture(texture: Texture, destination: Rect, source!: ?Rect = None): Unit
```

**参数**

- `texture`: `Texture` — 被绘制的纹理。
- `destination`: `Rect` — 目标区域，逻辑像素。
- `source!`: `?Rect` — 纹理上的源区域（纹理像素）；默认 `None`（整张）。

**异常**

- `CuiException` — 纹理已关闭，或 SDL 绘制失败时。

### textureRotated

旋转绘制纹理，可选源区域、旋转中心与镜像（见 [`TextureRenderOptions`](TextureRenderOptions.md)）。

```cangjie
public func textureRotated(texture: Texture, destination: Rect, angle: Float64, options!: TextureRenderOptions = TextureRenderOptions()): Unit
```

**参数**

- `texture`: `Texture` — 被绘制的纹理。
- `destination`: `Rect` — 目标区域，逻辑像素。
- `angle`: `Float64` — 顺时针角度。
- `options!`: `TextureRenderOptions` — 源区域/旋转中心/镜像；默认全部缺省。

**异常**

- `CuiException` — 纹理已关闭，或 SDL 绘制失败时。

## 另请参阅

- [SdlWindow](SdlWindow.md) — 渲染器的宿主窗口。
- [Pen](Pen.md) · [Color](Color.md) · [Rect](Rect.md) — 绘制参数类型。
- [FontStyle](FontStyle.md) · [FontSizes](FontSizes.md) · [Fonts](Fonts.md) — 文本样式、字号与字体注册。
