[sdl](../index.md) › [sdl](index.md) › Pen

# Pen

`sdl` 包中的 public struct

一次描边的描述：线条/轮廓的宽度与颜色。把两者组合成一支笔，使 [`Renderer.strokeLine`](Renderer.md#strokeline) / [`strokeRect`](Renderer.md#strokerect) / [`strokeCircle`](Renderer.md#strokecircle) 等描边方法的参数更简洁。

## 声明

```cangjie
public struct Pen
```

## 示例

```cangjie verify
package docexample

import sdl.{Color, Pen, Renderer}

main(): Unit {
    let outline = Pen(width: 2.0, color: Color.rgb(220, 220, 230))
    let r = Renderer.headless()
    r.strokeLine(24.0, 120.0, 296.0, 120.0, outline)
    println("描边宽度 ${Int64(outline.width)} 像素")
    // 输出: 描边宽度 2 像素
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(width!: Float32, color!: Color)`](#init) | 以命名参数构造一支笔。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`width`](#width) | 描边宽度，逻辑像素。 |
| [`color`](#color) | 描边颜色。 |

## 构造函数

### init

以命名参数构造一支笔。

```cangjie
public init(width!: Float32, color!: Color)
```

**参数**

- `width!`: `Float32` — 描边宽度，逻辑像素。
- `color!`: `Color` — 描边颜色。

## 字段

### width

描边宽度，逻辑像素。

```cangjie
public let width: Float32
```

### color

描边颜色。

```cangjie
public let color: Color
```

## 另请参阅

- [Color](Color.md) — RGBA 颜色。
- [Renderer](Renderer.md) — 消费 `Pen` 的描边方法。
