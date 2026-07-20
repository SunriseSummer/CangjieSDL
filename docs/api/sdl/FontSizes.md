[sdl](../index.md) › [sdl](index.md) › FontSizes

# FontSizes

`sdl` 包中的 public struct

渲染器与应用共用的标准字号常量集合（点值）。[`Renderer.text`](Renderer.md#text) 系列方法的 `pointSize` 参数默认取 `BODY`。

## 声明

```cangjie
public struct FontSizes
```

## 示例

```cangjie verify
package docexample

import sdl.{FontSizes, Renderer}

main(): Unit {
    let r = Renderer.headless()
    let title = r.textHeight(pointSize: FontSizes.TITLE)
    let body = r.textHeight(pointSize: FontSizes.BODY)
    println(title > body)
    // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `FontSizes` 值；字号常量仍通过类型名访问。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`static CAPTION`](#caption) | 辅助说明文字字号，13 点。 |
| [`static BODY`](#body) | 正文字号，15 点；文本方法的默认字号。 |
| [`static CONTROL`](#control) | 控件文字字号，15 点。 |
| [`static TITLE`](#title) | 标题字号，20 点。 |
| [`static DISPLAY`](#display) | 展示型大字号，32 点。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `FontSizes` 值；字号常量仍通过类型名访问。

```cangjie
public init()
```

## 字段

### CAPTION

辅助说明文字字号，13 点。

```cangjie
public static let CAPTION: Float32 = 13.0
```

### BODY

正文字号，15 点；文本方法的默认字号。

```cangjie
public static let BODY: Float32 = 15.0
```

### CONTROL

控件文字字号，15 点。

```cangjie
public static let CONTROL: Float32 = 15.0
```

### TITLE

标题字号，20 点。

```cangjie
public static let TITLE: Float32 = 20.0
```

### DISPLAY

展示型大字号，32 点。

```cangjie
public static let DISPLAY: Float32 = 32.0
```

## 另请参阅

- [FontStyle](FontStyle.md) — 字重与修饰样式。
