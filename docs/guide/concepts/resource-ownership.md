# 资源所有权与关闭顺序

## 先用一句话说明

窗口、Surface、Texture 和 Cursor 都要有一个明确拥有者；拥有者在最后一次使用后关闭一次，任何借用者都不得保存超出拥有者生命周期的引用。

## 为什么重要

先掌握[窗口与事件循环](window-events-lifecycle.md)，才能准确判断最后一次事件、绘制和关闭分别发生在何时。

这些类型背后是原生资源，仓颉对象离开局部变量并不等于底层资源立即安全释放。窗口关闭会释放内部渲染器、停止文本输入、销毁窗口并退出视频子系统；Texture、RenderCommandBuffer 与 TextMeasureSession 都关联创建它们的 Renderer；Cursor 激活后仍需在不用时关闭；Surface 关闭后不能再读取像素或创建纹理。关闭过早会得到 `SdlException` 或无效绘制，忘记关闭则会累积显存、像素内存或系统对象。

异常路径尤其容易暴露问题。若程序在加载图片后、创建纹理前失败，`Surface` 仍要释放；若窗口构造后的字体初始化失败，已经创建的部分资源也要回收。`try (...)` 和 `finally` 可以让正常退出、用户关闭和异常共用同一条清理路径。

## 工作模型

可以把资源关系看成一棵树：`SdlWindow` 拥有 `Renderer`；渲染器创建的 `Texture`、命令缓冲和文字会话必须在渲染器仍有效时使用，并且只能在其创建线程调用。渲染设备重置后，旧命令缓冲会在绘制前拒绝重放，应用应从普通数据重新创建资源。`Surface` 独立存在，可先加载或生成，再上传为 `Texture`；上传不会自动关闭表面，纹理也不能脱离渲染器使用。`Cursor` 通常由应用拥有，切换光标时应让旧资源保持有效，直到新光标已经激活。

不能从一个已经关闭窗口的函数中返回 `Texture`，因为纹理仍依赖该窗口的渲染器。安全结构让窗口资源块覆盖纹理的整个使用期，并按 `SdlWindow → Surface → Texture` 的顺序嵌套创建；退出时会按相反顺序关闭。完整写法见[图片、纹理与截图](../how-to/images-textures-screenshot.md)。

## 选择与取舍

短期资源适合局部 `try (...)`；跨帧资源适合集中到 `Assets` 或应用状态对象，由应用退出时统一关闭。绘制事务优先使用 `renderFrame`，需要手工控制时再用资源块包住 `beginRenderPass`。集中管理可以减少遗漏，但仍要明确关闭顺序，并防止业务对象随意持有底层资源。资源缓存能提高性能，代价是生命周期更长且需要处理设备失效；只绘制、不再读取像素的图片通常可以在上传后关闭 `Surface`，只保留 `Texture`。

窗口本身也可显式 `close()`，但只有在无法使用资源块时才需要。若调用显式关闭，后续代码应停止事件和渲染，并让 `isClosed()` 成为可观察保护。不要依赖重复关闭来掩盖边界不清，也不要在多个模块都写“保险 close”。

## 应用这个模型

计算器只有窗口和内部文本资源，入口用一个资源块即可。图片应用可把 `Surface.load → textureFromSurface → Surface.close` 放在初始化，Texture 放入 `Assets`，退出时先关闭 Texture 再关闭窗口。游戏的多个纹理和光标可由 `GameAssets` 统一拥有；状态和模拟只保存资源键或尺寸，不直接负责关闭。

排查资源问题时列出创建点、最后使用点和关闭点，按时间排序。检查当前线程是否为 Renderer 创建线程，异常是否能越过关闭语句，窗口关闭后是否仍有定时回调绘制，纹理/命令缓冲是否来自另一个 Renderer，以及设备 reset 后是否仍 replay 旧代资源。仓库的窗口生命周期、资源拥有者和 reset 测试是多窗口与渲染改动后的必要回归。

## 常见误解

关闭窗口不会自动释放独立创建的 `Surface` 和 `Cursor`；它们仍由各自创建者负责。`Texture` 也不是可在任意窗口共享的图片数据，它绑定创建它的 `Renderer` 和线程。设备重置不只是一次普通重绘通知，旧命令缓冲可能已经失效。最后，`Surface` 转为 `Texture` 不会转移所有权：两个资源同时存在，直到分别关闭。

## 相关 API

- [`SdlWindow`](../../api/sdl/SdlWindow.md)：主窗口资源与关闭行为。
- [`Surface`](../../api/sdl/Surface.md)：CPU 像素表面及其关闭边界。
- [`Texture`](../../api/sdl/Texture.md)：渲染器相关纹理资源。
- [`RenderCommandBuffer`](../../api/sdl/RenderCommandBuffer.md)：带 Renderer/设备代数约束的可重放绘制记录。
- [`RenderPass`](../../api/sdl/RenderPass.md)：异常安全的场景清理边界。
- [`TextMeasureSession`](../../api/sdl/TextMeasureSession.md)：不得跨 Renderer 生命周期的文字测量资源。
- [`Cursor`](../../api/sdl/input/Cursor.md)：系统光标资源与激活。

## 下一步

完成[多文件计算器](../tutorials/multi-file-calculator.md)，观察入口怎样成为资源所有者，而逻辑和渲染只接受借用。
