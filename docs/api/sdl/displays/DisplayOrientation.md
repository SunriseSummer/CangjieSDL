[sdl](../../index.md) › [sdl.displays](index.md) › DisplayOrientation

# DisplayOrientation

`sdl.displays` 包中的 public enum

显示器的朝向。SDL 报告未知或无法识别的值时映射为 `Unknown`。

## 声明

```cangjie
public enum DisplayOrientation
```

## 示例

```cangjie verify
package docexample

import sdl.displays.{DisplayOrientation, primaryDisplayInfo}

main(): Unit {
    // 运行时初始化视频子系统并查询主显示器；此处仅演示朝向的匹配。
    let info = primaryDisplayInfo()
    match (info.orientations.current) {
        case DisplayOrientation.Landscape => println("横屏")
        case DisplayOrientation.Portrait => println("竖屏")
        case _ => println("其他朝向")
    }
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Unknown` | 无法确定朝向。 |
| `Landscape` | 横屏。 |
| `LandscapeFlipped` | 横屏翻转（旋转 180°）。 |
| `Portrait` | 竖屏。 |
| `PortraitFlipped` | 竖屏翻转。 |

## 另请参阅

- [DisplayOrientations](DisplayOrientations.md) — 自然朝向与当前朝向的组合。
