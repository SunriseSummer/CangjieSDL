[sdl](../index.md) › [sdl](index.md) › Size

# Size

`sdl` 包中的 public struct

逻辑像素下的宽高尺寸，用于窗口尺寸查询与布局测量的返回值。

## 声明

```cangjie
public struct Size
```

## 示例

```cangjie verify
package docexample

import sdl.Size

main(): Unit {
    let content = Size(320.0, 240.0)
    let empty = Size.zero()
    println("${Int64(content.w)} × ${Int64(content.h)}，空尺寸宽 ${Int64(empty.w)}")
    // 输出: 320 × 240，空尺寸宽 0
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(w: Float32, h: Float32)`](#init) | 由宽高构造尺寸。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`w`](#w) | 宽度，逻辑像素。 |
| [`h`](#h) | 高度，逻辑像素。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static zero()`](#zero) | 返回宽高皆为 0 的尺寸。 |

## 构造函数

### init

由宽高构造尺寸。

```cangjie
public init(w: Float32, h: Float32)
```

**参数**

- `w`、`h`: `Float32` — 宽与高，逻辑像素。

## 字段

### w

宽度，逻辑像素。

```cangjie
public let w: Float32
```

### h

高度，逻辑像素。

```cangjie
public let h: Float32
```

## 方法

### zero

返回宽高皆为 0 的尺寸。

```cangjie
public static func zero(): Size
```

**返回值** `Size` — `Size(0.0, 0.0)`。

## 另请参阅

- [SdlWindow.refreshSize](SdlWindow.md#refreshsize) — 从 SDL 重新读取窗口逻辑尺寸。
- [Texture.size](Texture.md#size) — 纹理的像素尺寸。
