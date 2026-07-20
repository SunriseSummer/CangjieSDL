[sdl](../../index.md) › [sdl.system](index.md) › SdlHintSetting

# SdlHintSetting

`sdl.system` 包中的 public struct

一条完整的 hint 设置：hint 名、值与优先级，供 [`SdlHints.apply`](SdlHints.md#apply) 批量应用。

## 声明

```cangjie
public struct SdlHintSetting
```

## 示例

```cangjie verify
package docexample

import sdl.system.{HintPriority, SdlHint, SdlHintSetting, SdlHints}

main(): Unit {
    SdlHints.apply(
        [
            SdlHintSetting(SdlHint.AppName, "绘图板"),
            SdlHintSetting(SdlHint.VideoAllowScreensaver, "1", priority: HintPriority.Override)
        ]
    )
    println(SdlHints.getBool(SdlHint.VideoAllowScreensaver, false))
    // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(hint: SdlHint, value: String, priority!: HintPriority)`](#init) | 由 hint 与值构造；优先级可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`hint`](#hint) | 目标 hint。 |
| [`value`](#value) | 写入的字符串值。 |
| [`priority`](#priority) | 写入优先级；默认普通级。 |

## 构造函数

### init

由 hint 与值构造；优先级可选。

```cangjie
public init(hint: SdlHint, value: String, priority!: HintPriority = HintPriority.Normal)
```

**参数**

- `hint`: `SdlHint` — 目标 hint。
- `value`: `String` — 写入值；布尔型 hint 用 `"1"`/`"0"`。
- `priority!`: `HintPriority` — 优先级；默认 `HintPriority.Normal`。

## 字段

### hint

目标 hint。

```cangjie
public let hint: SdlHint
```

### value

写入的字符串值。

```cangjie
public let value: String
```

### priority

写入优先级；默认普通级。

```cangjie
public let priority: HintPriority
```

## 另请参阅

- [SdlHints.apply](SdlHints.md#apply) — 批量应用。
