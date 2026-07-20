[sdl](../../index.md) › [sdl.displays](index.md) › DisplayMode

# DisplayMode

`sdl.displays` 包中的 public struct

显示器可用的分辨率、像素密度与刷新率组合。显示查询会把 SDL 返回的非正像素密度规范化为 1.0；公开构造器原样保存调用者传入的值。

## 声明

```cangjie
public struct DisplayMode
```

## 示例

```cangjie verify
package docexample

import sdl.displays.{DisplayMode, fullscreenDisplayModes, primaryDisplayInfo}

main(): Unit {
    // 运行时枚举主显示器的全屏显示模式并打印第一种。
    let primary = primaryDisplayInfo()
    let modes = fullscreenDisplayModes(primary.id)
    if (modes.size > 0) {
        let best: DisplayMode = modes[0]
        println("${best.width}x${best.height} @ ${Int64(best.refreshRate)}Hz")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(width: Int32, height: Int32, pixelDensity: Float32, refreshRate: Float32)`](#init) | 逐项构造显示模式。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`width`](#width) | 宽度，像素。 |
| [`height`](#height) | 高度，像素。 |
| [`pixelDensity`](#pixeldensity) | 像素密度（物理像素/逻辑单位）；显示查询会把 SDL 的非正值规范化为 1.0，公开构造器原样保存传入值。 |
| [`refreshRate`](#refreshrate) | 刷新率，Hz；0 表示未指定。 |

## 构造函数

### init

逐项构造显示模式。

```cangjie
public init(width: Int32, height: Int32, pixelDensity: Float32, refreshRate: Float32)
```

**参数**

- `width`、`height`: `Int32` — 分辨率，像素。
- `pixelDensity`: `Float32` — 像素密度；公开构造器原样保存，不要求为正。
- `refreshRate`: `Float32` — 刷新率，Hz。

## 字段

### width

宽度，像素。

```cangjie
public let width: Int32
```

### height

高度，像素。

```cangjie
public let height: Int32
```

### pixelDensity

像素密度（物理像素/逻辑单位）；显示查询会把 SDL 的非正值规范化为 1.0，公开构造器原样保存传入值。

```cangjie
public let pixelDensity: Float32
```

### refreshRate

刷新率，Hz；0 表示未指定。

```cangjie
public let refreshRate: Float32
```

## 另请参阅

- [fullscreenDisplayModes](functions.md#fullscreendisplaymodes) · [closestFullscreenDisplayMode](functions.md#closestfullscreendisplaymode)
