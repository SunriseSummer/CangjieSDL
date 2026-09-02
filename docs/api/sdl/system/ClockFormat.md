[API 参考](../../index.md) › [sdl.system](index.md) › ClockFormat

# ClockFormat

当前系统区域偏好的时间显示制式。

```cangjie
public enum ClockFormat {
    | TwentyFourHour
    | TwelveHour
    | UnknownClockFormat(Int32)
}
```

| 值 | 含义 |
|---|---|
| `TwentyFourHour` | 24 小时制。 |
| `TwelveHour` | 12 小时制。 |
| `UnknownClockFormat(Int32)` | 未识别的 SDL 编码。 |

通过 [`Time.localePreferences`](Time.md#localepreferences) 获取。
