[sdl](../../index.md) › [sdl.dialogs](index.md) › FileDialogFilter

# FileDialogFilter

`sdl.dialogs` 包中的 public struct

文件对话框的一条类型过滤器：显示名加分号分隔的扩展名模式（SDL 语法，如 `"png;jpg"`，`"*"` 匹配全部）。

## 声明

```cangjie
public struct FileDialogFilter
```

## 示例

```cangjie verify
package docexample

import sdl.dialogs.FileDialogFilter

main(): Unit {
    let images = FileDialogFilter("图像文件", "png;bmp")
    let any = FileDialogFilter("全部文件", "*")
    println("${images.name}：${images.pattern}；${any.name}：${any.pattern}")
    // 输出: 图像文件：png;bmp；全部文件：*
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(name: String, pattern: String)`](#init) | 由显示名与扩展名模式构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`name`](#name) | 过滤器在对话框中的显示名。 |
| [`pattern`](#pattern) | 分号分隔的扩展名模式；`*` 匹配全部。 |

## 构造函数

### init

由显示名与扩展名模式构造。

```cangjie
public init(name: String, pattern: String)
```

**参数**

- `name`: `String` — 显示名，如"图像文件"。
- `pattern`: `String` — 扩展名模式，分号分隔且不含点，如 `"png;jpg"`；`"*"` 匹配全部。

## 字段

### name

过滤器在对话框中的显示名。

```cangjie
public let name: String
```

### pattern

分号分隔的扩展名模式；`*` 匹配全部。

```cangjie
public let pattern: String
```

## 另请参阅

- [FileDialogOptions](FileDialogOptions.md) — 携带过滤器列表。
