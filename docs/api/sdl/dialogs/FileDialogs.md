[sdl](../../index.md) › [sdl.dialogs](index.md) › FileDialogs

# FileDialogs

`sdl.dialogs` 包中的 public class

原生文件对话框的发起入口：打开文件、保存文件、选择文件夹。三个方法都立即返回 [`FileDialogRequest`](FileDialogRequest.md)，结果经原生回调异步送达——发起后继续跑事件循环并轮询请求对象。原生对话框启动或执行失败不会从发起方法抛出，而是由回调写成 `FileDialogResult.FileDialogFailed`。

## 声明

```cangjie
public class FileDialogs
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, UiEvent, WindowSpec}
import sdl.dialogs.{FileDialogFilter, FileDialogOptions, FileDialogResult, FileDialogs}

main(): Unit {
    try (window = SdlWindow(WindowSpec("导出", 640, 480))) {
        let options = FileDialogOptions(
            filters: [FileDialogFilter("CSV 文件", "csv")],
            defaultLocation: Some("C:/Users")
        )
        let request = FileDialogs.saveFile(options: options, window: Some(window))
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
            case FileDialogResult.FileDialogSelected(paths, _) => println("保存到 ${paths[0]}")
            case FileDialogResult.FileDialogCanceled => println("已取消")
            case FileDialogResult.FileDialogFailed(message) => println("保存失败：${message}")
            case FileDialogResult.FileDialogPending => println("窗口已关闭，对话框尚未完成")
        }
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `FileDialogs` 对象；文件对话框由静态方法发起。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static openFile(options!: FileDialogOptions, window!: ?SdlWindow)`](#openfile) | 弹出打开文件对话框，立即返回请求对象。 |
| [`static saveFile(options!: FileDialogOptions, window!: ?SdlWindow)`](#savefile) | 弹出保存文件对话框，立即返回请求对象。 |
| [`static openFolder(options!: FileDialogOptions, window!: ?SdlWindow)`](#openfolder) | 弹出选择文件夹对话框，立即返回请求对象。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `FileDialogs` 对象；文件对话框由静态方法发起。

```cangjie
public init()
```

## 方法

### openFile

弹出打开文件对话框，立即返回请求对象。`options.allowMany` 为 `true` 时允许多选。

```cangjie
public static func openFile(options!: FileDialogOptions = FileDialogOptions(), window!: ?SdlWindow = None): FileDialogRequest
```

**参数**

- `options!`: `FileDialogOptions` — 过滤器、初始目录与多选开关；默认全部缺省。
- `window!`: `?SdlWindow` — 作为父窗口的窗口；默认 `None`（无父窗口）。

**返回值** `FileDialogRequest` — 用于轮询异步结果的请求对象。

**异常**

- `CuiException` — 对话框选项非法时。

### saveFile

弹出保存文件对话框，立即返回请求对象。

```cangjie
public static func saveFile(options!: FileDialogOptions = FileDialogOptions(), window!: ?SdlWindow = None): FileDialogRequest
```

**参数**

- `options!`: `FileDialogOptions` — 过滤器与初始目录（多选开关对保存无效）；默认全部缺省。
- `window!`: `?SdlWindow` — 作为父窗口的窗口；默认 `None`。

**返回值** `FileDialogRequest` — 用于轮询异步结果的请求对象。

**异常**

- `CuiException` — 对话框选项非法时。

### openFolder

弹出选择文件夹对话框，立即返回请求对象。`options.allowMany` 允许选择多个文件夹；过滤器对文件夹选择无效。

```cangjie
public static func openFolder(options!: FileDialogOptions = FileDialogOptions(), window!: ?SdlWindow = None): FileDialogRequest
```

**参数**

- `options!`: `FileDialogOptions` — 初始目录与多选开关；默认全部缺省。
- `window!`: `?SdlWindow` — 作为父窗口的窗口；默认 `None`。

**返回值** `FileDialogRequest` — 用于轮询异步结果的请求对象。

**异常**

- `CuiException` — 对话框选项非法时。

## 另请参阅

- [FileDialogOptions](FileDialogOptions.md) · [FileDialogFilter](FileDialogFilter.md) — 选项类型。
- [FileDialogRequest](FileDialogRequest.md) · [FileDialogResult](FileDialogResult.md) — 结果的轮询与读取。
