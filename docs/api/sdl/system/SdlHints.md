[sdl](../../index.md) › [sdl.system](index.md) › SdlHints

# SdlHints

`sdl.system` 包中的 public class

SDL hint 的读写入口。hint 是进程内的运行时配置开关；多数须在受影响的子系统初始化前设置。`set` 与 `setBool` 在 SDL 拒绝写入时把失败状态转换为 `CuiException`；查询和重置方法按返回值表示结果。

## 声明

```cangjie
public class SdlHints
```

## 示例

```cangjie verify
package docexample

import sdl.system.{SdlHint, SdlHints}

main(): Unit {
    SdlHints.setBool(SdlHint.VideoAllowScreensaver, true)
    println(SdlHints.getBool(SdlHint.VideoAllowScreensaver, false))
    let changed = SdlHints.reset(SdlHint.VideoAllowScreensaver)
    println("重置生效：${changed}")
    // 输出:
    // true
    // 重置生效：true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `SdlHints` 对象；hint 操作由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static set(...)`](#set) | 以普通优先级写入 hint；重载接受完整的 `SdlHintSetting`（含优先级）。 |
| [`static setBool(hint: SdlHint, value: Bool, priority!: HintPriority)`](#setbool) | 以布尔值写入 hint（内部转为 `"1"`/`"0"`）。 |
| [`static apply(settings: Array<SdlHintSetting>)`](#apply) | 按序批量应用多条设置；任一条失败即中断并抛出。 |
| [`static get(hint: SdlHint)`](#get) | 读取 hint 当前值；未设置时为 `None`。 |
| [`static getBool(hint: SdlHint, defaultValue: Bool)`](#getbool) | 按布尔读取 hint；未设置时返回默认值。 |
| [`static reset(hint: SdlHint)`](#reset) | 把 hint 重置为默认，返回是否发生变化。 |
| [`static resetAll()`](#resetall) | 重置全部 hint。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `SdlHints` 对象；hint 操作由静态方法提供。

```cangjie
public init()
```

## 方法

### set

以普通优先级写入 hint；重载接受完整的 [`SdlHintSetting`](SdlHintSetting.md)（含优先级）。

```cangjie
public static func set(hint: SdlHint, value: String): Unit
```

```cangjie
public static func set(setting: SdlHintSetting): Unit
```

**参数**

- `hint`: `SdlHint` — 目标 hint；自定义 hint 名须非空。
- `value`: `String` — 写入值。
- `setting`: `SdlHintSetting` — hint、值与优先级的组合。

**异常**

- `CuiException` — hint 名为空，或 SDL 拒绝该 hint 时。

### setBool

以布尔值写入 hint（内部转为 `"1"`/`"0"`）。

```cangjie
public static func setBool(hint: SdlHint, value: Bool, priority!: HintPriority = HintPriority.Normal): Unit
```

**参数**

- `hint`: `SdlHint` — 目标 hint。
- `value`: `Bool` — 布尔值。
- `priority!`: `HintPriority` — 优先级；默认值为 `HintPriority.Normal`，即普通优先级。

**异常**

- `CuiException` — hint 名为空，或 SDL 拒绝该 hint 时。

### apply

按序批量应用多条设置；任一条失败即中断并抛出。

```cangjie
public static func apply(settings: Array<SdlHintSetting>): Unit
```

**参数**

- `settings`: `Array<SdlHintSetting>` — 设置列表。

**异常**

- `CuiException` — 任一条 hint 被拒绝时。

### get

读取 hint 当前值；未设置时为 `None`。

```cangjie
public static func get(hint: SdlHint): ?String
```

**参数**

- `hint`: `SdlHint` — 目标 hint；自定义 hint 名须非空。

**返回值** `?String` — 当前值，或 `None`。

**异常**

- `CuiException` — hint 名为空时。

### getBool

按布尔读取 hint；未设置时返回默认值。

```cangjie
public static func getBool(hint: SdlHint, defaultValue: Bool): Bool
```

**参数**

- `hint`: `SdlHint` — 目标 hint；自定义 hint 名须非空。
- `defaultValue`: `Bool` — hint 未设置时的返回值。

**返回值** `Bool` — hint 的布尔解释。

**异常**

- `CuiException` — hint 名为空时。

### reset

把 hint 重置为默认，返回是否发生变化。

```cangjie
public static func reset(hint: SdlHint): Bool
```

**参数**

- `hint`: `SdlHint` — 目标 hint；自定义 hint 名须非空。

**返回值** `Bool` — SDL 报告重置生效时为 `true`。

**异常**

- `CuiException` — hint 名为空时。

### resetAll

重置全部 hint。

```cangjie
public static func resetAll(): Unit
```

## 另请参阅

- [SdlHint](SdlHint.md) · [SdlHintSetting](SdlHintSetting.md) · [HintPriority](HintPriority.md)
