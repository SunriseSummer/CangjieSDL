[sdl](../../index.md) › [sdl.displays](index.md) › DisplayOrientations

# DisplayOrientations

`sdl.displays` 包中的 public struct

显示器的自然朝向与当前朝向的组合。

## 声明

```cangjie
public struct DisplayOrientations
```

## 示例

```cangjie verify
package docexample

import sdl.displays.{DisplayOrientation, DisplayOrientations, primaryDisplayInfo}

main(): Unit {
    // 运行时判断显示器是否被旋转过。
    let orientations: DisplayOrientations = primaryDisplayInfo().orientations
    let rotated = match ((orientations.natural, orientations.current)) {
        case (DisplayOrientation.Landscape, DisplayOrientation.Landscape) => false
        case (DisplayOrientation.Portrait, DisplayOrientation.Portrait) => false
        case _ => true
    }
    println("被旋转：${rotated}")
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(natural: DisplayOrientation, current: DisplayOrientation)`](#init) | 由自然朝向与当前朝向构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`natural`](#natural) | 硬件的自然朝向。 |
| [`current`](#current) | 当前生效的朝向。 |

## 构造函数

### init

由自然朝向与当前朝向构造。

```cangjie
public init(natural: DisplayOrientation, current: DisplayOrientation)
```

**参数**

- `natural`: `DisplayOrientation` — 硬件的自然朝向。
- `current`: `DisplayOrientation` — 当前生效的朝向。

## 字段

### natural

硬件的自然朝向。

```cangjie
public let natural: DisplayOrientation
```

### current

当前生效的朝向。

```cangjie
public let current: DisplayOrientation
```

## 另请参阅

- [DisplayOrientation](DisplayOrientation.md) — 朝向枚举。
