[sdl](../../index.md) › [sdl.input](index.md) › KeyModifiers

# KeyModifiers

`sdl.input` 包中的 public struct

某一时刻的修饰键状态：把 SDL 修饰键掩码展开为逐项布尔字段，左右同键合并（左 Shift 或右 Shift 都算 `shift`），另有跨平台的 `command` 便捷位（Ctrl 或 GUI 键任一按下）。由 [`Keyboard.modifiers`](Keyboard.md#modifiers) 返回。

## 声明

```cangjie
public struct KeyModifiers
```

## 示例

```cangjie verify
package docexample

import sdl.input.KeyModifiers

main(): Unit {
    // 从掩码构造以演示字段；实际使用中来自 Keyboard.modifiers()。
    // 0x0001 = 左 Shift, 0x0040 = 左 Ctrl。
    let mods = KeyModifiers(0x0041)
    println("shift=${mods.shift} ctrl=${mods.ctrl} command=${mods.command}")
    // 输出: shift=true ctrl=true command=true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(mask: UInt16)`](#init) | 由 SDL 修饰键掩码展开构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`raw`](#raw) | SDL 原始修饰键掩码。 |
| [`shift`](#shift) | 任一 Shift 按下。 |
| [`ctrl`](#ctrl) | 任一 Ctrl 按下。 |
| [`alt`](#alt) | 任一 Alt 按下。 |
| [`gui`](#gui) | 任一 GUI 键（Win/Cmd）按下。 |
| [`command`](#command) | Ctrl 或 GUI 任一按下——跨平台"命令键"，快捷键判断用它即可同时覆盖 Windows/Linux 的 Ctrl 与 macOS 的 Cmd。 |
| [`capsLock`](#capslock) | 大写锁定开启。 |
| [`numLock`](#numlock) | 数字锁定开启。 |
| [`mode`](#mode) | AltGr（Mode）按下。 |
| [`scrollLock`](#scrolllock) | 滚动锁定开启。 |
| [`level5`](#level5) | Level 5 Shift 按下（部分键盘布局的额外层）。 |

## 构造函数

### init

由 SDL 修饰键掩码展开构造。

```cangjie
public init(mask: UInt16)
```

**参数**

- `mask`: `UInt16` — SDL_GetModState 返回的掩码。

## 字段

### raw

SDL 原始修饰键掩码。

```cangjie
public let raw: UInt16
```

### shift

任一 Shift 按下。

```cangjie
public let shift: Bool
```

### ctrl

任一 Ctrl 按下。

```cangjie
public let ctrl: Bool
```

### alt

任一 Alt 按下。

```cangjie
public let alt: Bool
```

### gui

任一 GUI 键（Win/Cmd）按下。

```cangjie
public let gui: Bool
```

### command

Ctrl 或 GUI 任一按下——跨平台"命令键"，快捷键判断用它即可同时覆盖 Windows/Linux 的 Ctrl 与 macOS 的 Cmd。

```cangjie
public let command: Bool
```

### capsLock

大写锁定开启。

```cangjie
public let capsLock: Bool
```

### numLock

数字锁定开启。

```cangjie
public let numLock: Bool
```

### mode

AltGr（Mode）按下。

```cangjie
public let mode: Bool
```

### scrollLock

滚动锁定开启。

```cangjie
public let scrollLock: Bool
```

### level5

Level 5 Shift 按下（部分键盘布局的额外层）。

```cangjie
public let level5: Bool
```

## 另请参阅

- [Keyboard.modifiers](Keyboard.md#modifiers) — 查询入口。
- [sdl 的 Key](../Key.md) — 物理按键事件。
