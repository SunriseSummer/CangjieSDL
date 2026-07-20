[sdl](../../index.md) › [sdl.system](index.md) › Weekday

# Weekday

`sdl.system` 包中的 public enum

星期几，周日起算，由 [`Time.dayOfWeek`](Time.md#dayofweek) 与 [`DateTimeParts.dayOfWeek`](DateTimeParts.md#dayofweek) 使用。

## 声明

```cangjie
public enum Weekday
```

## 示例

```cangjie verify
package docexample

import sdl.system.{Time, Weekday}

main(): Unit {
    let day = Time.dayOfWeek(2026, 7, 19)
    match (day) {
        case Weekday.Sunday => println("周日")
        case Weekday.Saturday => println("周六")
        case _ => println("工作日")
    }
    // 输出: 周日
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Sunday` | 周日。 |
| `Monday` | 周一。 |
| `Tuesday` | 周二。 |
| `Wednesday` | 周三。 |
| `Thursday` | 周四。 |
| `Friday` | 周五。 |
| `Saturday` | 周六。 |

## 另请参阅

- [Time.dayOfWeek](Time.md#dayofweek) — 日期到星期的换算。
