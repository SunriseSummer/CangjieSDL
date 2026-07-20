[sdl](../../index.md) › [sdl.displays](index.md) › DisplayModes

# DisplayModes

`sdl.displays` 包中的 public struct

显示器的桌面显示模式与当前显示模式；SDL 无法提供时对应项为 `None`。

## 声明

```cangjie
public struct DisplayModes
```

## 示例

```cangjie verify
package docexample

import sdl.displays.{DisplayModes, primaryDisplayInfo}

main(): Unit {
    // 运行时打印当前显示模式的分辨率。
    let modes: DisplayModes = primaryDisplayInfo().modes
    match (modes.current) {
        case Some(mode) => println("当前 ${mode.width}x${mode.height}")
        case None => println("当前模式不可知")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(desktop: ?DisplayMode, current: ?DisplayMode)`](#init) | 由两种模式构造，皆可为 `None`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`desktop`](#desktop) | 桌面显示模式（未全屏时的模式）；不可知时为 `None`。 |
| [`current`](#current) | 当前生效的显示模式；不可知时为 `None`。 |

## 构造函数

### init

由两种模式构造，皆可为 `None`。

```cangjie
public init(desktop: ?DisplayMode, current: ?DisplayMode)
```

**参数**

- `desktop`: `?DisplayMode` — 桌面显示模式。
- `current`: `?DisplayMode` — 当前显示模式。

## 字段

### desktop

桌面显示模式（未全屏时的模式）；不可知时为 `None`。

```cangjie
public let desktop: ?DisplayMode
```

### current

当前生效的显示模式；不可知时为 `None`。

```cangjie
public let current: ?DisplayMode
```

## 另请参阅

- [DisplayMode](DisplayMode.md) — 单个显示模式。
