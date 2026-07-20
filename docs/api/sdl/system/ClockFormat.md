[sdl](../../index.md) › [sdl.system](index.md) › ClockFormat

# ClockFormat

`sdl.system` 包中的 public enum

系统区域偏好的报时制式；SDL 报告未识别的编码时以 `UnknownClockFormat` 携带原始值。

## 声明

```cangjie
public enum ClockFormat
```

## 示例

```cangjie verify
package docexample

import sdl.system.{ClockFormat, Time}

main(): Unit {
    let prefs = Time.localePreferences()
    match (prefs.clockFormat) {
        case ClockFormat.TwentyFourHour => println("24 小时制")
        case ClockFormat.TwelveHour => println("12 小时制")
        case ClockFormat.UnknownClockFormat(code) => println("未知(${code})")
    }
    // 运行时按系统区域输出报时制式。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`TwentyFourHour`](#twentyfourhour) | 24 小时制。 |
| [`TwelveHour`](#twelvehour) | 12 小时制。 |
| [`UnknownClockFormat(Int32)`](#unknownclockformat) | 未识别的制式，携带 SDL 原始编码。 |

## 枚举值

### TwentyFourHour

24 小时制。

```cangjie
TwentyFourHour
```

### TwelveHour

12 小时制。

```cangjie
TwelveHour
```

### UnknownClockFormat

未识别的制式，携带 SDL 原始编码。

```cangjie
UnknownClockFormat(Int32)
```

## 另请参阅

- [DateTimeLocalePreferences](DateTimeLocalePreferences.md) · [Time.localePreferences](Time.md#localepreferences)
