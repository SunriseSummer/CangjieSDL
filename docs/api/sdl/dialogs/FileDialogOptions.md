[sdl](../../index.md) › [sdl.dialogs](index.md) › FileDialogOptions

# FileDialogOptions

`sdl.dialogs` 包中的 public struct

发起文件对话框时的选项：类型过滤器、初始目录与是否允许多选。全部字段带默认值，可按需设置。

## 声明

```cangjie
public struct FileDialogOptions
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, UiEvent, WindowSpec}
import sdl.dialogs.{FileDialogFilter, FileDialogOptions, FileDialogResult, FileDialogs}

main(): Unit {
    try (window = SdlWindow(WindowSpec("导入图片", 640, 480))) {
        let options = FileDialogOptions(
            filters: [FileDialogFilter("图像文件", "png;bmp")],
            defaultLocation: Some("C:/Users"),
            allowMany: true
        )
        let request = FileDialogs.openFile(options: options, window: Some(window))
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
            case FileDialogResult.FileDialogSelected(paths, _) => println("选中 ${paths.size} 张图片")
            case FileDialogResult.FileDialogCanceled => println("已取消")
            case FileDialogResult.FileDialogFailed(message) => println("打开失败：${message}")
            case FileDialogResult.FileDialogPending => println("窗口已关闭，对话框尚未完成")
        }
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(filters!: Array<FileDialogFilter>, defaultLocation!: ?String, allowMany!: Bool)`](#init) | 以命名参数构造，全部可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`filters`](#filters) | 类型过滤器列表；默认为空（不过滤）。 |
| [`defaultLocation`](#defaultlocation) | 对话框的初始目录；默认 `None`（系统默认）。 |
| [`allowMany`](#allowmany) | 是否允许多选；默认 `false`。 |

## 构造函数

### init

以命名参数构造，全部可选。

```cangjie
public init(filters!: Array<FileDialogFilter> = [], defaultLocation!: ?String = None, allowMany!: Bool = false)
```

**参数**

- `filters!`: `Array<FileDialogFilter>` — 类型过滤器；默认空数组。
- `defaultLocation!`: `?String` — 初始目录路径；默认 `None`。
- `allowMany!`: `Bool` — 允许多选；默认 `false`。

## 字段

### filters

类型过滤器列表；默认为空（不过滤）。

```cangjie
public var filters: Array<FileDialogFilter>
```

### defaultLocation

对话框的初始目录；默认 `None`（系统默认）。

```cangjie
public var defaultLocation: ?String
```

### allowMany

是否允许多选；默认 `false`。文件夹选择对话框同样生效。

```cangjie
public var allowMany: Bool
```

## 另请参阅

- [FileDialogs](FileDialogs.md) — 消费本选项发起对话框。
