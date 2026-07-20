[sdl](../../index.md) › [sdl.dialogs](index.md) › FileDialogResult

# FileDialogResult

`sdl.dialogs` 包中的 public enum

一次文件对话框请求的状态：进行中、被取消、已选中或失败。由 [`FileDialogRequest.result`](FileDialogRequest.md#result) 返回，对话框在原生线程回调完成后从 `FileDialogPending` 变为终态。

## 声明

```cangjie
public enum FileDialogResult
```

## 示例

```cangjie verify
package docexample

import sdl.dialogs.FileDialogResult

main(): Unit {
    // 模拟检查一次对话框结果；真实结果来自 FileDialogRequest.result()。
    let result = FileDialogResult.FileDialogSelected(["C:/data/report.csv"], Some(0))
    match (result) {
        case FileDialogResult.FileDialogPending => println("等待用户操作")
        case FileDialogResult.FileDialogCanceled => println("已取消")
        case FileDialogResult.FileDialogSelected(paths, filter) => println("选中 ${paths.size} 项")
        case FileDialogResult.FileDialogFailed(message) => println("失败：${message}")
    }
    // 输出: 选中 1 项
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`FileDialogPending`](#filedialogpending) | 对话框仍在等待用户操作。 |
| [`FileDialogCanceled`](#filedialogcanceled) | 用户取消了对话框（未选择任何内容）。 |
| [`FileDialogSelected(Array<String>, ?Int32)`](#filedialogselected) | 用户完成选择，携带选中路径列表与过滤器序号（对话框无过滤器时为 `None`）。 |
| [`FileDialogFailed(String)`](#filedialogfailed) | 对话框失败，携带错误信息。 |

## 枚举值

### FileDialogPending

对话框仍在等待用户操作。[`FileDialogRequest.isDone`](FileDialogRequest.md#isdone) 对此值返回 `false`。

```cangjie
FileDialogPending
```

### FileDialogCanceled

用户取消了对话框（未选择任何内容）。

```cangjie
FileDialogCanceled
```

### FileDialogSelected

用户完成选择，携带选中路径列表与过滤器序号（对话框无过滤器时为 `None`）。

```cangjie
FileDialogSelected(Array<String>, ?Int32)
```

### FileDialogFailed

对话框失败，携带错误信息。

```cangjie
FileDialogFailed(String)
```

## 另请参阅

- [FileDialogRequest](FileDialogRequest.md) — 结果的承载对象。
- [FileDialogs](FileDialogs.md) — 发起对话框。
