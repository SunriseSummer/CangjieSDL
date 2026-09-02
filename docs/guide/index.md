# CangjieSDL 使用指南

本指南先建立窗口、事件、绘制和资源的运行模型，再按任务讲解输入、文字、图片和平台能力。精确签名、默认值和异常以 [API 参考](../api/index.md)为准。

## 入门路线

1. [创建第一个窗口](getting-started/first-window.md)：运行完整程序，认识窗口、事件循环和 `renderFrame`。
2. [窗口与事件循环](concepts/window-events-lifecycle.md)：理解每一帧的固定顺序，以及单窗口和多窗口的事件所有权。
3. [逻辑坐标与高 DPI](concepts/render-scene-coordinates.md)：区分逻辑尺寸、窗口坐标、后备像素和超采样。
4. [资源所有权](concepts/resource-ownership.md)：正确管理窗口、纹理、表面、光标和测量会话。
5. [多文件计算器](tutorials/multi-file-calculator.md)：把状态、业务逻辑、事件、绘制和主题拆成清晰层次。

游戏开发可继续阅读[输入事件与持续状态](concepts/input-state.md)、[时间步长与游戏循环](concepts/game-loop-timing.md)和[实时小游戏](tutorials/real-time-game.md)。

## 核心工作模型

一帧通常遵循这条路径：

> 读取事件 → 更新应用状态 → 计算逻辑布局 → 绘制 → 提交画面

需要长期记住四条边界：

- 布局、命中测试和绘制都使用逻辑像素；设备像素只用于诊断和资源分辨率选择。
- `SdlWindow` 拥有 `Renderer`，渲染器创建的纹理和命令资源不能跨渲染器使用。
- 渲染 API 只能在渲染器的创建线程调用；后台线程只准备普通应用数据。
- 系统能力可能不可用，`Option` 和结果枚举的每个分支都应有明确处理。

## 概念

| 主题 | 解决的问题 |
|---|---|
| [窗口与事件循环](concepts/window-events-lifecycle.md) | 事件、更新、绘制和退出应该按什么顺序执行？ |
| [逻辑坐标与高 DPI](concepts/render-scene-coordinates.md) | 为什么窗口尺寸、后备像素和渲染倍率不能混用？ |
| [资源所有权](concepts/resource-ownership.md) | 谁创建、使用和关闭窗口、纹理及其他资源？ |
| [文字与字体缓存](concepts/text-font-cache.md) | 怎样保证度量与绘制一致，并避免重复塑形？ |
| [Surface、Texture 与图片](concepts/surface-texture-image.md) | CPU 像素和渲染器纹理分别适合什么场景？ |
| [输入事件与持续状态](concepts/input-state.md) | 一次事件和跨帧按住状态怎样分工？ |
| [时间步长与游戏循环](concepts/game-loop-timing.md) | 怎样让更新速度不依赖刷新率？ |

## 任务手册

### 绘制与资源

- [绘制图形与自适应布局](how-to/draw-shapes-and-layout.md)
- [排版文字与选择字体](how-to/text-and-fonts.md)
- [加载图片、绘制纹理并保存截图](how-to/images-textures-screenshot.md)
- [无窗口测试与渲染计数](how-to/test-headless-and-instrument.md)

### 输入与桌面交互

- [处理输入、光标与拖放](how-to/input-cursor-drop.md)
- [使用剪贴板、文件对话框与消息框](how-to/clipboard-and-dialogs.md)
- [查询显示器、控制窗口并切换全屏](how-to/displays-fullscreen-window.md)

### 系统与交付

- [管理文件系统与应用路径](how-to/filesystem-and-paths.md)
- [设置应用元数据与 SDL Hints](how-to/hints-and-metadata.md)
- [使用系统信息、时间与电源状态](how-to/system-time-power.md)
- [部署 SDL 原生运行库](how-to/deploy-native-runtime.md)

## 完整教程

- [构建多文件计算器](tutorials/multi-file-calculator.md)：桌面工具的职责划分与输入闭环。
- [构建实时小游戏](tutorials/real-time-game.md)：持续输入、时间步长、更新和绘制。
- [构建平台诊断工具](tutorials/platform-toolbox.md)：在创建窗口前检查运行环境。

## 排错

- [构建、动态库与字体](troubleshooting/build-runtime-fonts.md)
- [渲染、坐标与截图](troubleshooting/render-output.md)
- [事件、资源与平台能力](troubleshooting/events-resources-platform.md)

## API 快速入口

- [窗口、事件、绘制、文字和图片](../api/sdl/index.md)
- [键鼠、剪贴板和光标](../api/sdl/input/index.md)
- [消息框与文件对话框](../api/sdl/dialogs/index.md)
- [显示器与全屏模式](../api/sdl/displays/index.md)
- [路径、文件、时间和系统信息](../api/sdl/system/index.md)

## 文档质量

[文档验证说明](_verification.md)列出了公开 API、链接、代码示例、库测试和示例工程的检查方法。所有仓颉示例都必须是可独立编译的完整程序；API 声明则与源码公开面自动对照。
