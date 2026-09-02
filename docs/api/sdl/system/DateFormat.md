[API 参考](../../index.md) › [sdl.system](index.md) › DateFormat

# DateFormat

当前系统区域偏好的日期字段顺序。

```cangjie
public enum DateFormat {
    | YearMonthDay
    | DayMonthYear
    | MonthDayYear
    | UnknownDateFormat(Int32)
}
```

| 值 | 含义 |
|---|---|
| `YearMonthDay` | 年、月、日。 |
| `DayMonthYear` | 日、月、年。 |
| `MonthDayYear` | 月、日、年。 |
| `UnknownDateFormat(Int32)` | 未识别的 SDL 编码。 |

通过 [`Time.localePreferences`](Time.md#localepreferences) 获取。
