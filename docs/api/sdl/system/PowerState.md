[sdl](../../index.md) › [sdl.system](index.md) › PowerState

# PowerState

`sdl.system` 包中的 public enum

设备的供电状态，出现在 [`PowerInfo.state`](PowerInfo.md#state) 中。

## 声明

```cangjie
public enum PowerState
```

## 示例

```cangjie verify
package docexample

import sdl.system.{powerInfo, PowerState}

main(): Unit {
    let power = powerInfo()
    match (power.state) {
        case PowerState.OnBattery => println("电池供电")
        case PowerState.NoBattery => println("无电池(台式机)")
        case PowerState.Charging => println("充电中")
        case PowerState.Charged => println("已充满")
        case _ => println("状态未知")
    }
    // 运行时按实际供电状态输出一行。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Error` | 查询出错。 |
| `Unknown` | 状态无法确定。 |
| `OnBattery` | 电池供电。 |
| `NoBattery` | 无电池（插电台式机）。 |
| `Charging` | 充电中。 |
| `Charged` | 已充满且仍插电。 |

## 另请参阅

- [powerInfo](functions.md#powerinfo) · [PowerInfo](PowerInfo.md)
