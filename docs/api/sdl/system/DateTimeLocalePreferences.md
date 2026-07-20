[sdl](../../index.md) › [sdl.system](index.md) › DateTimeLocalePreferences

# DateTimeLocalePreferences

`sdl.system` 包中的 public struct

系统区域的日期时间显示偏好：日期字段顺序与报时制式。由 [`Time.localePreferences`](Time.md#localepreferences) 返回。

## 声明

```cangjie
public struct DateTimeLocalePreferences
```

## 示例

```cangjie verify
package docexample

import sdl.system.{ClockFormat, DateTimeLocalePreferences, Time}

main(): Unit {
    let prefs: DateTimeLocalePreferences = Time.localePreferences()
    let use24h = match (prefs.clockFormat) {
        case ClockFormat.TwentyFourHour => true
        case _ => false
    }
    println("24 小时制：${use24h}")
    // 运行时按系统区域输出。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(dateFormat: DateFormat, clockFormat: ClockFormat)`](#init) | 由两项偏好构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`dateFormat`](#dateformat) | 日期字段顺序。 |
| [`clockFormat`](#clockformat) | 报时制式。 |

## 构造函数

### init

由两项偏好构造。

```cangjie
public init(dateFormat: DateFormat, clockFormat: ClockFormat)
```

**参数**

- `dateFormat`: `DateFormat` — 日期字段顺序。
- `clockFormat`: `ClockFormat` — 报时制式。

## 字段

### dateFormat

日期字段顺序。

```cangjie
public let dateFormat: DateFormat
```

### clockFormat

报时制式。

```cangjie
public let clockFormat: ClockFormat
```

## 另请参阅

- [DateFormat](DateFormat.md) · [ClockFormat](ClockFormat.md)
