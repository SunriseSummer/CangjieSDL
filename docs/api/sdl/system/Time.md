[sdl](../../index.md) › [sdl.system](index.md) › Time

# Time

`sdl.system` 包中的 public class

系统实时钟与日历换算：读取当前时间（1970-01-01 UTC 起算的纳秒），在纳秒时间戳与 [`DateTimeParts`](DateTimeParts.md) 之间互转，查询每月天数、一年中的第几天和星期，以及与 Windows FILETIME 互转。单调计时见 [`PerformanceClock`](PerformanceClock.md)。SDL 无法读取时钟、换算日历字段或返回有效日历结果时，方法把失败状态转换为 `CuiException`。

## 声明

```cangjie
public class Time
```

## 示例

```cangjie verify
package docexample

import sdl.system.Time

main(): Unit {
    let now = Time.currentDateTime()
    println(now.year >= 2026)
    println(Time.daysInMonth(2026, 2))
    // 输出:
    // true
    // 28
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `Time` 对象；时间操作由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static currentNanoseconds()`](#currentnanoseconds) | 当前系统时间，1970-01-01 UTC 起算的纳秒。 |
| [`static currentDateTime(local!: Bool)`](#currentdatetime) | 当前时间的日历字段（默认本地时区）。 |
| [`static toDateTime(nanoseconds: Int64, local!: Bool)`](#todatetime) | 纳秒时间戳转日历字段。 |
| [`static toNanoseconds(parts: DateTimeParts)`](#tonanoseconds) | 日历字段转纳秒时间戳。 |
| [`static toWindowsFileTime(nanoseconds: Int64)`](#towindowsfiletime) | SDL 时间转 Windows FILETIME（1601-01-01 起算的 100 纳秒滴答，拆为高低 32 位）。 |
| [`static fromWindowsFileTime(fileTime: WindowsFileTime)`](#fromwindowsfiletime) | Windows FILETIME 转 SDL 时间。 |
| [`static daysInMonth(year: Int32, month: Int32)`](#daysinmonth) | 某年某月的天数（闰年 2 月为 29）。 |
| [`static dayOfYear(year: Int32, month: Int32, day: Int32)`](#dayofyear) | 返回日期在一年中的序号（从 0 开始，1 月 1 日为 0）。 |
| [`static dayOfWeek(year: Int32, month: Int32, day: Int32)`](#dayofweek) | 日期对应的星期。 |
| [`static localePreferences()`](#localepreferences) | 系统区域的日期时间显示偏好。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `Time` 对象；时间操作由静态方法提供。

```cangjie
public init()
```

## 方法

### currentNanoseconds

当前系统时间，1970-01-01 UTC 起算的纳秒。

```cangjie
public static func currentNanoseconds(): Int64
```

**返回值** `Int64` — 纳秒时间戳。

**异常**

- `CuiException` — SDL 无法读取实时钟时。

### currentDateTime

当前时间的日历字段（默认本地时区）。

```cangjie
public static func currentDateTime(local!: Bool = true): DateTimeParts
```

**参数**

- `local!`: `Bool` — `true` 按本地时区拆解，`false` 按 UTC；默认 `true`。

**返回值** `DateTimeParts` — 拆解后的日历时间，含星期与 UTC 偏移。

**异常**

- `CuiException` — SDL 无法读取或换算时。

### toDateTime

纳秒时间戳转日历字段。

```cangjie
public static func toDateTime(nanoseconds: Int64, local!: Bool = true): DateTimeParts
```

**参数**

- `nanoseconds`: `Int64` — 1970-01-01 UTC 起算的纳秒。
- `local!`: `Bool` — `true` 按本地时区，`false` 按 UTC；默认 `true`。

**返回值** `DateTimeParts` — 拆解后的日历时间。

**异常**

- `CuiException` — SDL 无法换算时。

### toNanoseconds

日历字段转纳秒时间戳。`parts.utcOffsetSeconds` 参与换算；`dayOfWeek` 不需要填。

```cangjie
public static func toNanoseconds(parts: DateTimeParts): Int64
```

**参数**

- `parts`: `DateTimeParts` — 日历字段。

**返回值** `Int64` — 纳秒时间戳。

**异常**

- `CuiException` — 字段无法构成合法时间时。

### toWindowsFileTime

SDL 时间转 Windows FILETIME（1601-01-01 起算的 100 纳秒滴答，拆为高低 32 位）。

```cangjie
public static func toWindowsFileTime(nanoseconds: Int64): WindowsFileTime
```

**参数**

- `nanoseconds`: `Int64` — SDL 纳秒时间戳。

**返回值** `WindowsFileTime` — FILETIME 高低位。

### fromWindowsFileTime

Windows FILETIME 转 SDL 时间。

```cangjie
public static func fromWindowsFileTime(fileTime: WindowsFileTime): Int64
```

**参数**

- `fileTime`: `WindowsFileTime` — FILETIME 高低位。

**返回值** `Int64` — SDL 纳秒时间戳。

### daysInMonth

某年某月的天数（闰年 2 月为 29）。

```cangjie
public static func daysInMonth(year: Int32, month: Int32): Int32
```

**参数**

- `year`: `Int32` — 年。
- `month`: `Int32` — 月，1–12。

**返回值** `Int32` — 当月天数。

**异常**

- `CuiException` — 年/月非法时。

### dayOfYear

返回日期在一年中的序号（从 0 开始，1 月 1 日为 0）。

```cangjie
public static func dayOfYear(year: Int32, month: Int32, day: Int32): Int32
```

**参数**

- `year`、`month`、`day`: `Int32` — 日期。

**返回值** `Int32` — 从 0 开始的一年内日期序号。

**异常**

- `CuiException` — 日期非法时。

### dayOfWeek

日期对应的星期。

```cangjie
public static func dayOfWeek(year: Int32, month: Int32, day: Int32): Weekday
```

**参数**

- `year`、`month`、`day`: `Int32` — 日期。

**返回值** `Weekday` — 星期。

**异常**

- `CuiException` — 日期非法时。

### localePreferences

系统区域的日期时间显示偏好。

```cangjie
public static func localePreferences(): DateTimeLocalePreferences
```

**返回值** `DateTimeLocalePreferences` — 日期顺序与报时制式。

**异常**

- `CuiException` — SDL 无法查询区域偏好时。

## 另请参阅

- [DateTimeParts](DateTimeParts.md) · [WindowsFileTime](WindowsFileTime.md) · [Weekday](Weekday.md)
- [PerformanceClock](PerformanceClock.md) — 单调高精度计时。
