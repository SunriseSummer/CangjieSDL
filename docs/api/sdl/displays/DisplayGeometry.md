[sdl](../../index.md) › [sdl.displays](index.md) › DisplayGeometry

# DisplayGeometry

`sdl.displays` 包中的 public struct

显示器的几何信息：完整边界、去除任务栏等系统区域后的可用边界，以及系统建议的内容缩放。

## 声明

```cangjie
public struct DisplayGeometry
```

## 示例

```cangjie verify
package docexample

import sdl.displays.{DisplayGeometry, primaryDisplayInfo}

main(): Unit {
    // 运行时打印主显示器的完整与可用尺寸。
    let geometry: DisplayGeometry = primaryDisplayInfo().geometry
    println("完整 ${Int64(geometry.bounds.w)}x${Int64(geometry.bounds.h)}")
    println("可用 ${Int64(geometry.usableBounds.w)}x${Int64(geometry.usableBounds.h)}")
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(bounds: Rect, usableBounds: Rect, contentScale: Float32)`](#init) | 逐项构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`bounds`](#bounds) | 显示器在桌面坐标系中的完整边界。 |
| [`usableBounds`](#usablebounds) | 去除任务栏/停靠栏后的可用边界。 |
| [`contentScale`](#contentscale) | 系统建议的内容缩放，恒为正（150% 缩放报告 1.5）。 |

## 构造函数

### init

逐项构造。

```cangjie
public init(bounds: Rect, usableBounds: Rect, contentScale: Float32)
```

**参数**

- `bounds`: `Rect` — 完整边界，桌面坐标。
- `usableBounds`: `Rect` — 可用边界，桌面坐标。
- `contentScale`: `Float32` — 内容缩放。

## 字段

### bounds

显示器在桌面坐标系中的完整边界。

```cangjie
public let bounds: Rect
```

### usableBounds

去除任务栏/停靠栏后的可用边界。

```cangjie
public let usableBounds: Rect
```

### contentScale

系统建议的内容缩放，恒为正（150% 缩放报告 1.5）。

```cangjie
public let contentScale: Float32
```

## 另请参阅

- [DisplayInfo](DisplayInfo.md) — 显示器信息的聚合。
