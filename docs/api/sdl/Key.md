[API 参考](../index.md) › [sdl](index.md) › Key

# Key

解码后的键盘按键。字母和数字优先采用当前键盘布局对应的逻辑键值；导航键和功能键按物理扫描码识别。可打印文字由 [`UiEvent.TextInput`](UiEvent.md) 提供，不应从 `Key` 自行转换。

```cangjie
public enum Key {
    | Escape
    | Backspace
    | Enter
    | Tab
    | Delete
    | Space
    | Home
    | End
    | Left
    | Right
    | Up
    | Down
    | Letter(UInt8)
    | Digit(UInt8)
    | RawScancode(Int32)
}
```

## 示例

```cangjie verify role=complete
package docexample

import sdl.Key

main(): Unit {
    let pressed = Key.Letter(UInt8(65))
    match (pressed) {
        case Key.Escape => println("退出")
        case Key.Letter(code) => println("字母 ${code}")
        case _ => println("其他按键")
    }
}
```

## 枚举值

| 值 | 含义 |
|---|---|
| `Escape`、`Backspace`、`Enter`、`Tab`、`Delete`、`Space` | 常用控制键。 |
| `Home`、`End`、`Left`、`Right`、`Up`、`Down` | 导航键。 |
| `Letter(UInt8)` | 字母键，携带大写 ASCII 码 65–90；随当前键盘布局变化。 |
| `Digit(UInt8)` | 数字键，携带 ASCII 码 48–57。 |
| `RawScancode(Int32)` | 未映射按键，保留 SDL 原始扫描码。 |

需要同时保存物理扫描码、逻辑键值和修饰键时，使用 [`UiEventRecord`](UiEventRecord.md) 的 [`UiEventMetadata`](UiEventMetadata.md)。
