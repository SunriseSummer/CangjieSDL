[sdl](../index.md) › [sdl](index.md) › SurfaceStyle

# SurfaceStyle

`sdl` 包中的 public struct

一块圆角面板的外观描述：填充色、边框色与宽度、圆角半径、阴影色与垂直偏移。它只保存这些样式数据，方便上层 UI 把“卡片”外观作为一个整体传递；`with…` 方法返回只替换指定项的新值。

## 声明

```cangjie
public struct SurfaceStyle
```

## 示例

```cangjie verify
package docexample

import sdl.{Color, SurfaceStyle}

main(): Unit {
    let card = SurfaceStyle(
        Color.rgb(40, 42, 54),
        border: Color.rgb(68, 71, 90),
        radius: 8.0,
        borderWidth: 1.0
    )
    let hover = card.withFill(Color.rgb(50, 52, 64))
    println("${Int64(card.radius)} ${Int64(hover.borderWidth)}")
    // 输出: 8 1
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(fill: Color, ...)`](#init) | 由填充色构造；边框、圆角与阴影经命名参数可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`fill`](#fill) | 填充颜色。 |
| [`border`](#border) | 边框颜色；默认全透明。 |
| [`radius`](#radius) | 圆角半径，逻辑像素；默认 0。 |
| [`borderWidth`](#borderwidth) | 边框宽度，逻辑像素；默认 0（不画边框）。 |
| [`shadow`](#shadow) | 阴影颜色；默认全透明。 |
| [`shadowOffsetY`](#shadowoffsety) | 阴影的垂直偏移，逻辑像素；默认 0。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`withFill(fill: Color)`](#withfill) | 返回替换填充色的副本。 |
| [`withBorder(border: Color)`](#withborder) | 返回替换边框色的副本。 |

## 构造函数

### init

由填充色构造；边框、圆角与阴影经命名参数可选。

```cangjie
public init(fill: Color, border!: Color = Color.rgba(0, 0, 0, 0), radius!: Float32 = 0.0, borderWidth!: Float32 = 0.0, shadow!: Color = Color.rgba(0, 0, 0, 0), shadowOffsetY!: Float32 = 0.0)
```

**参数**

- `fill`: `Color` — 填充颜色。
- `border!`: `Color` — 边框颜色；默认值为 `Color.rgba(0, 0, 0, 0)`，即全透明。
- `radius!`: `Float32` — 圆角半径；默认值为 `0.0`。
- `borderWidth!`: `Float32` — 边框宽度；默认值为 `0.0`，不绘制边框。
- `shadow!`: `Color` — 阴影颜色；默认值为 `Color.rgba(0, 0, 0, 0)`，即全透明。
- `shadowOffsetY!`: `Float32` — 阴影垂直偏移；默认值为 `0.0`。

## 字段

### fill

填充颜色。

```cangjie
public let fill: Color
```

### border

边框颜色；默认全透明。

```cangjie
public let border: Color
```

### radius

圆角半径，逻辑像素；默认 0。

```cangjie
public let radius: Float32
```

### borderWidth

边框宽度，逻辑像素；默认 0（不画边框）。

```cangjie
public let borderWidth: Float32
```

### shadow

阴影颜色；默认全透明。

```cangjie
public let shadow: Color
```

### shadowOffsetY

阴影的垂直偏移，逻辑像素；默认 0。

```cangjie
public let shadowOffsetY: Float32
```

## 方法

### withFill

返回替换填充色的副本。

```cangjie
public func withFill(fill: Color): SurfaceStyle
```

**参数**

- `fill`: `Color` — 新的填充颜色。

**返回值** `SurfaceStyle` — 其余字段不变的副本。

### withBorder

返回替换边框色的副本。

```cangjie
public func withBorder(border: Color): SurfaceStyle
```

**参数**

- `border`: `Color` — 新的边框颜色。

**返回值** `SurfaceStyle` — 其余字段不变的副本。

## 另请参阅

- [Renderer.fillRoundedRect](Renderer.md#fillroundedrect) · [Renderer.strokeRoundedRect](Renderer.md#strokeroundedrect) — 绘制这类面板的方法。
