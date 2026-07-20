[sdl](../../index.md) › [sdl.input](index.md) › SystemCursor

# SystemCursor

`sdl.input` 包中的 public enum

操作系统内置的光标形状，交给 [`Cursor.system`](Cursor.md#system) 创建对应的原生光标。

## 声明

```cangjie
public enum SystemCursor
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowSpec}
import sdl.input.{Cursor, SystemCursor}

main(): Unit {
    // 光标需要视频子系统，本示例仅作编译验证；运行时把指针换成文本编辑形状。
    try (window = SdlWindow(WindowSpec("光标", 320, 240))) {
        try (ibeam = Cursor.system(SystemCursor.Text)) {
            ibeam.setActive()
            window.delay(1)
        }
    }
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Default` | 默认箭头。 |
| `Text` | 文本编辑（工字梁）。 |
| `Wait` | 等待。 |
| `Crosshair` | 十字准星。 |
| `Progress` | 后台忙（箭头加转轮）。 |
| `NwseResize` | 西北—东南向缩放。 |
| `NeswResize` | 东北—西南向缩放。 |
| `EwResize` | 水平缩放。 |
| `NsResize` | 垂直缩放。 |
| `Move` | 四向移动。 |
| `NotAllowed` | 禁止。 |
| `Pointer` | 手形（链接指点）。 |
| `NwResize` | 窗口左上角缩放。 |
| `NResize` | 窗口上边缩放。 |
| `NeResize` | 窗口右上角缩放。 |
| `EResize` | 窗口右边缩放。 |
| `SeResize` | 窗口右下角缩放。 |
| `SResize` | 窗口下边缩放。 |
| `SwResize` | 窗口左下角缩放。 |
| `WResize` | 窗口左边缩放。 |

## 另请参阅

- [Cursor](Cursor.md) — 光标对象与显示控制。
