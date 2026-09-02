# 使用剪贴板、文件对话框与消息框

## 目标

基于[首个窗口](../getting-started/first-window.md)，加入复制/粘贴文本、异步打开文件和放弃修改确认框。对话框的 Pending、Selected、Canceled、Failed 都有明确处理；应用等待对话框时仍继续轮询窗口事件，不会假死。

## 适用场景

适用于编辑器、图片查看器、导入导出工具和桌面设置程序。普通文本优先用 `Clipboard.setText/getText`；自定义 MIME 数据只在双方约定格式时使用，并限制外部数据大小。文件对话框用于让用户选择路径，不替代文件内容验证；消息框适合短确认，不适合复杂表单。

## 准备工作

保留首个窗口完整事件循环。为文件请求增加 `?FileDialogRequest` 状态，不在点击按钮时同步等待。过滤器扩展名按 SDL 接受的形式填写，如 `png`、`jpg`，不包含路径分隔符或通配符。剪贴板内容来自外部，进入业务前检查长度和格式。

## 操作步骤

点击“打开”时，用 `FileDialogOptions` 配置 `FileDialogFilter("图片", "png;jpg")` 和多选，再调用 `FileDialogs.openFile` 保存返回的 `FileDialogRequest`。每帧查询 `result()`：`FileDialogPending` 保留请求；`FileDialogSelected` 把路径交给业务队列；`FileDialogCanceled` 安静结束；`FileDialogFailed` 显示错误。后三种结果处理完后都清空请求。

复制和粘贴仍属于事件层的轻量操作：复制调用 `Clipboard.setText`；粘贴先查询 `hasText()`，再读取 `getText()` 并执行长度和格式检查。

真正读取文件放到请求终态之后，并先检查路径、扩展名与业务上限。窗口关闭时若请求仍 Pending，停止继续使用窗口，但保留清晰日志；不要把 Pending 当作取消。

## 确认结果

复制后在另一个程序粘贴，应得到完整文本；从外部复制再粘回，超长内容应触发业务限制。打开对话框期间主窗口仍能处理关闭和重绘。多选后路径数组数量正确，取消不显示错误，失败显示 SDL 返回的消息。消息框回车和 Escape 默认按钮符合设计。非交互自动测试可覆盖结果分支，真实对话框仍需人工执行并记录选择结果。

## 常见错误

调用 `result()` 一次看到 Pending 就判失败，会丢失正常异步结果；在紧密循环中等待而不轮询窗口会造成无响应。过滤器写 `*.png` 或完整路径可能不被后端接受。剪贴板 MIME 与数据数组数量不匹配会失败；外部二进制数据必须限制大小。消息框按钮 ID 应稳定且唯一，不要依赖数组下标作为业务结果。

## 可以继续修改

加入双按钮“放弃修改”确认：把 `MessageBoxOptions.kind` 设为 `Warning`，为“放弃”使用稳定 ID 1，为“返回”使用 ID 0，并把后者同时设为回车和 Esc 默认按钮。`showMessageBox` 返回的是按钮 ID，不是数组位置；只有结果为 1 时才丢弃修改。

## 相关 API

- [`Clipboard`](../../api/sdl/input/Clipboard.md)：文本、主选择和 MIME 数据。
- [`FileDialogs`](../../api/sdl/dialogs/FileDialogs.md)：打开、保存和文件夹请求。
- [`FileDialogResult`](../../api/sdl/dialogs/FileDialogResult.md)：异步状态。
- [`MessageBoxOptions`](../../api/sdl/dialogs/MessageBoxOptions.md) 与[消息框函数](../../api/sdl/dialogs/functions.md)：确认对话框。

## 下一步

继续[文件系统与应用路径](filesystem-and-paths.md)，把用户选中的路径与应用自己的配置目录区分开。
