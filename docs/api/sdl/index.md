[sdl](../index.md) › sdl

# sdl

```cangjie
import sdl.*
```

核心包：窗口与渲染器、事件解码、二维几何类型、文本与字体、纹理与表面。应用从 [`WindowSpec`](WindowSpec.md) 创建 [`SdlWindow`](SdlWindow.md)，经 [`SdlWindow.pollEvent`](SdlWindow.md#pollevent) 消费 [`UiEvent`](UiEvent.md)，通过窗口自带的 [`Renderer`](Renderer.md) 绘制。全部坐标为逻辑像素；API 以仓颉类型表达，不暴露 C 指针。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`CuiException`](CuiException.md) | SDL 调用失败、参数非法或资源已关闭时，本模块会抛出 `CuiException`。 |
| [`Fonts`](Fonts.md) | 进程级注册表，把应用字体名映射到字体文件路径，类似 CSS 的 `@font-face` 表。 |
| [`Renderer`](Renderer.md) | 窗口的二维绘制入口：绘制几何、文本和纹理，并管理视口与裁剪。 |
| [`SdlWindow`](SdlWindow.md) | 与自己的渲染器成对创建、成对关闭的 SDL 窗口。 |
| [`Surface`](Surface.md) | CPU 侧的 RGBA 像素缓冲，包装 SDL_Surface：可新建、从 BMP/PNG 文件加载、逐像素写入并存回 BMP 文件。 |
| [`Texture`](Texture.md) | GPU 侧图像资源，由渲染器创建（`loadTexture` / `textureFromSurface`），经 `Renderer.texture` / `textureRotated` / `texturedStrip` 绘制。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`Color`](Color.md) | 8 位通道的 RGBA 颜色。 |
| [`FontSizes`](FontSizes.md) | 渲染器与应用共用的标准字号常量集合（点值）。 |
| [`FontStyle`](FontStyle.md) | 叠加在基础 UI 字体上的文本样式：字重、倾斜与两种线条修饰。 |
| [`FrameInfo`](FrameInfo.md) | 以毫秒计的帧计时信息：`elapsedMs` 为 SDL 初始化以来的总时长，`deltaMs` 为距上一帧的间隔。 |
| [`Insets`](Insets.md) | 逻辑像素下的四边间距——内边距、外边距、留白。 |
| [`Pen`](Pen.md) | 一次描边的描述：线条/轮廓的宽度与颜色。 |
| [`Point`](Point.md) | 逻辑像素坐标系中的一个位置——布局、事件与绘制共用的坐标空间。 |
| [`Rect`](Rect.md) | 逻辑像素下的轴对齐矩形——原点 `x`/`y` 加宽高 `w`/`h`，用于布局框、命中测试与裁剪。 |
| [`Size`](Size.md) | 逻辑像素下的宽高尺寸，用于窗口尺寸查询与布局测量的返回值。 |
| [`SurfaceStyle`](SurfaceStyle.md) | 一块圆角面板的外观描述：填充色、边框色与宽度、圆角半径、阴影色与垂直偏移。 |
| [`TextureRenderOptions`](TextureRenderOptions.md) | `Renderer.textureRotated` 的可选项集合：源区域裁剪、旋转中心与镜像方式。 |
| [`WindowAspectRatio`](WindowAspectRatio.md) | 窗口宽高比约束的上下界，由 `SdlWindow.aspectRatio` 返回。 |
| [`WindowBorderSize`](WindowBorderSize.md) | 窗口装饰（标题栏与边框）在四个方向占用的像素数，由 `SdlWindow.borderSize` 返回。 |
| [`WindowFlags`](WindowFlags.md) | 窗口状态标志位快照：把 SDL 的 64 位标志掩码展开为逐项布尔字段，同时保留原始掩码。 |
| [`WindowPosition`](WindowPosition.md) | 窗口左上角在屏幕坐标系中的位置，由 `SdlWindow.position` 返回。 |
| [`WindowSpec`](WindowSpec.md) | 创建窗口时的一次性选项：标题、逻辑尺寸、DPI 与缩放行为、垂直同步和渲染器的超采样倍数。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`IconName`](IconName.md) | 内置矢量图标的名称，交给 `drawIcon` 在 24×24 的坐标网格上绘制圆头线条图标。 |
| [`ImageFileFormat`](ImageFileFormat.md) | `Surface` 能读写的图像文件格式。 |
| [`Key`](Key.md) | 从 SDL 扫描码解码出的键盘按键——物理按键，与键盘布局无关。 |
| [`MouseButton`](MouseButton.md) | 解码后的鼠标按键；左/中/右之外的按键以 `RawCode` 携带 SDL 的按键码到达。 |
| [`TextureBlendMode`](TextureBlendMode.md) | 纹理绘制时与目标像素的混合方式，对应 SDL 的 SDL_BLENDMODE_*。 |
| [`TextureFlip`](TextureFlip.md) | 旋转绘制纹理时的镜像方式，作为 `TextureRenderOptions` 的一项传入 `Renderer.textureRotated`。 |
| [`UiEvent`](UiEvent.md) | 解码后的 SDL 输入事件，按到达顺序交给应用处理。 |
| [`WindowFlash`](WindowFlash.md) | 任务栏/窗口闪烁请求的方式，传给 `SdlWindow.flash`。 |
| [`WindowProgressState`](WindowProgressState.md) | 原生任务栏进度指示的状态（Windows 任务栏按钮的进度条），经 `SdlWindow.setProgressState` 设置。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`clampF32`](functions.md#clampf32) | 将值限制在闭区间 [`low`, `high`]。 |
| [`drawIcon`](functions.md#drawicon) | 在给定矩形内以圆头粗描边绘制一枚内置矢量图标。 |
| [`imageFormatFromPath`](functions.md#imageformatfrompath) | 按扩展名推断图像文件格式：`.png` / `.PNG` 为 PNG，其余一律为 BMP。 |
| [`sdlVersion`](functions.md#sdlversion) | 返回链接到的 SDL 版本号（SDL_GetVersion 的数值编码）。 |
| [`sdlRevision`](functions.md#sdlrevision) | 返回 SDL 构建的修订串；SDL 未提供时为空串。 |

## 子包

| 包 | 说明 |
|---|---|
| [`sdl.dialogs`](dialogs/index.md) | 原生消息框与异步文件对话框。 |
| [`sdl.displays`](displays/index.md) | 显示器信息查询与全屏显示模式枚举。 |
| [`sdl.input`](input/index.md) | 剪贴板、鼠标状态、键盘修饰键与系统光标。 |
| [`sdl.system`](system/index.md) | 应用元数据、路径与文件系统、SDL hint、时钟与日历时间、平台与电源信息。 |
