[sdl](../index.md) › [sdl](index.md) › IconName

# IconName

`sdl` 包中的 public enum

内置矢量图标的名称，交给 [`drawIcon`](functions.md#drawicon) 在 24×24 的坐标网格上绘制圆头线条图标。

## 声明

```cangjie
public enum IconName
```

## 示例

```cangjie verify
package docexample

import sdl.{Color, IconName, Rect, Renderer, drawIcon}

main(): Unit {
    let r = Renderer.headless()
    // 在 32×32 的区域内绘制“保存”图标；真实窗口中会显示为 2 像素描边的软盘轮廓。
    drawIcon(r, IconName.Save, Rect(8.0, 8.0, 32.0, 32.0), Color.rgb(220, 220, 230))
    println("图标绘制完成")
    // 输出: 图标绘制完成
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `NewDocument` | 新建文档：带折角与加号的纸张。 |
| `OpenFolder` | 打开文件夹。 |
| `Save` | 保存：软盘轮廓。 |
| `SaveAs` | 另存为：软盘加外指箭头。 |
| `Copy` | 复制：两张错位的卡片。 |
| `Paste` | 粘贴：带夹子的剪贴板。 |
| `Refresh` | 刷新：带箭头的圆环。 |
| `Trash` | 删除：垃圾桶。 |
| `Brush` | 画笔。 |
| `Calendar` | 日历。 |
| `Clock` | 时钟：表盘加时针分针。 |
| `Process` | 处理器：芯片轮廓。 |
| `Calculator` | 计算器。 |
| `ChevronLeft` | 左尖角。 |
| `ChevronRight` | 右尖角。 |

## 另请参阅

- [drawIcon](functions.md#drawicon) — 图标绘制函数。
