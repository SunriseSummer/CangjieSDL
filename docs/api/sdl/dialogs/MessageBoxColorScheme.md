[sdl](../../index.md) › [sdl.dialogs](index.md) › MessageBoxColorScheme

# MessageBoxColorScheme

`sdl.dialogs` 包中的 public struct

消息框的整套配色：背景、文字、按钮边框、按钮底色与选中按钮。是否生效取决于平台原生消息框的支持程度。

## 声明

```cangjie
public struct MessageBoxColorScheme
```

## 示例

```cangjie verify
package docexample

import sdl.dialogs.{MessageBoxColor, MessageBoxColorScheme, MessageBoxOptions, showMessageBox}

main(): Unit {
    let dark = MessageBoxColorScheme(
        MessageBoxColor(30, 30, 46),
        MessageBoxColor(220, 220, 230),
        MessageBoxColor(68, 71, 90),
        MessageBoxColor(40, 42, 54),
        MessageBoxColor(64, 128, 255)
    )
    var options = MessageBoxOptions("自定义配色", "平台支持时，消息框会采用深色配色。")
    options.colorScheme = Some(dark)
    let chosen = showMessageBox(options)
    println("用户选择按钮 ${chosen}")
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(background: MessageBoxColor, text: MessageBoxColor, buttonBorder: MessageBoxColor, buttonBackground: MessageBoxColor, buttonSelected: MessageBoxColor)`](#init) | 按五个部位依次给出颜色。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`background`](#background) | 对话框背景色。 |
| [`text`](#text) | 正文文字颜色。 |
| [`buttonBorder`](#buttonborder) | 按钮边框颜色。 |
| [`buttonBackground`](#buttonbackground) | 按钮底色。 |
| [`buttonSelected`](#buttonselected) | 选中按钮的颜色。 |

## 构造函数

### init

按五个部位依次给出颜色。

```cangjie
public init(background: MessageBoxColor, text: MessageBoxColor, buttonBorder: MessageBoxColor, buttonBackground: MessageBoxColor, buttonSelected: MessageBoxColor)
```

**参数**

- `background`: `MessageBoxColor` — 对话框背景色。
- `text`: `MessageBoxColor` — 正文文字颜色。
- `buttonBorder`: `MessageBoxColor` — 按钮边框颜色。
- `buttonBackground`: `MessageBoxColor` — 按钮底色。
- `buttonSelected`: `MessageBoxColor` — 选中按钮的颜色。

## 字段

### background

对话框背景色。

```cangjie
public let background: MessageBoxColor
```

### text

正文文字颜色。

```cangjie
public let text: MessageBoxColor
```

### buttonBorder

按钮边框颜色。

```cangjie
public let buttonBorder: MessageBoxColor
```

### buttonBackground

按钮底色。

```cangjie
public let buttonBackground: MessageBoxColor
```

### buttonSelected

选中按钮的颜色。

```cangjie
public let buttonSelected: MessageBoxColor
```

## 另请参阅

- [MessageBoxOptions](MessageBoxOptions.md) — 经 `colorScheme` 字段挂载配色。
