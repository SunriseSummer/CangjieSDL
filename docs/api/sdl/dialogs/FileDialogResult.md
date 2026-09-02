[API 参考](../../index.md) › [sdl.dialogs](index.md) › FileDialogResult

# FileDialogResult

异步文件对话框的当前状态。通过 [`FileDialogRequest.result`](FileDialogRequest.md#result) 查询。

```cangjie
public enum FileDialogResult {
    | FileDialogPending
    | FileDialogCanceled
    | FileDialogSelected(Array<String>, ?Int32)
    | FileDialogFailed(String)
}
```

## 示例

```cangjie verify role=complete
package docexample

import sdl.dialogs.FileDialogResult

main(): Unit {
    let result = FileDialogResult.FileDialogSelected(["C:/data/report.csv"], Some(0))
    match (result) {
        case FileDialogResult.FileDialogPending => println("等待用户操作")
        case FileDialogResult.FileDialogCanceled => println("已取消")
        case FileDialogResult.FileDialogSelected(paths, _) => println("选中 ${paths.size} 项")
        case FileDialogResult.FileDialogFailed(message) => println("失败：${message}")
    }
}
```

| 值 | 含义 |
|---|---|
| `FileDialogPending` | 对话框仍在等待用户操作；`isDone()` 返回 `false`。 |
| `FileDialogCanceled` | 用户取消，没有选中内容。 |
| `FileDialogSelected(Array<String>, ?Int32)` | 选中路径和可选的过滤器序号。 |
| `FileDialogFailed(String)` | 对话框失败，携带错误信息。 |

`Pending` 不是失败。事件循环应继续运行并定期查询，直到出现其他三种最终结果之一。
