[sdl](../index.md) › [sdl](index.md) › ImageFileFormat

# ImageFileFormat

`sdl` 包中的 public enum

[`Surface`](Surface.md) 能读写的图像文件格式。

## 声明

```cangjie
public enum ImageFileFormat
```

## 示例

```cangjie verify
package docexample

import sdl.{ImageFileFormat, imageFormatFromPath}

main(): Unit {
    let format = imageFormatFromPath("assets/hero.png")
    match (format) {
        case ImageFileFormat.Png => println("按 PNG 读取")
        case ImageFileFormat.Bmp => println("按 BMP 读取")
    }
    // 输出: 按 PNG 读取
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Bmp` | Windows 位图（.bmp）。 |
| `Png` | PNG 图像（.png）。 |

## 另请参阅

- [imageFormatFromPath](functions.md#imageformatfrompath) — 按扩展名推断格式。
- [Surface.load](Surface.md#load) — 按推断格式加载图像。
