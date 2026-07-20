[sdl](../index.md) › [sdl](index.md) › FontStyle

# FontStyle

`sdl` 包中的 public struct

叠加在基础 UI 字体上的文本样式：字重、倾斜与两种线条修饰。不可变值类型，`with…` 系列返回调整后的副本，样式可逐个标志叠加组合，如 `FontStyle(bold: true, italic: true)`。

## 声明

```cangjie
public struct FontStyle <: Equatable<FontStyle>
```

## 继承

- `Equatable<FontStyle>`（标准库 `std.core`）

## 说明

`bold` 优先使用随字体一同安装的真粗体伴随文件（msyh.ttc → msyhbd.ttc、segoeui.ttf → segoeuib.ttf、X-Regular → X-Bold），粗体文本因此使用字族真实的粗体轮廓；没有伴随文件的字体回退到 SDL_ttf 的合成加粗。`italic` 对字形做剪切变形，`underline` / `strikethrough` 在文字下方或中部画线——这三者对字体覆盖的任何文字（拉丁与中日韩皆同）都是合成生效的。

## 示例

```cangjie verify
package docexample

import sdl.FontStyle

main(): Unit {
    let emphasis = FontStyle(bold: true).withItalic()
    println("${emphasis.bold} ${emphasis.italic} 标志位 ${emphasis.ttfFlags()}")
    println(emphasis == FontStyle(bold: true, italic: true))
    // 输出:
    // true true 标志位 3
    // true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(bold!: Bool, italic!: Bool, underline!: Bool, strikethrough!: Bool)`](#init) | 以命名参数构造样式，各标志默认 `false`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`bold`](#bold) | 是否加粗。 |
| [`italic`](#italic) | 是否倾斜。 |
| [`underline`](#underline) | 是否带下划线。 |
| [`strikethrough`](#strikethrough) | 是否带删除线。 |
| [`static regular`](#regular) | 平文样式——无字重、倾斜与修饰。 |

**属性**

| 成员 | 说明 |
|---|---|
| [`isRegular`](#isregular) | 是否为平文样式：无字重、倾斜与修饰。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`withBold(value!: Bool)`](#withbold) | 返回打开（或设为 `value`）加粗的副本。 |
| [`withItalic(value!: Bool)`](#withitalic) | 返回打开（或设为 `value`）倾斜的副本。 |
| [`withUnderline(value!: Bool)`](#withunderline) | 返回打开（或设为 `value`）下划线的副本。 |
| [`withStrikethrough(value!: Bool)`](#withstrikethrough) | 返回打开（或设为 `value`）删除线的副本。 |
| [`ttfFlags()`](#ttfflags) | 返回 SDL_ttf 的样式位掩码（TTF_STYLE_*）。 |

**运算符**

| 成员 | 说明 |
|---|---|
| [`operator ==`](#operator) | 四个标志逐一相等则相等。 |
| [`operator !=`](#operator-1) | 相等判断的取反。 |

## 构造函数

### init

以命名参数构造样式，各标志默认 `false`。

```cangjie
public init(bold!: Bool = false, italic!: Bool = false, underline!: Bool = false, strikethrough!: Bool = false)
```

**参数**

- `bold!`: `Bool` — 加粗；默认 `false`。
- `italic!`: `Bool` — 倾斜；默认 `false`。
- `underline!`: `Bool` — 下划线；默认 `false`。
- `strikethrough!`: `Bool` — 删除线；默认 `false`。

## 字段

### bold

是否加粗。有真粗体伴随文件时使用真轮廓，否则合成加粗。

```cangjie
public let bold: Bool
```

### italic

是否倾斜。

```cangjie
public let italic: Bool
```

### underline

是否带下划线。

```cangjie
public let underline: Bool
```

### strikethrough

是否带删除线。

```cangjie
public let strikethrough: Bool
```

### regular

平文样式——无字重、倾斜与修饰。[`Renderer.text`](Renderer.md#text) 系列方法的 `style` 参数默认值。

```cangjie
public static let regular = FontStyle()
```

## 属性

### isRegular

是否为平文样式：无字重、倾斜与修饰。只读。

```cangjie
public prop isRegular: Bool
```

**返回值** `Bool` — 四个标志全为 `false` 时为 `true`。

## 方法

### withBold

返回打开（或设为 `value`）加粗的副本。

```cangjie
public func withBold(value!: Bool = true): FontStyle
```

**参数**

- `value!`: `Bool` — 加粗标志的新值；默认 `true`。

**返回值** `FontStyle` — 其余标志不变的副本。

### withItalic

返回打开（或设为 `value`）倾斜的副本。

```cangjie
public func withItalic(value!: Bool = true): FontStyle
```

**参数**

- `value!`: `Bool` — 倾斜标志的新值；默认 `true`。

**返回值** `FontStyle` — 其余标志不变的副本。

### withUnderline

返回打开（或设为 `value`）下划线的副本。

```cangjie
public func withUnderline(value!: Bool = true): FontStyle
```

**参数**

- `value!`: `Bool` — 下划线标志的新值；默认 `true`。

**返回值** `FontStyle` — 其余标志不变的副本。

### withStrikethrough

返回打开（或设为 `value`）删除线的副本。

```cangjie
public func withStrikethrough(value!: Bool = true): FontStyle
```

**参数**

- `value!`: `Bool` — 删除线标志的新值；默认 `true`。

**返回值** `FontStyle` — 其余标志不变的副本。

### ttfFlags

返回 SDL_ttf 的样式位掩码（TTF_STYLE_*）。位值属于 SDL_ttf 稳定 ABI：BOLD 0x01、ITALIC 0x02、UNDERLINE 0x04、STRIKETHROUGH 0x08；它同时参与文本测量缓存的键，使同尺寸的样式文本与平文分开缓存。

```cangjie
public func ttfFlags(): Int32
```

**返回值** `Int32` — 按开启标志按位或的掩码，平文为 0。

## 运算符

### operator==

四个标志逐一相等则相等。

```cangjie
public operator func ==(other: FontStyle): Bool
```

**参数**

- `other`: `FontStyle` — 比较对象。

**返回值** `Bool` — 标志全部相同时为 `true`。

### operator!=

相等判断的取反。

```cangjie
public operator func !=(other: FontStyle): Bool
```

**参数**

- `other`: `FontStyle` — 比较对象。

**返回值** `Bool` — 任一标志不同则为 `true`。

## 另请参阅

- [FontSizes](FontSizes.md) — 标准字号。
- [Renderer.text](Renderer.md#text) — 以样式绘制文本。
