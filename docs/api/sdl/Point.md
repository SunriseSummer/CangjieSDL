[sdl](../index.md) › [sdl](index.md) › Point

# Point

`sdl` 包中的 public struct

逻辑像素坐标系中的一个位置——布局、事件与绘制共用的坐标空间。

## 声明

```cangjie
public struct Point
```

## 示例

```cangjie verify
package docexample

import sdl.{Point, Rect}

main(): Unit {
    let anchor = Point(160.0, 120.0)
    let frame = Rect(0.0, 0.0, 320.0, 240.0)
    println(frame.contains(anchor.x, anchor.y))
    // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(x: Float32, y: Float32)`](#init) | 由横纵坐标构造点。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`x`](#x) | 横坐标，逻辑像素。 |
| [`y`](#y) | 纵坐标，逻辑像素。 |

## 构造函数

### init

由横纵坐标构造点。

```cangjie
public init(x: Float32, y: Float32)
```

**参数**

- `x`、`y`: `Float32` — 逻辑像素坐标。

## 字段

### x

横坐标，逻辑像素。

```cangjie
public let x: Float32
```

### y

纵坐标，逻辑像素。

```cangjie
public let y: Float32
```

## 另请参阅

- [Rect](Rect.md) — 由原点与尺寸构成的矩形。
- [Renderer.fillConvexPolygon](Renderer.md#fillconvexpolygon) — 以顶点列表填充多边形。
