[sdl](../../index.md) › [sdl.system](index.md) › PowerInfo

# PowerInfo

`sdl.system` 包中的 public struct

电源信息快照：供电状态、剩余秒数与剩余百分比；系统无法给出的项为 `None`。由 [`powerInfo`](functions.md#powerinfo) 返回。

## 声明

```cangjie
public struct PowerInfo
```

## 示例

```cangjie verify
package docexample

import sdl.system.{PowerInfo, powerInfo}

main(): Unit {
    let power: PowerInfo = powerInfo()
    match (power.percent) {
        case Some(percent) => println("电量 ${percent}%")
        case None => println("电量不可知")
    }
    // 运行时打印电量或"不可知"。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(state: PowerState, seconds: ?Int32, percent: ?Int32)`](#init) | 逐项构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`state`](#state) | 供电状态。 |
| [`seconds`](#seconds) | 剩余续航秒数；不可知时为 `None`。 |
| [`percent`](#percent) | 剩余电量百分比 0–100；不可知时为 `None`。 |

## 构造函数

### init

逐项构造。

```cangjie
public init(state: PowerState, seconds: ?Int32, percent: ?Int32)
```

**参数**

- `state`: `PowerState` — 供电状态。
- `seconds`: `?Int32` — 剩余秒数。
- `percent`: `?Int32` — 剩余百分比。

## 字段

### state

供电状态。

```cangjie
public let state: PowerState
```

### seconds

剩余续航秒数；不可知时为 `None`。

```cangjie
public let seconds: ?Int32
```

### percent

剩余电量百分比 0–100；不可知时为 `None`。

```cangjie
public let percent: ?Int32
```

## 另请参阅

- [powerInfo](functions.md#powerinfo) — 查询入口。
- [PowerState](PowerState.md) — 状态枚举。
