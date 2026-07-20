[sdl](../../index.md) › [sdl.dialogs](index.md) › MessageBoxKind

# MessageBoxKind

`sdl.dialogs` 包中的 public enum

消息框的严重级别，决定原生对话框的图标样式。

## 声明

```cangjie
public enum MessageBoxKind
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowSpec}
import sdl.dialogs.{MessageBoxKind, showSimpleMessageBox}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时弹出带警告图标的原生消息框。
    try (window = SdlWindow(WindowSpec("消息框", 320, 240))) {
        showSimpleMessageBox(
            "磁盘空间不足",
            "剩余空间小于 1 GB。",
            kind: MessageBoxKind.Warning,
            window: Some(window)
        )
    }
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Error` | 错误级别。 |
| `Warning` | 警告级别。 |
| `Information` | 信息级别（[`showSimpleMessageBox`](functions.md#showsimplemessagebox) 的默认值）。 |

## 另请参阅

- [showSimpleMessageBox](functions.md#showsimplemessagebox) · [MessageBoxOptions](MessageBoxOptions.md)
