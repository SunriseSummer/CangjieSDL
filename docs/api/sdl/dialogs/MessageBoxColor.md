[sdl](../../index.md) › [sdl.dialogs](index.md) › MessageBoxColor

# MessageBoxColor

`sdl.dialogs` 包中的 public struct

消息框配色中的一项 RGB 颜色（无 alpha——原生消息框不支持透明）。

## 声明

```cangjie
public struct MessageBoxColor
```

## 示例

```cangjie verify
package docexample

import sdl.dialogs.MessageBoxColor

main(): Unit {
    let background = MessageBoxColor(30, 30, 46)
    println("${background.r} ${background.g} ${background.b}")
    // 输出: 30 30 46
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(r: UInt8, g: UInt8, b: UInt8)`](#init) | 逐通道构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`r`](#r) | 红色通道，0–255。 |
| [`g`](#g) | 绿色通道，0–255。 |
| [`b`](#b) | 蓝色通道，0–255。 |

## 构造函数

### init

逐通道构造。

```cangjie
public init(r: UInt8, g: UInt8, b: UInt8)
```

**参数**

- `r`、`g`、`b`: `UInt8` — 颜色通道值。

## 字段

### r

红色通道，0–255。

```cangjie
public let r: UInt8
```

### g

绿色通道，0–255。

```cangjie
public let g: UInt8
```

### b

蓝色通道，0–255。

```cangjie
public let b: UInt8
```

## 另请参阅

- [MessageBoxColorScheme](MessageBoxColorScheme.md) — 五项配色的组合。
