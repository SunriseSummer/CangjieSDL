# 事件、资源与平台能力排错

## 先看现象

本页处理三类跨边界问题：窗口无响应或输入滞后，关闭后继续使用 Surface/Texture/Cursor，对话框、显示器或全屏能力在某个平台返回不同结果。诊断目标是先区分事件顺序、资源生命周期和能力可用性，再选择修复；不要用吞掉 `SdlException` 的方式制造假正常。

## 可能原因

无响应常因事件未取空、事件分支执行耗时 I/O、多个窗口各自争抢进程级事件队列，或只处理按下不处理抬起；资源错误常因借用超过拥有者、纹理/命令缓冲跨 Renderer、设备 reset 后重放旧资源、重复关闭或越过 Renderer 拥有线程；平台差异常因把 Option 当必有值、把异步 Pending 当失败、缓存显示器 ID 或调用平台不支持的窗口控制。

## 诊断步骤

### 症状一：窗口卡住、输入延迟或角色松键后仍移动

为每帧记录处理事件数、耗时和最后事件类型，检查内层循环是否持续调用 `pollEvent` 直到 `None`。多窗口时确认只有一个 `SdlEventPump` 消费事件，并按 `metadata.windowId` 路由。把文件加载和网络工作暂时替换为计数，比较响应是否恢复。对于持续按键，记录 `KeyDown` 的 repeat 值和对应 `KeyUp`，确认状态最终恢复为 `false`。

修复时让事件层只更新轻量状态，耗时任务进入队列，更新阶段按明确的毫秒预算分批处理。每帧先取空事件，再处理一小段工作、更新状态并绘制；即使当前没有事件也不能跳过更新和绘制。快速移动鼠标、拖放多个文件和连续按键时，窗口仍应响应，事件队列也不应持续增长。

### 症状二：出现“已关闭”、无效纹理或退出时崩溃

列出每个资源的创建、最后使用和关闭位置，检查 `Texture`、`RenderCommandBuffer` 和 `TextMeasureSession` 是否来自当前 `Renderer`，并确认调用线程正确；还要明确 `Surface` 转为 `Texture` 后谁关闭两者，以及 `Cursor` 是否仍在使用。收到 `RenderTargetsReset`、`RenderDeviceReset` 或 `RenderDeviceLost` 后，先调用旧命令缓冲的 `isReplayable`，再从普通应用数据重建 GPU 资源。修复时使用嵌套的 `try (...)` 或集中资源所有者；退出应先停止循环，再关闭纹理和光标，最后关闭窗口。

### 症状三：文件对话框一直 Pending、全屏无匹配或平台信息为空

对话框 Pending 是异步进行中，继续轮询窗口并定期读取 `result()`；只有 Failed 才记录错误。显示器模式和用户目录允许没有结果，重新调用枚举确认设备当前状态，不复用上次运行的 ID。全屏模式找不到时退回桌面全屏或窗口模式。确认取消对话框走 Canceled、设备插拔后列表更新、None 路径显示“不可用”且应用仍能操作；这比强行解包更可靠。

## 修复方法

事件问题缩短事件分支并建立工作预算，多窗口统一由 `SdlEventPump` 消费；资源问题收窄所有权、保持 Renderer 线程亲和性，并把设备 reset 当作资源代数失效边界；平台问题保留 Option/结果枚举的全部分支并提供降级。任何捕获异常的代码都要把 API 名和 SDL 消息写入状态或日志，不能只返回 false。

## 确认已经修复

持续输入与拖放时窗口仍可移动和关闭；松键后状态恢复；正常、异常和用户关闭三条路径退出码都可解释；资源计数不随重复打开持续增长；对话框四种结果均覆盖；显示器和路径缺失时降级可见。最后重跑计算器、实时游戏、对话框和显示器场景，记录当前源代码哈希与结果。

## 避免再次发生

事件层只负责转换，业务层不直接拥有窗口；资源创建与关闭放在相近位置；平台返回的 `Option` 和结果枚举应保留“不可用”与“失败”等差异。为长任务设置每帧预算，为多窗口与设备插拔保留回归测试。公开 API 变化后重新运行文档检查，避免继续引用已经移除的成员。

## 相关 API

- [`SdlWindow`](../../api/sdl/SdlWindow.md) 与 [`UiEvent`](../../api/sdl/UiEvent.md)：事件和生命周期。
- [`SdlEventPump`](../../api/sdl/SdlEventPump.md) 与 [`UiEventRecord`](../../api/sdl/UiEventRecord.md)：多窗口路由和事件时元数据。
- [`RenderCommandBuffer`](../../api/sdl/RenderCommandBuffer.md)：拥有者、设备代数与 replay 可用性。
- [`FileDialogRequest`](../../api/sdl/dialogs/FileDialogRequest.md)：异步完成状态。
- [显示器函数](../../api/sdl/displays/functions.md)：运行时设备枚举。
- [`Cursor`](../../api/sdl/input/Cursor.md)、[`Surface`](../../api/sdl/Surface.md) 与 [`Texture`](../../api/sdl/Texture.md)：资源边界。

## 下一步

排错闭环到此结束。回到[指南首页](../index.md)，按当前任务进入对应 how-to；需要精确签名时转到 [SDL API 参考](../../api/index.md)。
