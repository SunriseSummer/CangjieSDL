[sdl](../../index.md) › [sdl.dialogs](index.md) › MessageBoxButtonOrder

# MessageBoxButtonOrder

`sdl.dialogs` 包中的 public enum

消息框按钮的排列方向。

## 声明

```cangjie
public enum MessageBoxButtonOrder
```

## 示例

```cangjie verify
package docexample

import sdl.dialogs.{MessageBoxButton, MessageBoxButtonOrder, MessageBoxOptions, showMessageBox}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时按声明顺序从左到右排列按钮。
    var options = MessageBoxOptions("确认", "要保存修改吗?")
    options.buttons = [
        MessageBoxButton("保存", id: 1, returnKeyDefault: true),
        MessageBoxButton("不保存", id: 0, escapeKeyDefault: true)
    ]
    options.buttonOrder = MessageBoxButtonOrder.LeftToRight
    let chosen = showMessageBox(options)
    println("用户选择按钮 ${chosen}")
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `PlatformDefault` | 使用平台默认方向。 |
| `LeftToRight` | 按声明顺序从左到右。 |
| `RightToLeft` | 按声明顺序从右到左。 |

## 另请参阅

- [MessageBoxOptions](MessageBoxOptions.md) — 携带本设置。
