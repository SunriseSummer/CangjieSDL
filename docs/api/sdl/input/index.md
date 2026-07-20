[sdl](../../index.md) › sdl.input

# sdl.input

```cangjie
import sdl.input.*
```

剪贴板、鼠标状态、键盘修饰键与系统光标。本包提供轮询式与进程级的输入设施；逐事件的输入流（按键、指针、滚轮、拖放）在 [`sdl`](../index.md) 包经 [`UiEvent`](../UiEvent.md) 到达。剪贴板与光标要求视频子系统已初始化（通常已有窗口）。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`Clipboard`](Clipboard.md) | SDL3 剪贴板的主线程访问入口：普通文本、主选择文本（X11 的选中即复制），以及带 MIME 类型的二进制数据。 |
| [`Cursor`](Cursor.md) | 一个原生鼠标光标对象，加上光标显隐的静态控制。 |
| [`Keyboard`](Keyboard.md) | 键盘的轮询式查询入口，当前提供修饰键状态。 |
| [`Mouse`](Mouse.md) | 鼠标的轮询式查询与捕获控制。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`ClipboardData`](ClipboardData.md) | 一段二进制剪贴板数据及其 MIME 类型，供 `Clipboard.setData` 批量提交给其他桌面应用。 |
| [`KeyModifiers`](KeyModifiers.md) | 某一时刻的修饰键状态：把 SDL 修饰键掩码展开为逐项布尔字段，左右同键合并（左 Shift 或右 Shift 都算 `shift`），另有跨平台的 `command` 便捷位（Ctrl 或 GUI 键任一按下）。 |
| [`MouseState`](MouseState.md) | 某一时刻的鼠标快照：指针位置（已按窗口缩放折算为逻辑像素）、左中右三键的按下状态与原始按键掩码。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`SystemCursor`](SystemCursor.md) | 操作系统内置的光标形状，交给 `Cursor.system` 创建对应的原生光标。 |
