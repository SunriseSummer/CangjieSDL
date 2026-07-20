[sdl](../../index.md) › [sdl.input](index.md) › Keyboard

# Keyboard

`sdl.input` 包中的 public class

键盘的轮询式查询入口，当前提供修饰键状态。事件式的按键输入经 [`UiEvent.KeyDown`](../UiEvent.md#keydown) / [`KeyUp`](../UiEvent.md#keyup) 到达。

## 声明

```cangjie
public class Keyboard
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowSpec}
import sdl.input.Keyboard

main(): Unit {
    // 需要视频子系统，本示例仅作编译验证；
    // 运行时在事件循环里判断 Ctrl/Cmd 是否按住。
    try (window = SdlWindow(WindowSpec("快捷键", 320, 240))) {
        let mods = Keyboard.modifiers()
        if (mods.command) {
            println("命令键按住")
        }
        window.delay(1)
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `Keyboard` 对象；键盘状态由静态方法查询。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static modifiers()`](#modifiers) | 返回当前修饰键状态快照（SDL_GetModState 的展开）。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `Keyboard` 对象；键盘状态由静态方法查询。

```cangjie
public init()
```

## 方法

### modifiers

返回当前修饰键状态快照（SDL_GetModState 的展开）。

```cangjie
public static func modifiers(): KeyModifiers
```

**返回值** `KeyModifiers` — 修饰键状态。

## 另请参阅

- [KeyModifiers](KeyModifiers.md) — 返回类型。
