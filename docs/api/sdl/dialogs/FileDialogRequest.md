[sdl](../../index.md) › [sdl.dialogs](index.md) › FileDialogRequest

# FileDialogRequest

`sdl.dialogs` 包中的 public class

用于跟踪一次正在进行的文件对话框请求。对话框是异步的：[`FileDialogs`](FileDialogs.md) 立即返回本对象，应用在事件循环中轮询 [`isDone`](#isdone)/[`result`](#result)，原生回调把结果写入后即可读取。内部以互斥锁同步，跨线程读取安全。

## 声明

```cangjie
public class FileDialogRequest
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, UiEvent, WindowSpec}
import sdl.dialogs.{FileDialogRequest, FileDialogResult, FileDialogs}

main(): Unit {
    try (window = SdlWindow(WindowSpec("选择文件", 640, 480))) {
        let request: FileDialogRequest = FileDialogs.openFile(window: Some(window))
        var running = true
        while (running && !request.isDone()) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case _ => ()
                }
            }
            window.delay(16)
        }
        match (request.result()) {
            case FileDialogResult.FileDialogSelected(paths, _) => println("选中 ${paths.size} 个文件")
            case FileDialogResult.FileDialogCanceled => println("已取消")
            case FileDialogResult.FileDialogFailed(message) => println("打开失败：${message}")
            case FileDialogResult.FileDialogPending => println("窗口已关闭，对话框尚未完成")
        }
    }
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`result()`](#result) | 当前结果快照；回调完成前为 `FileDialogResult.FileDialogPending`。 |
| [`isDone()`](#isdone) | 判断对话框是否已到终态（已选中、已取消或失败）。 |

## 方法

### result

当前结果快照；回调完成前为 [`FileDialogResult.FileDialogPending`](FileDialogResult.md#filedialogpending)。加锁读取，可在任意线程调用。

```cangjie
public func result(): FileDialogResult
```

**返回值** `FileDialogResult` — 当前状态。

### isDone

判断对话框是否已到终态（已选中、已取消或失败）。

```cangjie
public func isDone(): Bool
```

**返回值** `Bool` — 非 `FileDialogPending` 时为 `true`。

## 另请参阅

- [FileDialogs](FileDialogs.md) — 请求的发起入口。
- [FileDialogResult](FileDialogResult.md) — 结果的四种状态。
