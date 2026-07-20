# 事件、资源与平台能力排错

## 先看现象

本页处理三类跨边界问题：窗口无响应或输入滞后，关闭后继续使用 Surface/Texture/Cursor，对话框、显示器或全屏能力在某个平台返回不同结果。诊断目标是先区分事件顺序、资源生命周期和能力可用性，再选择修复；不要用吞掉 `CuiException` 的方式制造假正常。

## 可能原因

无响应常因事件未取空、事件分支执行耗时 I/O 或只处理按下不处理抬起；资源错误常因借用超过拥有者、纹理跨 Renderer、重复关闭；平台差异常因把 Option 当必有值、把异步 Pending 当失败、缓存显示器 ID 或调用平台不支持的窗口控制。线程越界也会让这些问题随机出现。

## 诊断步骤

### 症状一：窗口卡住、输入延迟或角色松键后仍移动

为每帧记录处理事件数、耗时和最后事件类型，检查内层循环是否持续调用 `pollEvent` 直到 None。把文件加载和网络工作暂时替换为计数，比较响应是否恢复。下面探针将 KeyDown/KeyUp 转换为状态并打印变化；确认按下和抬起各出现一次，状态最终回到 false。

```cangjie role=probe
case UiEvent.KeyDown(Key.Right, repeat) => {
    println("right down repeat=${repeat}")
    rightHeld = true
}
case UiEvent.KeyUp(Key.Right) => {
    println("right up")
    rightHeld = false
}
```

修复时让事件层只更新轻量状态，耗时任务进入队列，更新阶段分批处理；无论是否有事件，每帧都能更新和绘制。确认快速移动鼠标、拖放多个文件和连续按键时窗口仍响应，事件队列不会持续增长。

```cangjie role=fix
var current = window.pollEvent()
while (let Some(event) <- current) {
    translateEvent(event, inputState, workQueue)
    current = window.pollEvent()
}
processWorkBudget(workQueue, milliseconds: UInt64(3))
update(state, inputState, dt)
draw(window.renderer, state)
```

### 症状二：出现“已关闭”、无效纹理或退出时崩溃

列出每个 Resource 的创建、最后使用和关闭位置，检查 Texture 是否由当前窗口 Renderer 创建，Surface 转 Texture 后谁关闭两者，Cursor 是否仍被激活。运行 `isClosed()` 或最小资源测试确认失败点。修复为嵌套 try-with-resources 或集中 Assets 拥有者，退出时先停止循环、关闭 Texture/Cursor，最后关闭窗口。确认异常与正常退出都只执行一次关闭，关闭后没有定时回调继续绘制。

### 症状三：文件对话框一直 Pending、全屏无匹配或平台信息为空

对话框 Pending 是异步进行中，继续轮询窗口并定期读取 `result()`；只有 Failed 才记录错误。显示器模式和用户目录允许没有结果，重新调用枚举确认设备当前状态，不复用上次运行的 ID。全屏模式找不到时退回桌面全屏或窗口模式。确认取消对话框走 Canceled、设备插拔后列表更新、None 路径显示“不可用”且应用仍能操作；这比强行解包更可靠。

## 修复方法

事件问题缩短事件分支并建立工作预算；资源问题收窄所有权并停止关闭后的借用；平台问题保留 Option/结果枚举的全部分支并提供降级。UI 资源操作留在同一线程。任何捕获异常的代码都要把 API 名和 SDL 消息写入状态或日志，不能只返回 false。

## 确认已经修复

持续输入与拖放时窗口仍可移动和关闭；松键后状态恢复；正常、异常和用户关闭三条路径退出码都可解释；资源计数不随重复打开持续增长；对话框四种结果均覆盖；显示器和路径缺失时降级可见。最后重跑计算器、实时游戏、对话框和显示器场景，记录当前源代码哈希与结果。

## 避免再次发生

事件层只翻译，业务层不直接拥有窗口；资源创建与关闭放在同一结构附近；平台返回的 Option 与结果枚举不被提前压平。为长任务设置每帧预算，为多窗口与设备插拔保留回归测试。API 库存变化后重跑指南/API 对账，避免文档继续引用已移除成员。

## 相关 API

- [`SdlWindow`](../../api/sdl/SdlWindow.md) 与 [`UiEvent`](../../api/sdl/UiEvent.md)：事件和生命周期。
- [`FileDialogRequest`](../../api/sdl/dialogs/FileDialogRequest.md)：异步完成状态。
- [显示器函数](../../api/sdl/displays/functions.md)：运行时设备枚举。
- [`Cursor`](../../api/sdl/input/Cursor.md)、[`Surface`](../../api/sdl/Surface.md) 与 [`Texture`](../../api/sdl/Texture.md)：资源边界。

## 下一步

排错闭环到此结束。回到[指南首页](../index.md)，按当前任务进入对应 how-to；需要精确签名时转到 [SDL API 参考](../../api/index.md)。
