[sdl](../../index.md) › [sdl.input](index.md) › ClipboardData

# ClipboardData

`sdl.input` 包中的 public struct

一段二进制剪贴板数据及其 MIME 类型，供 [`Clipboard.setData`](Clipboard.md#setdata) 批量提交给其他桌面应用。

## 声明

```cangjie
public struct ClipboardData
```

## 示例

```cangjie verify
package docexample

import sdl.input.{Clipboard, ClipboardData}

main(): Unit {
    let payload = ClipboardData("text/plain", "你好".toArray())
    Clipboard.setData([payload])
    match (Clipboard.getData("text/plain")) {
        case Some(bytes) => println("剪贴板提供 ${bytes.size} 字节的 text/plain 数据")
        case None => println("剪贴板没有 text/plain 数据")
    }
    Clipboard.clearData()
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(mimeType: String, bytes: Array<UInt8>)`](#init) | 由 MIME 类型与字节内容构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`mimeType`](#mimetype) | 报出的 MIME 类型，如 `"text/plain"`、`"image/png"`。 |
| [`bytes`](#bytes) | 剪贴板数据的字节。 |

## 构造函数

### init

由 MIME 类型与字节内容构造。

```cangjie
public init(mimeType: String, bytes: Array<UInt8>)
```

**参数**

- `mimeType`: `String` — MIME 类型；提交时须非空且不含控制字节。
- `bytes`: `Array<UInt8>` — 剪贴板数据。

## 字段

### mimeType

报出的 MIME 类型，如 `"text/plain"`、`"image/png"`。

```cangjie
public let mimeType: String
```

### bytes

剪贴板数据的字节。

```cangjie
public let bytes: Array<UInt8>
```

## 另请参阅

- [Clipboard.setData](Clipboard.md#setdata) — 提交入口。
