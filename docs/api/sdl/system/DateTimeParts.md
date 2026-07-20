[sdl](../../index.md) › [sdl.system](index.md) › DateTimeParts

# DateTimeParts

`sdl.system` 包中的 public struct

拆解后的日历时间：年月日、时分秒、纳秒、星期与 UTC 偏移。字段全部带默认值（1970-01-01 00:00:00），`DateTimeParts()` 构造后逐项赋值，或由 [`Time.toDateTime`](Time.md#todatetime) 填好返回。

## 声明

```cangjie
public struct DateTimeParts
```

## 示例

```cangjie verify
package docexample

import sdl.system.{DateTimeParts, Time}

main(): Unit {
    var parts = DateTimeParts()
    parts.year = 2026
    parts.month = 7
    parts.day = 19
    parts.hour = 12
    parts.utcOffsetSeconds = 8 * 3600 // 东八区
    let nanoseconds = Time.toNanoseconds(parts)
    let back = Time.toDateTime(nanoseconds, local: false)
    println("${back.year}-${back.month}-${back.day} UTC 时 ${back.hour}")
    // 输出: 2026-7-19 UTC 时 4
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建 1970-01-01 00:00:00、无星期且 UTC 偏移为 0 的日历字段。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`year`](#year) | 年；默认 1970。 |
| [`month`](#month) | 月，1–12；默认 1。 |
| [`day`](#day) | 日，1–31；默认 1。 |
| [`hour`](#hour) | 时，0–23；默认 0。 |
| [`minute`](#minute) | 分，0–59；默认 0。 |
| [`second`](#second) | 秒，0–59；默认 0。 |
| [`nanosecond`](#nanosecond) | 纳秒，0–999 999 999；默认 0。 |
| [`dayOfWeek`](#dayofweek) | 星期；`None` 表示未填。 |
| [`utcOffsetSeconds`](#utcoffsetseconds) | 相对 UTC 的偏移秒数（东八区为 28800）；默认 0。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建 1970-01-01 00:00:00、无星期且 UTC 偏移为 0 的日历字段。

```cangjie
public init()
```

## 字段

### year

年；默认 1970。

```cangjie
public var year: Int32 = 1970
```

### month

月，1–12；默认 1。

```cangjie
public var month: Int32 = 1
```

### day

日，1–31；默认 1。

```cangjie
public var day: Int32 = 1
```

### hour

时，0–23；默认 0。

```cangjie
public var hour: Int32 = 0
```

### minute

分，0–59；默认 0。

```cangjie
public var minute: Int32 = 0
```

### second

秒，0–59；默认 0。

```cangjie
public var second: Int32 = 0
```

### nanosecond

纳秒，0–999 999 999；默认 0。

```cangjie
public var nanosecond: Int32 = 0
```

### dayOfWeek

星期；`None` 表示未填。[`Time.toDateTime`](Time.md#todatetime) 返回时填好；作为 [`Time.toNanoseconds`](Time.md#tonanoseconds) 的输入时无须填写。

```cangjie
public var dayOfWeek: ?Weekday = None
```

### utcOffsetSeconds

相对 UTC 的偏移秒数（东八区为 28800）；默认 0。

```cangjie
public var utcOffsetSeconds: Int32 = 0
```

## 另请参阅

- [Time](Time.md) — 与纳秒时间戳互转。
- [Weekday](Weekday.md) — 星期枚举。
