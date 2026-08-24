[sdl](../index.md) › [sdl](index.md) › Key

# Key

`sdl` 包中的 public enum

解码后的键盘按键。字母与数字优先来自 SDL 的布局相关逻辑 keycode，导航/功能键按物理 scancode 映射；`Letter` 携带大写 ASCII 码（A–Z），`Digit` 携带 ASCII 数字码（'0'–'9'）。未映射的按键以 `RawScancode` 携带原始扫描码到达。可打印文本仍不经由此类型——它经输入法合成后以 [`UiEvent.TextInput`](UiEvent.md#textinput) 到达；需要同时区分物理键和逻辑键时读取 [`UiEventMetadata`](UiEventMetadata.md)。

## 声明

```cangjie
public enum Key
```

## 示例

```cangjie verify
package docexample

import sdl.Key

main(): Unit {
    let pressed = Key.Letter(65)
    match (pressed) {
        case Key.Escape => println("退出")
        case Key.Letter(code) => println("字母 ${code}")
        case _ => println("其他按键")
    }
    // 输出: 字母 65
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`Escape`](#escape) | Esc 键。 |
| [`Backspace`](#backspace) | 退格键。 |
| [`Enter`](#enter) | 回车键。 |
| [`Tab`](#tab) | Tab 键。 |
| [`Delete`](#delete) | Delete 键。 |
| [`Space`](#space) | 空格键。 |
| [`Home`](#home) | Home 键。 |
| [`End`](#end) | End 键。 |
| [`Left`](#left) | 左方向键。 |
| [`Right`](#right) | 右方向键。 |
| [`Up`](#up) | 上方向键。 |
| [`Down`](#down) | 下方向键。 |
| [`Letter(UInt8)`](#letter) | 字母键，携带大写 ASCII 码 65–90。 |
| [`Digit(UInt8)`](#digit) | 数字键，携带 ASCII 数字码 48–57（主键盘区 '0'–'9'）。 |
| [`RawScancode(Int32)`](#rawscancode) | 未映射按键，携带原始 SDL 扫描码。 |

## 枚举值

### Escape

Esc 键。

```cangjie
Escape
```

### Backspace

退格键。

```cangjie
Backspace
```

### Enter

回车键。对应 SDL 的 Return 扫描码。

```cangjie
Enter
```

### Tab

Tab 键。

```cangjie
Tab
```

### Delete

Delete 键。

```cangjie
Delete
```

### Space

空格键。

```cangjie
Space
```

### Home

Home 键。

```cangjie
Home
```

### End

End 键。

```cangjie
End
```

### Left

左方向键。

```cangjie
Left
```

### Right

右方向键。

```cangjie
Right
```

### Up

上方向键。

```cangjie
Up
```

### Down

下方向键。

```cangjie
Down
```

### Letter

字母键，携带大写 ASCII 码 65–90。正常键盘事件优先从逻辑 keycode 得到，因此会跟随当前布局；用事件元数据的 `physicalScancode` 实现与布局无关的物理键位操作。

```cangjie
Letter(UInt8)
```

### Digit

数字键，携带 ASCII 数字码 48–57。正常键盘事件优先采用逻辑 keycode；无法映射时再按物理 scancode 解码。

```cangjie
Digit(UInt8)
```

### RawScancode

未映射按键，携带原始 SDL 扫描码。

```cangjie
RawScancode(Int32)
```

## 另请参阅

- [UiEvent](UiEvent.md) — `KeyDown` / `KeyUp` 事件携带本类型。
- [UiEventMetadata](UiEventMetadata.md) — 同一事件的物理 scancode、逻辑 keycode 和修饰键快照。
- [sdl.input 的 KeyModifiers](input/KeyModifiers.md) — 查询调用时刻的全局修饰键状态。
