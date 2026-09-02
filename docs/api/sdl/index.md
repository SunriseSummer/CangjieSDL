[API 参考](../index.md) › sdl

# sdl

```cangjie
import sdl.*
```

核心包提供窗口、事件、二维绘制、文字、图片和资源管理。应用通常从 `WindowSpec` 与 `SdlWindow` 开始，在事件循环中更新状态，再通过窗口自带的 `Renderer` 绘制。

## 窗口与事件

| 类型 | 说明 |
|---|---|
| [`WindowSpec`](WindowSpec.md) | 窗口标题、逻辑尺寸、DPI、缩放、垂直同步和超采样配置。 |
| [`SdlWindow`](SdlWindow.md) | 拥有原生窗口与渲染器，并提供事件、尺寸、计时和窗口控制。 |
| [`SdlEventPump`](SdlEventPump.md) | 在多窗口应用中统一消费并路由进程级事件。 |
| [`UiEvent`](UiEvent.md) | 已解码的退出、窗口、键鼠、文字和拖放事件。 |
| [`UiEventRecord`](UiEventRecord.md) | 事件与事件发生时的时间、窗口和键盘元数据。 |
| [`UiEventMetadata`](UiEventMetadata.md) | 原生事件元数据的仓颉快照。 |
| [`EventKeyModifiers`](EventKeyModifiers.md) | 事件发生时的修饰键快照。 |
| [`Key`](Key.md) | 导航键、功能键、字母、数字和原始键码。 |
| [`MouseButton`](MouseButton.md) | 鼠标按键。 |
| [`FrameInfo`](FrameInfo.md) | 总运行时间和相邻帧间隔。 |
| [`WindowDisplayMetrics`](WindowDisplayMetrics.md) | 内容缩放、像素密度和总渲染缩放。 |
| [`WindowFlags`](WindowFlags.md) | 当前窗口状态标志。 |
| [`WindowPosition`](WindowPosition.md) | 窗口在桌面坐标系中的位置。 |
| [`WindowBorderSize`](WindowBorderSize.md) | 窗口边框和标题栏占用的空间。 |
| [`WindowAspectRatio`](WindowAspectRatio.md) | 窗口宽高比约束。 |
| [`WindowFlash`](WindowFlash.md) | 窗口或任务栏提醒方式。 |
| [`WindowProgressState`](WindowProgressState.md) | 任务栏进度状态。 |

## 绘制与增量重放

| 类型 | 说明 |
|---|---|
| [`Renderer`](Renderer.md) | 场景提交、几何、文字、纹理、裁剪、视口和截图入口。 |
| [`RenderPass`](RenderPass.md) | 保证场景能够正确结束的资源边界。 |
| [`RenderCommandBuffer`](RenderCommandBuffer.md) | 可校验并重复播放的不可变绘制命令。 |
| [`RenderCommandSlot`](RenderCommandSlot.md) | 可替换的子命令引用，用于稳定父结构下的局部更新。 |
| [`RenderCommandBufferStats`](RenderCommandBufferStats.md) | 命令数量、资源、批处理、内存估算和重放次数。 |
| [`RenderSamplingStats`](RenderSamplingStats.md) | 当前采样倍率、目标尺寸、内存估算和回退原因。 |
| [`RenderSamplingStatus`](RenderSamplingStatus.md) | 直接绘制、超采样或降级的状态。 |
| [`Color`](Color.md) | 8 位 RGBA 颜色。 |
| [`Pen`](Pen.md) | 描边宽度和颜色。 |
| [`Point`](Point.md) | 逻辑坐标点。 |
| [`Size`](Size.md) | 逻辑宽高。 |
| [`Rect`](Rect.md) | 逻辑矩形及常用几何运算。 |
| [`Insets`](Insets.md) | 四边间距。 |
| [`SurfaceStyle`](SurfaceStyle.md) | 面板填充、边框、圆角和阴影样式。 |
| [`IconName`](IconName.md) | 内置矢量图标名称。 |

## 文字

| 类型 | 说明 |
|---|---|
| [`Fonts`](Fonts.md) | 把应用字体名映射到主字体和回退字体文件。 |
| [`FontStyle`](FontStyle.md) | 粗体、斜体、下划线和删除线组合。 |
| [`FontSizes`](FontSizes.md) | 常用字号常量。 |
| [`TextMeasureSession`](TextMeasureSession.md) | 复用同一字符串和字体的适配、范围测量与命中测试。 |
| [`TextFitResult`](TextFitResult.md) | 宽度限制内可容纳的 UTF-8 前缀。 |
| [`TextHitResult`](TextHitResult.md) | 指针位置对应的文字插入边界和字形簇范围。 |

## 图片与纹理

| 类型 | 说明 |
|---|---|
| [`Surface`](Surface.md) | CPU 侧像素表面，可创建、加载、读写和保存。 |
| [`Texture`](Texture.md) | 绑定某个渲染器的图像资源。 |
| [`TextureRenderOptions`](TextureRenderOptions.md) | 纹理源区域、旋转中心和镜像选项。 |
| [`TextureBlendMode`](TextureBlendMode.md) | 纹理与目标像素的混合方式。 |
| [`TextureFlip`](TextureFlip.md) | 纹理水平或垂直镜像方式。 |
| [`ImageFileFormat`](ImageFileFormat.md) | Surface 支持的 BMP 与 PNG 格式。 |

## 异常与函数

| 项目 | 说明 |
|---|---|
| [`SdlException`](SdlException.md) | SDL 调用、资源状态或封装层操作失败。 |
| [`clampF32`](functions.md#clampf32) | 将浮点值限制在闭区间内。 |
| [`drawIcon`](functions.md#drawicon) | 绘制内置矢量图标。 |
| [`imageFormatFromPath`](functions.md#imageformatfrompath) | 根据文件扩展名选择图像格式。 |
| [`sdlVersion`](functions.md#sdlversion) | 查询链接的 SDL 版本号。 |
| [`sdlRevision`](functions.md#sdlrevision) | 查询 SDL 构建修订字符串。 |

## 子包

| 包 | 说明 |
|---|---|
| [`sdl.input`](input/index.md) | 剪贴板、键鼠状态和系统光标。 |
| [`sdl.dialogs`](dialogs/index.md) | 消息框和异步文件对话框。 |
| [`sdl.displays`](displays/index.md) | 显示器信息和全屏模式。 |
| [`sdl.system`](system/index.md) | 路径、文件、元数据、时间、电源和平台信息。 |
