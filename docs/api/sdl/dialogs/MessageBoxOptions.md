[sdl](../../index.md) › [sdl.dialogs](index.md) › MessageBoxOptions

# MessageBoxOptions

`sdl.dialogs` 包中的 public struct

自定义消息框的完整描述：标题、正文、级别、按钮列表、按钮方向与可选配色。构造后字段可直接赋值调整；默认带一个绑定回车与 Esc 的"OK"按钮。

## 声明

```cangjie
public struct MessageBoxOptions
```

## 示例

```cangjie verify
package docexample

import sdl.dialogs.{MessageBoxButton, MessageBoxKind, MessageBoxOptions, showMessageBox}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时弹出双按钮警告框并打印所选编号。
    var options = MessageBoxOptions("放弃修改", "未保存的修改将丢失。")
    options.kind = MessageBoxKind.Warning
    options.buttons = [
        MessageBoxButton("放弃", id: 1),
        MessageBoxButton("返回", id: 0, returnKeyDefault: true, escapeKeyDefault: true)
    ]
    let chosen = showMessageBox(options)
    println("用户选择 ${chosen}")
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(title: String, message: String)`](#init) | 由标题与正文构造；其余字段取默认值（信息级、"OK"按钮、平台按钮方向、无配色）。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`title`](#title) | 对话框标题。 |
| [`message`](#message) | 正文文本。 |
| [`kind`](#kind) | 严重级别；默认信息级。 |
| [`buttons`](#buttons) | 按钮列表；默认一个绑定回车与 Esc 的"OK"（id 0）。 |
| [`buttonOrder`](#buttonorder) | 按钮排列方向；默认平台默认。 |
| [`colorScheme`](#colorscheme) | 可选配色；默认 `None`（系统外观）。 |

## 构造函数

### init

由标题与正文构造；其余字段取默认值（信息级、"OK"按钮、平台按钮方向、无配色）。

```cangjie
public init(title: String, message: String)
```

**参数**

- `title`: `String` — 对话框标题。
- `message`: `String` — 正文文本。

## 字段

### title

对话框标题。

```cangjie
public var title: String
```

### message

正文文本。

```cangjie
public var message: String
```

### kind

严重级别；默认信息级。

```cangjie
public var kind: MessageBoxKind
```

### buttons

按钮列表；默认一个绑定回车与 Esc 的"OK"（id 0）。[`showMessageBox`](functions.md#showmessagebox) 要求列表非空。

```cangjie
public var buttons: Array<MessageBoxButton>
```

### buttonOrder

按钮排列方向；默认平台默认。

```cangjie
public var buttonOrder: MessageBoxButtonOrder
```

### colorScheme

可选配色；默认 `None`（系统外观）。

```cangjie
public var colorScheme: ?MessageBoxColorScheme
```

## 另请参阅

- [showMessageBox](functions.md#showmessagebox) — 消费本选项弹出消息框。
- [MessageBoxButton](MessageBoxButton.md) · [MessageBoxButtonOrder](MessageBoxButtonOrder.md) · [MessageBoxColorScheme](MessageBoxColorScheme.md)
