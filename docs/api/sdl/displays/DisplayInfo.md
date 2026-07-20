[sdl](../../index.md) › [sdl.displays](index.md) › DisplayInfo

# DisplayInfo

`sdl.displays` 包中的 public struct

一台显示器的聚合信息：编号、名称、几何、朝向与显示模式。由 [`primaryDisplayInfo`](functions.md#primarydisplayinfo) / [`displayInfo`](functions.md#displayinfo) / [`allDisplayInfos`](functions.md#alldisplayinfos) 返回。

## 声明

```cangjie
public struct DisplayInfo
```

## 示例

```cangjie verify
package docexample

import sdl.displays.{DisplayInfo, primaryDisplayInfo}

main(): Unit {
    // 运行时初始化视频子系统并打印主显示器概况。
    let display: DisplayInfo = primaryDisplayInfo()
    println("显示器 #${display.id} ${display.name}")
    println("缩放 ${display.geometry.contentScale}")
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(id: UInt32, name: String, geometry: DisplayGeometry, orientations: DisplayOrientations, modes: DisplayModes)`](#init) | 逐项构造聚合信息。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`id`](#id) | SDL 显示器编号；显示查询返回非零值，公开构造器不校验此字段。 |
| [`name`](#name) | 显示器名称。 |
| [`geometry`](#geometry) | 边界与内容缩放。 |
| [`orientations`](#orientations) | 自然朝向与当前朝向。 |
| [`modes`](#modes) | 桌面模式与当前模式。 |

## 构造函数

### init

逐项构造聚合信息。

```cangjie
public init(id: UInt32, name: String, geometry: DisplayGeometry, orientations: DisplayOrientations, modes: DisplayModes)
```

**参数**

- `id`: `UInt32` — SDL 显示器编号；公开构造器原样保存，显示查询返回的编号非零。
- `name`: `String` — 显示器名称。
- `geometry`: `DisplayGeometry` — 几何信息。
- `orientations`: `DisplayOrientations` — 朝向信息。
- `modes`: `DisplayModes` — 显示模式信息。

## 字段

### id

SDL 显示器编号；显示查询返回非零值，公开构造器不校验此字段。

```cangjie
public let id: UInt32
```

### name

显示器名称。

```cangjie
public let name: String
```

### geometry

边界与内容缩放。

```cangjie
public let geometry: DisplayGeometry
```

### orientations

自然朝向与当前朝向。

```cangjie
public let orientations: DisplayOrientations
```

### modes

桌面模式与当前模式。

```cangjie
public let modes: DisplayModes
```

## 另请参阅

- [DisplayGeometry](DisplayGeometry.md) · [DisplayOrientations](DisplayOrientations.md) · [DisplayModes](DisplayModes.md)
- [allDisplayInfos](functions.md#alldisplayinfos) — 枚举全部显示器。
