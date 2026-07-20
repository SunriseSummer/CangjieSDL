[sdl](../../index.md) › [sdl.system](index.md) › DateFormat

# DateFormat

`sdl.system` 包中的 public enum

系统区域偏好的日期字段顺序；SDL 报告未识别的编码时以 `UnknownDateFormat` 携带原始值。

## 声明

```cangjie
public enum DateFormat
```

## 示例

```cangjie verify
package docexample

import sdl.system.{DateFormat, Time}

main(): Unit {
    let prefs = Time.localePreferences()
    match (prefs.dateFormat) {
        case DateFormat.YearMonthDay => println("年/月/日")
        case DateFormat.DayMonthYear => println("日/月/年")
        case DateFormat.MonthDayYear => println("月/日/年")
        case DateFormat.UnknownDateFormat(code) => println("未知(${code})")
    }
    // 运行时按系统区域输出日期顺序。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`YearMonthDay`](#yearmonthday) | 年/月/日。 |
| [`DayMonthYear`](#daymonthyear) | 日/月/年。 |
| [`MonthDayYear`](#monthdayyear) | 月/日/年。 |
| [`UnknownDateFormat(Int32)`](#unknowndateformat) | 未识别的顺序，携带 SDL 原始编码。 |

## 枚举值

### YearMonthDay

年/月/日。

```cangjie
YearMonthDay
```

### DayMonthYear

日/月/年。

```cangjie
DayMonthYear
```

### MonthDayYear

月/日/年。

```cangjie
MonthDayYear
```

### UnknownDateFormat

未识别的顺序，携带 SDL 原始编码。

```cangjie
UnknownDateFormat(Int32)
```

## 另请参阅

- [DateTimeLocalePreferences](DateTimeLocalePreferences.md) · [Time.localePreferences](Time.md#localepreferences)
