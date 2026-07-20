[sdl](../index.md) › [sdl](index.md) › Rect

# Rect

`sdl` 包中的 public struct

逻辑像素下的轴对齐矩形——原点 `x`/`y` 加宽高 `w`/`h`，用于布局框、命中测试与裁剪。[`contains`](#contains) 将四条边都视为在内（`x` 与 `right()` 均命中），所以相邻矩形都会把共享边上的点判定为内部；[`inset`](#inset) 与 [`intersection`](#intersection) 会把负的结果宽高改为 0。

## 声明

```cangjie
public struct Rect
```

## 示例

```cangjie verify
package docexample

import sdl.Rect

main(): Unit {
    let frame = Rect(0.0, 0.0, 200.0, 120.0)
    let padded = frame.inset(10.0)
    let overlap = frame.intersection(Rect(150.0, 60.0, 100.0, 100.0))
    println(padded.contains(15.0, 15.0))
    println("${Int64(overlap.w)} x ${Int64(overlap.h)}")
    // 输出:
    // true
    // 50 x 60
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(x: Float32, y: Float32, w: Float32, h: Float32)`](#init) | 由原点与宽高构造矩形。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`x`](#x) | 原点横坐标，逻辑像素。 |
| [`y`](#y) | 原点纵坐标，逻辑像素。 |
| [`w`](#w) | 宽度，逻辑像素。 |
| [`h`](#h) | 高度，逻辑像素。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static zero()`](#zero) | 返回原点与宽高皆为 0 的矩形。 |
| [`right()`](#right) | 右边缘坐标 `x + w`。 |
| [`bottom()`](#bottom) | 下边缘坐标 `y + h`。 |
| [`centerX()`](#centerx) | 水平中心坐标。 |
| [`centerY()`](#centery) | 垂直中心坐标。 |
| [`inset(...)`](#inset) | 返回按同一间距或按 `Insets` 逐边收缩的副本，宽高最小为 0。 |
| [`shift(dx: Float32, dy: Float32)`](#shift) | 返回平移后的副本。 |
| [`contains(px: Float32, py: Float32)`](#contains) | 判断点是否落在矩形内，四条边均算在内。 |
| [`intersection(other: Rect)`](#intersection) | 两矩形的交集；不相交时退化为零面积矩形。 |

## 构造函数

### init

由原点与宽高构造矩形。

```cangjie
public init(x: Float32, y: Float32, w: Float32, h: Float32)
```

**参数**

- `x`、`y`: `Float32` — 左上角原点，逻辑像素。
- `w`、`h`: `Float32` — 宽与高，逻辑像素。

## 字段

### x

原点横坐标，逻辑像素。

```cangjie
public var x: Float32
```

### y

原点纵坐标，逻辑像素。

```cangjie
public var y: Float32
```

### w

宽度，逻辑像素。

```cangjie
public var w: Float32
```

### h

高度，逻辑像素。

```cangjie
public var h: Float32
```

## 方法

### zero

返回原点与宽高皆为 0 的矩形。

```cangjie
public static func zero(): Rect
```

**返回值** `Rect` — `Rect(0.0, 0.0, 0.0, 0.0)`。

### right

右边缘坐标 `x + w`。

```cangjie
public func right(): Float32
```

**返回值** `Float32` — 右边缘的横坐标。

### bottom

下边缘坐标 `y + h`。

```cangjie
public func bottom(): Float32
```

**返回值** `Float32` — 下边缘的纵坐标。

### centerX

水平中心坐标。

```cangjie
public func centerX(): Float32
```

**返回值** `Float32` — `x + w / 2`。

### centerY

垂直中心坐标。

```cangjie
public func centerY(): Float32
```

**返回值** `Float32` — `y + h / 2`。

### inset

返回按同一间距或按 [`Insets`](Insets.md) 逐边收缩的副本，宽高最小为 0。

```cangjie
public func inset(value: Float32): Rect
```

```cangjie
public func inset(edges: Insets): Rect
```

**参数**

- `value`: `Float32` — 四边同用的收缩量。
- `edges`: `Insets` — 逐边收缩量。

**返回值** `Rect` — 收缩后的矩形；收缩量超过一半宽高时对应尺寸为 0。

### shift

返回平移后的副本。

```cangjie
public func shift(dx: Float32, dy: Float32): Rect
```

**参数**

- `dx`、`dy`: `Float32` — 水平与垂直平移量，逻辑像素。

**返回值** `Rect` — 尺寸不变、原点平移后的矩形。

### contains

判断点是否落在矩形内，四条边均算在内。

```cangjie
public func contains(px: Float32, py: Float32): Bool
```

**参数**

- `px`、`py`: `Float32` — 待判断的点，逻辑像素。

**返回值** `Bool` — 点在内部或边上时为 `true`。

### intersection

两矩形的交集；不相交时退化为零面积矩形。

```cangjie
public func intersection(other: Rect): Rect
```

**参数**

- `other`: `Rect` — 参与求交的另一矩形。

**返回值** `Rect` — 交集区域，宽高最小为 0。

## 另请参阅

- [Insets](Insets.md) — 逐边间距。
- [Renderer.pushClip](Renderer.md#pushclip) — 以矩形收窄当前裁剪。
