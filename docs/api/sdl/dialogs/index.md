[sdl](../../index.md) › sdl.dialogs

# sdl.dialogs

```cangjie
import sdl.dialogs.*
```

原生消息框与异步文件对话框。消息框（[`showSimpleMessageBox`](functions.md#showsimplemessagebox) / [`showMessageBox`](functions.md#showmessagebox)）是同步的——关闭后才返回；文件对话框（[`FileDialogs`](FileDialogs.md)）是异步的——立即返回 [`FileDialogRequest`](FileDialogRequest.md)，在事件循环中轮询结果。两类对话框都可挂到某个 [`SdlWindow`](../SdlWindow.md) 作为父窗口。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`FileDialogRequest`](FileDialogRequest.md) | 用于跟踪一次正在进行的文件对话框请求。 |
| [`FileDialogs`](FileDialogs.md) | 原生文件对话框的发起入口：打开文件、保存文件、选择文件夹。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`FileDialogFilter`](FileDialogFilter.md) | 文件对话框的一条类型过滤器：显示名加分号分隔的扩展名模式（SDL 语法，如 `"png;jpg"`，`"*"` 匹配全部）。 |
| [`FileDialogOptions`](FileDialogOptions.md) | 发起文件对话框时的选项：类型过滤器、初始目录与是否允许多选。 |
| [`MessageBoxButton`](MessageBoxButton.md) | 消息框中的一个按钮：标签、返回给调用者的编号，以及是否绑定回车/Esc 快捷键。 |
| [`MessageBoxColor`](MessageBoxColor.md) | 消息框配色中的一项 RGB 颜色（无 alpha——原生消息框不支持透明）。 |
| [`MessageBoxColorScheme`](MessageBoxColorScheme.md) | 消息框的整套配色：背景、文字、按钮边框、按钮底色与选中按钮。 |
| [`MessageBoxOptions`](MessageBoxOptions.md) | 自定义消息框的完整描述：标题、正文、级别、按钮列表、按钮方向与可选配色。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`FileDialogResult`](FileDialogResult.md) | 一次文件对话框请求的状态：进行中、被取消、已选中或失败。 |
| [`MessageBoxButtonOrder`](MessageBoxButtonOrder.md) | 消息框按钮的排列方向。 |
| [`MessageBoxKind`](MessageBoxKind.md) | 消息框的严重级别，决定原生对话框的图标样式。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`showSimpleMessageBox`](functions.md#showsimplemessagebox) | 弹出只有一个"确定"按钮的原生消息框，用户关闭后返回。 |
| [`showMessageBox`](functions.md#showmessagebox) | 按 `MessageBoxOptions` 弹出自定义按钮的原生消息框，返回用户点击的按钮编号。 |
