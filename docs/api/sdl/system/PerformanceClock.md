[sdl](../../index.md) › [sdl.system](index.md) › PerformanceClock

# PerformanceClock

`sdl.system` 包中的 public class

单调高精度计时：毫秒/纳秒计时、性能计数器与高精度延时。适合帧计时与基准测量；需要当前日期和时间时使用 [`Time`](Time.md)。

## 声明

```cangjie
public class PerformanceClock
```

## 示例

```cangjie verify
package docexample

import sdl.system.PerformanceClock

main(): Unit {
    let start = PerformanceClock.counter()
    PerformanceClock.delayNanoseconds(PerformanceClock.millisecondsToNanoseconds(5))
    let elapsed = PerformanceClock.counter() - start
    let seconds = Float64(elapsed) / Float64(PerformanceClock.frequency())
    println(seconds > 0.0)
    // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `PerformanceClock` 对象；计时操作由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static ticksMilliseconds()`](#ticksmilliseconds) | SDL 初始化以来的毫秒数。 |
| [`static ticksNanoseconds()`](#ticksnanoseconds) | SDL 初始化以来的纳秒数。 |
| [`static counter()`](#counter) | 高精度性能计数器的当前值。 |
| [`static frequency()`](#frequency) | 性能计数器每秒的滴答数。 |
| [`static delayNanoseconds(ns: UInt64)`](#delaynanoseconds) | 阻塞等待指定纳秒。 |
| [`static delayPrecise(ns: UInt64)`](#delayprecise) | 更高精度地阻塞等待指定纳秒（以 CPU 占用换精度），适合帧节拍等需要精确唤醒的场景。 |
| [`static millisecondsToNanoseconds(ms: UInt64)`](#millisecondstonanoseconds) | 毫秒换算为纳秒（乘以 1 000 000）。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `PerformanceClock` 对象；计时操作由静态方法提供。

```cangjie
public init()
```

## 方法

### ticksMilliseconds

SDL 初始化以来的毫秒数。

```cangjie
public static func ticksMilliseconds(): UInt64
```

**返回值** `UInt64` — 毫秒计时。

### ticksNanoseconds

SDL 初始化以来的纳秒数。

```cangjie
public static func ticksNanoseconds(): UInt64
```

**返回值** `UInt64` — 纳秒计时。

### counter

高精度性能计数器的当前值。两次读数之差除以 [`frequency`](#frequency) 得到秒数。

```cangjie
public static func counter(): UInt64
```

**返回值** `UInt64` — 计数器读数。

### frequency

性能计数器每秒的滴答数。

```cangjie
public static func frequency(): UInt64
```

**返回值** `UInt64` — 每秒滴答数。

### delayNanoseconds

阻塞等待指定纳秒。

```cangjie
public static func delayNanoseconds(ns: UInt64): Unit
```

**参数**

- `ns`: `UInt64` — 等待时长，纳秒。

### delayPrecise

更高精度地阻塞等待指定纳秒（以 CPU 占用换精度），适合帧节拍等需要精确唤醒的场景。

```cangjie
public static func delayPrecise(ns: UInt64): Unit
```

**参数**

- `ns`: `UInt64` — 等待时长，纳秒。

### millisecondsToNanoseconds

毫秒换算为纳秒（乘以 1 000 000）。

```cangjie
public static func millisecondsToNanoseconds(ms: UInt64): UInt64
```

**参数**

- `ms`: `UInt64` — 毫秒数。

**返回值** `UInt64` — 纳秒数。

## 另请参阅

- [Time](Time.md) — 当前日期时间与日历换算。
- [SdlWindow.ticks](../SdlWindow.md#ticks) — 窗口侧的毫秒计时。
