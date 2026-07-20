[sdl](../index.md) › [sdl](index.md) › Color

# Color

`sdl` 包中的 public struct

8 位通道的 RGBA 颜色。`rgb` / `rgba` 工厂接受整数，并把各通道限制在 0–255；[`lerp`](#lerp) 在两种颜色之间线性插值，适合生成动画过渡色。

## 声明

```cangjie
public struct Color
```

## 示例

```cangjie verify
package docexample

import sdl.Color

main(): Unit {
    let night = Color.rgb(30, 30, 46)
    let accent = Color.rgba(64, 128, 255, 200)
    let mid = night.lerp(accent, 0.5)
    println("${mid.r} ${mid.g} ${mid.b} ${mid.a}")
    // 输出: 47 79 150 227
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以不透明 alpha（255）构造颜色；四参数重载逐通道构造颜色。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`r`](#r) | 红色通道，0–255。 |
| [`g`](#g) | 绿色通道，0–255。 |
| [`b`](#b) | 蓝色通道，0–255。 |
| [`a`](#a) | 不透明度通道，0 全透明，255 不透明。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static rgb(r: Int64, g: Int64, b: Int64)`](#rgb) | 由整数通道构造不透明颜色，各通道限制在 0–255。 |
| [`static rgba(r: Int64, g: Int64, b: Int64, a: Int64)`](#rgba) | 由整数通道构造带 alpha 的颜色，各通道限制在 0–255。 |
| [`withAlpha(alpha: Int64)`](#withalpha) | 返回替换了不透明度的副本。 |
| [`lerp(other: Color, t: Float32)`](#lerp) | 向另一颜色线性插值，`t` 限制在 `[0, 1]`。 |

## 构造函数

### init

以不透明 alpha（255）构造颜色；四参数重载逐通道构造颜色。

```cangjie
public init(r: UInt8, g: UInt8, b: UInt8)
```

```cangjie
public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8)
```

**参数**

- `r`、`g`、`b`: `UInt8` — 红、绿、蓝通道值。
- `a`: `UInt8` — 不透明度；三参数重载固定为 255。

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

### a

不透明度通道，0 全透明，255 不透明。

```cangjie
public let a: UInt8
```

## 方法

### rgb

由整数通道构造不透明颜色，各通道限制在 0–255。

```cangjie
public static func rgb(r: Int64, g: Int64, b: Int64): Color
```

**参数**

- `r`、`g`、`b`: `Int64` — 通道值；小于 0 按 0、大于 255 按 255 处理。

**返回值** `Color` — alpha 为 255 的颜色。

### rgba

由整数通道构造带 alpha 的颜色，各通道限制在 0–255。

```cangjie
public static func rgba(r: Int64, g: Int64, b: Int64, a: Int64): Color
```

**参数**

- `r`、`g`、`b`、`a`: `Int64` — 通道值；小于 0 按 0、大于 255 按 255 处理。

**返回值** `Color` — 构造出的颜色。

### withAlpha

返回替换了不透明度的副本。

```cangjie
public func withAlpha(alpha: Int64): Color
```

**参数**

- `alpha`: `Int64` — 新的不透明度；小于 0 按 0、大于 255 按 255 处理。

**返回值** `Color` — RGB 不变、alpha 替换后的副本。

### lerp

向另一颜色线性插值，`t` 限制在 `[0, 1]`。四个通道各自独立混合。

```cangjie
public func lerp(other: Color, t: Float32): Color
```

**参数**

- `other`: `Color` — 插值目标。
- `t`: `Float32` — 插值系数；小于 0 按 0、大于 1 按 1 处理，0 返回自身，1 返回 `other`。

**返回值** `Color` — 混合后的颜色。

## 另请参阅

- [Pen](Pen.md) — 将颜色与描边宽度捆绑为一支笔。
- [Renderer](Renderer.md) — 使用颜色的绘制入口。
