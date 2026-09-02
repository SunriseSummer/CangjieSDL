# 处理输入、光标与拖放

## 目标

在[首个窗口](../getting-started/first-window.md)中同时处理快捷键、文本输入、鼠标状态、系统光标和文件拖放；一次性动作与持续状态分开，拖放序列收集完成后才交给业务层。

## 适用场景

适用于编辑器、计算器、画布、文件查看器和游戏菜单。文本内容用 `TextInput`，导航和快捷键用 `KeyDown`，持续移动配对处理 KeyDown/KeyUp。需要拖入多个文件时，不要在第一个 DropFile 到达就结束本次操作。

## 准备工作

先阅读[输入事件与持续状态](../concepts/input-state.md)。保留首个窗口完整事件循环，增加 `hovered`、`typedText` 和 `droppedPaths` 等状态。系统光标是 Resource，应由外层资源块拥有；鼠标捕获或相对模式在结束时恢复。

## 操作步骤

在事件匹配中，让 Esc 改变运行状态，Backspace 调用按 Unicode 字符删除的业务函数，`TextInput` 追加系统已经组合好的文字，`MouseMove` 只更新逻辑坐标。拖放开始时清空本次集合，`DropFile` 只累计路径，`DropComplete` 才把完整列表交给加载队列。不要在事件分支内执行耗时文件读取。

窗口创建后可用 `Cursor.system(SystemCursor.Pointer)` 创建并激活指针光标；悬停可点击区域时切换 Hand，离开后切回默认。不要每次 MouseMove 都创建新 Cursor，预先创建并复用。

## 确认结果

输入中文和英文时，画面中的 `typedText` 与系统提交内容一致；Backspace 只删除一个 Unicode 字符而不是破坏编码。移动鼠标时坐标与逻辑按钮位置一致。一次拖入多个文件时，日志先出现 Begin，再出现所有路径，最后只调用一次处理。光标进入按钮变成手形，离开恢复。关闭窗口后 Cursor 和窗口都只关闭一次，进程退出码为 0。

## 常见错误

只处理 KeyDown 而忽略 TextInput 会让输入法和键盘布局失效；按字节截断中文字符串会产生非法文本。每个 DropFile 立刻加载会阻塞事件队列，并在多选时重复刷新。Cursor 枚举不是资源实例，创建出的 Cursor 仍要关闭。相对鼠标模式适合第一人称控制，不适合普通按钮；忘记恢复会让系统光标行为异常。

## 可以继续修改

加入以指针位置为中心的滚轮缩放时，按 `MouseWheel(wheelX, wheelY, pointerX, pointerY)` 的顺序解构；用 `clampF32` 把缩放限制在 0.5 到 3.0，并保存当前指针为中心。物理 R 键可用 `Key.Letter(UInt8(82))` 匹配，且只在 `repeat = false` 时复位。

确认滚轮向上和向下改变缩放，缩放中心跟随当前指针，物理 R 键恢复初始值；文本输入仍只经过 `TextInput`。

## 相关 API

- [`UiEvent`](../../api/sdl/UiEvent.md)：键鼠、文本和拖放事件精确载荷。
- [`Keyboard`](../../api/sdl/input/Keyboard.md)：修饰键状态。
- [`Mouse`](../../api/sdl/input/Mouse.md)：状态、捕获和缩放。
- [`Cursor`](../../api/sdl/input/Cursor.md) 与 [`SystemCursor`](../../api/sdl/input/SystemCursor.md)：光标资源。

## 下一步

继续[剪贴板与对话框](clipboard-and-dialogs.md)，把外部文本、文件选择和用户确认接入同一事件驱动应用。
