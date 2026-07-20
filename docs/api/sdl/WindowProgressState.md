[sdl](../index.md) › [sdl](index.md) › WindowProgressState

# WindowProgressState

`sdl` 包中的 public enum

原生任务栏进度指示的状态（Windows 任务栏按钮的进度条），经 [`SdlWindow.setProgressState`](SdlWindow.md#setprogressstate) 设置。

## 声明

```cangjie
public enum WindowProgressState
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowProgressState, WindowSpec}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时任务栏图标显示 40% 进度。
    try (window = SdlWindow(WindowSpec("下载中", 640, 480))) {
        window.setProgressState(WindowProgressState.Normal)
        window.setProgressValue(0.4)
    }
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Inactive` | 不显示进度。 |
| `Indeterminate` | 不定进度（跑马灯）。 |
| `Normal` | 正常进度，配合 [`setProgressValue`](SdlWindow.md#setprogressvalue) 的 0–1 值。 |
| `Paused` | 已暂停（黄色）。 |
| `Error` | 出错（红色）。 |

## 另请参阅

- [SdlWindow.setProgressState](SdlWindow.md#setprogressstate) · [SdlWindow.progressState](SdlWindow.md#progressstate)
