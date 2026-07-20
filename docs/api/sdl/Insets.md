[sdl](../index.md) › [sdl](index.md) › Insets

# Insets

`sdl` 包中的 public struct

逻辑像素下的四边间距——内边距、外边距、留白。[`horizontal`](#horizontal) 与 [`vertical`](#vertical) 分别求对边之和，即布局从可用尺寸中扣除的量。

## 声明

```cangjie
public struct Insets
```

## 示例

```cangjie verify
package docexample

import sdl.{Insets, Rect}

main(): Unit {
    let padding = Insets(4.0, 8.0, 4.0, 8.0)
    let inner = Rect(0.0, 0.0, 200.0, 100.0).inset(padding)
    println("${Int64(padding.horizontal())} ${Int64(padding.vertical())} ${Int64(inner.w)}")
    // 输出: 16 8 184
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 四边取同一间距；四参数重载逐边指定间距。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`top`](#top) | 上边间距，逻辑像素。 |
| [`right`](#right) | 右边间距，逻辑像素。 |
| [`bottom`](#bottom) | 下边间距，逻辑像素。 |
| [`left`](#left) | 左边间距，逻辑像素。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`horizontal()`](#horizontal) | 左右间距之和。 |
| [`vertical()`](#vertical) | 上下间距之和。 |

## 构造函数

### init

四边取同一间距；四参数重载逐边指定间距。

```cangjie
public init(all: Float32)
```

```cangjie
public init(top: Float32, right: Float32, bottom: Float32, left: Float32)
```

**参数**

- `all`: `Float32` — 同时应用到四边的间距。
- `top`、`right`、`bottom`、`left`: `Float32` — 各边间距，逻辑像素。

## 字段

### top

上边间距，逻辑像素。

```cangjie
public let top: Float32
```

### right

右边间距，逻辑像素。

```cangjie
public let right: Float32
```

### bottom

下边间距，逻辑像素。

```cangjie
public let bottom: Float32
```

### left

左边间距，逻辑像素。

```cangjie
public let left: Float32
```

## 方法

### horizontal

左右间距之和。

```cangjie
public func horizontal(): Float32
```

**返回值** `Float32` — `left + right`。

### vertical

上下间距之和。

```cangjie
public func vertical(): Float32
```

**返回值** `Float32` — `top + bottom`。

## 另请参阅

- [Rect.inset](Rect.md#inset) — 按 `Insets` 收缩矩形。
