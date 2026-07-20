[sdl](../../index.md) › [sdl.system](index.md) › WindowsFileTime

# WindowsFileTime

`sdl.system` 包中的 public struct

Windows FILETIME 的高低 32 位组合（1601-01-01 起算的 100 纳秒滴答），与 SDL 时间互转时使用。

## 声明

```cangjie
public struct WindowsFileTime
```

## 示例

```cangjie verify
package docexample

import sdl.system.{Time, WindowsFileTime}

main(): Unit {
    let now = Time.currentNanoseconds()
    let fileTime: WindowsFileTime = Time.toWindowsFileTime(now)
    let roundTrip = Time.fromWindowsFileTime(fileTime)
    // FILETIME 精度为 100 纳秒，往返误差在一个刻度内。
    println((now - roundTrip) < 100 && (roundTrip - now) < 100)
    // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(low: UInt32, high: UInt32)`](#init) | 由高低位构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`low`](#low) | FILETIME 低 32 位。 |
| [`high`](#high) | FILETIME 高 32 位。 |

## 构造函数

### init

由高低位构造。

```cangjie
public init(low: UInt32, high: UInt32)
```

**参数**

- `low`、`high`: `UInt32` — FILETIME 的低位与高位。

## 字段

### low

FILETIME 低 32 位。

```cangjie
public let low: UInt32
```

### high

FILETIME 高 32 位。

```cangjie
public let high: UInt32
```

## 另请参阅

- [Time.toWindowsFileTime](Time.md#towindowsfiletime) · [Time.fromWindowsFileTime](Time.md#fromwindowsfiletime)
