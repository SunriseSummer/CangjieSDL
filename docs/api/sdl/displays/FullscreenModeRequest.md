[sdl](../../index.md) › [sdl.displays](index.md) › FullscreenModeRequest

# FullscreenModeRequest

`sdl.displays` 包中的 public struct

查找最接近的全屏显示模式时的期望参数：目标分辨率、刷新率与是否考虑高像素密度模式。

## 声明

```cangjie
public struct FullscreenModeRequest
```

## 示例

```cangjie verify
package docexample

import sdl.displays.{closestFullscreenDisplayMode, FullscreenModeRequest, primaryDisplayInfo}

main(): Unit {
    // 运行时在主显示器上查找最接近 1920x1080@60 的全屏显示模式。
    let primary = primaryDisplayInfo()
    let request = FullscreenModeRequest(1920, 1080, refreshRate: 60.0)
    match (closestFullscreenDisplayMode(primary.id, request)) {
        case Some(mode) => println("匹配 ${mode.width}x${mode.height}")
        case None => println("没有可用模式")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(width: Int32, height: Int32, refreshRate!: Float32, includeHighDensityModes!: Bool)`](#init) | 由目标分辨率构造；刷新率与高密度开关可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`width`](#width) | 期望宽度，像素。 |
| [`height`](#height) | 期望高度，像素。 |
| [`refreshRate`](#refreshrate) | 期望刷新率，Hz；0 表示接受任意刷新率。 |
| [`includeHighDensityModes`](#includehighdensitymodes) | 是否把高像素密度模式纳入匹配；默认 `true`。 |

## 构造函数

### init

由目标分辨率构造；刷新率与高密度开关可选。

```cangjie
public init(width: Int32, height: Int32, refreshRate!: Float32 = 0.0, includeHighDensityModes!: Bool = true)
```

**参数**

- `width`、`height`: `Int32` — 期望分辨率，像素。
- `refreshRate!`: `Float32` — 期望刷新率；默认 0.0（任意）。
- `includeHighDensityModes!`: `Bool` — 纳入高像素密度模式；默认 `true`。

## 字段

### width

期望宽度，像素。

```cangjie
public let width: Int32
```

### height

期望高度，像素。

```cangjie
public let height: Int32
```

### refreshRate

期望刷新率，Hz；0 表示接受任意刷新率。

```cangjie
public let refreshRate: Float32
```

### includeHighDensityModes

是否把高像素密度模式纳入匹配；默认 `true`。

```cangjie
public let includeHighDensityModes: Bool
```

## 另请参阅

- [closestFullscreenDisplayMode](functions.md#closestfullscreendisplaymode) — 消费本请求。
