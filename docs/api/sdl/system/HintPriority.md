[sdl](../../index.md) › [sdl.system](index.md) › HintPriority

# HintPriority

`sdl.system` 包中的 public enum

设置 SDL hint 时的优先级；高优先级覆盖低优先级已写入的值。

## 声明

```cangjie
public enum HintPriority
```

## 示例

```cangjie verify
package docexample

import sdl.system.{HintPriority, SdlHint, SdlHints}

main(): Unit {
    SdlHints.setBool(SdlHint.VideoAllowScreensaver, true, priority: HintPriority.Override)
    println(SdlHints.getBool(SdlHint.VideoAllowScreensaver, false))
    // 输出: true
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Default` | 默认级——仅当 hint 尚无值时生效。 |
| `Normal` | 普通级（设置方法的默认值）。 |
| `Override` | 覆盖级——压过环境变量与已有值。 |

## 另请参阅

- [SdlHints](SdlHints.md) · [SdlHintSetting](SdlHintSetting.md)
