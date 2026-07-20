[sdl](../index.md) › [sdl](index.md) › WindowFlash

# WindowFlash

`sdl` 包中的 public enum

任务栏/窗口闪烁请求的方式，传给 [`SdlWindow.flash`](SdlWindow.md#flash)。

## 声明

```cangjie
public enum WindowFlash
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowFlash, WindowSpec}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时让任务栏图标持续闪烁直到窗口获得焦点。
    try (window = SdlWindow(WindowSpec("提醒", 640, 480))) {
        window.flash(operation: WindowFlash.UntilFocused)
    }
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Cancel` | 取消正在进行的闪烁。 |
| `Briefly` | 短促闪烁一次。 |
| `UntilFocused` | 持续闪烁直到窗口获得焦点。 |

## 另请参阅

- [SdlWindow.flash](SdlWindow.md#flash) — 发起闪烁。
