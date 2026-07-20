# SDL 应用开发指南

SDL 模块是 SDL3 与 SDL3_ttf 的仓颉安全封装，适合自绘桌面工具、轻量媒体程序和 2D 游戏。本指南不把 81 个类型重新排成另一份成员清单，而是围绕真实结果组织：先打开窗口，再建立事件与渲染模型，随后完成多文件计算器和实时游戏，最后接入字体、图片、剪贴板、对话框、文件、显示器、系统信息与部署。精确签名、默认值和异常条件请查独立的 [SDL API 参考](../api/index.md)。

## 如何使用这套指南

第一次接触 SDL 时，请按“学习路径”连续完成；每页都说明进入时已有的产物、离开时新增的能力和肉眼或终端可见的确认标准。教程给出含包声明、导入和 `main` 的完整程序；how-to 若继承已有程序，会明确指出基页和插入位置；概念页解释为什么这样组织；排错页按症状给出探针、修复与复测。完整程序的编译、格式化、运行与截图证据汇总在[验证报告](_verification.md)。

如果你正在维护已有项目，可从“按任务查找”直接进入。页面末尾的“相关 API”落到最窄的类型页，不要求先读完整包索引。非视觉能力以输出、退出码、文件或测试断言确认；GUI 能力除编译外还保留真实窗口截图、尺寸、哈希和捕获命令，避免把“能编译”误当成“画面正确”。

## 从这里开始

开始前需要 `cjpm 1.0.5`、仓颉编译器，以及能访问本仓库 `sdl` 目录的本地路径。Windows 运行可见窗口还需让 `SDL3.dll` 与 `SDL3_ttf.dll` 可被进程加载；首次构建只验证仓颉依赖，首次运行才会验证动态库、显示环境和系统字体。你只需会写包声明、导入、变量和 `match`，不需要预先理解 SDL 的 C 接口。

先留出约二十分钟完成[首个 SDL 窗口](getting-started/first-window.md)。它从一个空目录和两份文件开始，最终显示一个可调整大小、能正常关闭的窗口。成功标准不是“命令没有报错”，而是窗口标题与卡片文字可见、调整尺寸后仍能绘制、点击关闭后终端重新出现提示符。

接着按顺序阅读[窗口与事件循环](concepts/window-events-lifecycle.md)、[场景、坐标与高 DPI](concepts/render-scene-coordinates.md)和[绘制图形与布局](how-to/draw-shapes-and-layout.md)。这三页分别回答“输入何时处理”“尺寸怎样换算”和“控件怎样画”。随后阅读[资源所有权](concepts/resource-ownership.md)，再完成[多文件计算器](tutorials/multi-file-calculator.md)。这条路径最终落到真实的 `main.cj`、`state.cj`、`logic.cj`、`loop.cj`、`render.cj` 与 `theme.cj`，不是只停在 `main` 里的核心片段。

若首个窗口构建失败，立即进入[构建、动态库与字体排错](troubleshooting/build-runtime-fonts.md)，不要一边改依赖一边继续增加绘制代码。窗口可见但画面异常时使用[渲染与截图排错](troubleshooting/render-output.md)；窗口无响应、资源关闭报错或平台能力不同则使用[事件、资源与平台排错](troubleshooting/events-resources-platform.md)。

## 学习路径

### 入门：从空项目到多文件计算器

[首个窗口](getting-started/first-window.md) → [窗口与事件循环](concepts/window-events-lifecycle.md) → [场景、坐标与高 DPI](concepts/render-scene-coordinates.md) → [绘制图形与布局](how-to/draw-shapes-and-layout.md) → [资源所有权](concepts/resource-ownership.md) → [多文件计算器](tutorials/multi-file-calculator.md)。完成后，你不仅能画按钮，还能解释事件、状态、业务逻辑和渲染为什么放在不同文件，并能独立增加一个按键而不改动所有层。

### 进阶：从输入状态到实时游戏

从[多文件计算器](tutorials/multi-file-calculator.md)进入[输入事件与持续状态](concepts/input-state.md)、[时间步长与游戏循环](concepts/game-loop-timing.md)和[实时小游戏](tutorials/real-time-game.md)，再用[渲染排错](troubleshooting/render-output.md)与[事件、资源和平台排错](troubleshooting/events-resources-platform.md)完成诊断训练。该路径同时覆盖设计、诊断与扩展：你会把按键边沿变成持续状态，限制异常长帧，并在真实 `thunder`/`contra` 分层中定位新增玩法应落在哪一层。

### 平台与交付：从诊断探针到发布目录

从[平台诊断工具](tutorials/platform-toolbox.md)开始，依次学习[文本与缓存](concepts/text-font-cache.md)、[文字排版](how-to/text-and-fonts.md)、[Surface 与 Texture](concepts/surface-texture-image.md)、[图片与截图](how-to/images-textures-screenshot.md)、[输入和光标](how-to/input-cursor-drop.md)、[剪贴板与对话框](how-to/clipboard-and-dialogs.md)、[文件与路径](how-to/filesystem-and-paths.md)、[显示器与全屏](how-to/displays-fullscreen-window.md)、[Hints 与元数据](how-to/hints-and-metadata.md)、[时间与电源](how-to/system-time-power.md)、[部署](how-to/deploy-native-runtime.md)和[无窗口测试](how-to/test-headless-and-instrument.md)。

## 按任务查找

| 当前目标 | 入口 | 完成后怎样确认 |
|---|---|---|
| 从空目录打开窗口 | [首个 SDL 窗口](getting-started/first-window.md) | 卡片可见，窗口可缩放并正常退出 |
| 理清事件与退出顺序 | [窗口与事件循环](concepts/window-events-lifecycle.md) | 能画出 poll → update → draw 的顺序 |
| 处理逻辑坐标和高 DPI | [场景、坐标与高 DPI](concepts/render-scene-coordinates.md) | 缩放后布局比例与命中位置一致 |
| 绘制圆角、渐变、描边和裁剪 | [绘制图形与布局](how-to/draw-shapes-and-layout.md) | 卡片边缘清晰，内容不越过裁剪区 |
| 完成职责分离的 GUI 工程 | [多文件计算器](tutorials/multi-file-calculator.md) | 鼠标与键盘共用逻辑，六个源文件职责清楚 |
| 让移动速度不依赖帧率 | [实时小游戏](tutorials/real-time-game.md) | 不同刷新率下移动速度近似相同 |
| 在无窗口环境读取平台、路径和电源 | [平台诊断工具](tutorials/platform-toolbox.md) | 七项环境字段有输出，命令退出码为 0 |
| 对齐中英文和数字读数 | [文字与字体](how-to/text-and-fonts.md) | 度量和绘制使用同一字号、样式与字体 |
| 加载 PNG/BMP、纹理或截图 | [图片、纹理与截图](how-to/images-textures-screenshot.md) | 图片可见，BMP 文件非空且可打开 |
| 处理键鼠、文本、拖放和光标 | [输入、光标与拖放](how-to/input-cursor-drop.md) | 一次事件与持续状态没有混用 |
| 接入剪贴板、文件选择和确认框 | [剪贴板与对话框](how-to/clipboard-and-dialogs.md) | Pending、Selected、Canceled、Failed 都有分支 |
| 选择配置、资源和用户文件目录 | [文件系统与路径](how-to/filesystem-and-paths.md) | 输出路径属于预期目录且文件信息可读 |
| 查询显示器并切换全屏 | [显示器、窗口和全屏](how-to/displays-fullscreen-window.md) | 模式来自当前显示器，退出全屏可恢复 |
| 设置应用身份与 SDL Hint | [Hints 与元数据](how-to/hints-and-metadata.md) | 设置发生在窗口创建前并可读回 |
| 区分墙钟、性能计时和电源策略 | [系统、时间与电源](how-to/system-time-power.md) | 输出包含日期、耗时和可选电量 |
| 打包 Windows 原生依赖 | [部署原生运行库](how-to/deploy-native-runtime.md) | 干净目录中的程序仍能启动 |
| 为布局和缓存写快速测试 | [无窗口测试与计数](how-to/test-headless-and-instrument.md) | 断言退出码为 0，视觉测试仍单独执行 |
| 定位 DLL、字体或依赖失败 | [构建、动态库与字体排错](troubleshooting/build-runtime-fonts.md) | 最小探针明确失败阶段 |
| 定位空白、模糊、裁剪或截图 | [渲染与截图排错](troubleshooting/render-output.md) | 修复后画面和文件均可观察 |
| 定位无响应、关闭错误或平台差异 | [事件、资源与平台排错](troubleshooting/events-resources-platform.md) | 输入恢复、资源只关闭一次、能力重新查询 |

## 核心概念

七个概念页组成稳定的工作模型：[窗口与事件循环](concepts/window-events-lifecycle.md)说明每帧顺序；[场景、逻辑坐标与高 DPI](concepts/render-scene-coordinates.md)说明布局尺寸如何落到像素；[资源所有权](concepts/resource-ownership.md)说明谁负责关闭；[文字度量与缓存](concepts/text-font-cache.md)说明排版和性能；[Surface 与 Texture](concepts/surface-texture-image.md)说明 CPU 像素与渲染资源；[输入事件与持续状态](concepts/input-state.md)说明边沿和电平；[时间步长与帧循环](concepts/game-loop-timing.md)说明不同刷新率下的稳定更新。

## API 参考

需要准确成员时使用 [SDL API 参考](../api/index.md)。先按问题选择包：窗口和事件查 [`sdl`](../api/sdl/index.md)，剪贴板查 [`sdl.input`](../api/sdl/input/index.md)，对话框查 [`sdl.dialogs`](../api/sdl/dialogs/index.md)，显示器查 [`sdl.displays`](../api/sdl/displays/index.md)，文件、时间与系统信息查 [`sdl.system`](../api/sdl/system/index.md)。

进入核心包后，窗口生命周期落到 [`SdlWindow`](../api/sdl/SdlWindow.md) 和 [`UiEvent`](../api/sdl/UiEvent.md)，绘制落到 [`Renderer`](../api/sdl/Renderer.md)，图片资源落到 [`Surface`](../api/sdl/Surface.md) 与 [`Texture`](../api/sdl/Texture.md)。这样先做读者决策，再看具体类型，不把一段说明堆成标识符列表。

## 故障排查

先按发生阶段选择页面。编译期、启动期或字体初始化失败看[构建、动态库与字体](troubleshooting/build-runtime-fonts.md)；窗口已出现但空白、模糊、被裁剪或截图错误看[渲染与输出](troubleshooting/render-output.md)；窗口无响应、输入滞后、资源关闭后仍被使用、对话框不返回或全屏模式不兼容看[事件、资源与平台](troubleshooting/events-resources-platform.md)。每个症状分支都要求运行具体探针并确认可观察结果，不以“检查配置”结束。
