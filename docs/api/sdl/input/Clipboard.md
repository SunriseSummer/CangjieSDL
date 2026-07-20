[sdl](../../index.md) › [sdl.input](index.md) › Clipboard

# Clipboard

`sdl.input` 包中的 public class

SDL3 剪贴板的主线程访问入口：普通文本、主选择文本（X11 的选中即复制），以及带 MIME 类型的二进制数据。全部为静态方法，须在视频子系统初始化后（通常已有窗口）于主线程调用。写入失败以及读取已报告为可用的二进制数据失败时，方法把 SDL 错误转换为 `CuiException`；探测不到内容则按各方法契约返回 `false`、`None` 或空值。文本读取遇到空指针时返回空字符串。

## 声明

```cangjie
public class Clipboard
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowSpec}
import sdl.input.Clipboard

main(): Unit {
    // 剪贴板依赖视频子系统，本示例仅作编译验证；
    // 运行时把文本写入系统剪贴板并读回。
    try (window = SdlWindow(WindowSpec("剪贴板", 320, 240))) {
        Clipboard.setText("来自 sdl 的问候")
        if (Clipboard.hasText()) {
            println(Clipboard.getText())
        }
        window.delay(1)
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `Clipboard` 对象；剪贴板操作由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static setText(text: String)`](#settext) | 写入系统剪贴板文本。 |
| [`static hasText()`](#hastext) | 判断剪贴板是否有文本。 |
| [`static getText()`](#gettext) | 读取剪贴板文本；无文本时为空串。 |
| [`static setPrimarySelectionText(text: String)`](#setprimaryselectiontext) | 写入主选择文本（X11 的选中缓冲；无此概念的平台上等同普通剪贴板或无效果）。 |
| [`static hasPrimarySelectionText()`](#hasprimaryselectiontext) | 判断主选择是否有文本。 |
| [`static getPrimarySelectionText()`](#getprimaryselectiontext) | 读取主选择文本；无文本时为空串。 |
| [`static setData(items: Array<ClipboardData>)`](#setdata) | 以多个 MIME 类型报出二进制数据，供其他应用拉取。 |
| [`static clearData()`](#cleardata) | 清空非文本剪贴板数据。 |
| [`static hasData(mimeType: String)`](#hasdata) | 判断剪贴板是否有指定 MIME 类型的数据。 |
| [`static getData(mimeType: String)`](#getdata) | 读取指定 MIME 类型的数据；不存在时为 `None`。 |
| [`static mimeTypes()`](#mimetypes) | 枚举剪贴板当前可用的 MIME 类型；SDL 未返回列表时为空数组。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `Clipboard` 对象；剪贴板操作由静态方法提供。

```cangjie
public init()
```

## 方法

### setText

写入系统剪贴板文本。

```cangjie
public static func setText(text: String): Unit
```

**参数**

- `text`: `String` — 写入的 UTF-8 文本。

**异常**

- `CuiException` — SDL 无法更新剪贴板时。

### hasText

判断剪贴板是否有文本。

```cangjie
public static func hasText(): Bool
```

**返回值** `Bool` — 有文本时为 `true`。

### getText

读取剪贴板文本；无文本时为空串。

```cangjie
public static func getText(): String
```

**返回值** `String` — 剪贴板文本，或空串。

### setPrimarySelectionText

写入主选择文本（X11 的选中缓冲；无此概念的平台上等同普通剪贴板或无效果）。

```cangjie
public static func setPrimarySelectionText(text: String): Unit
```

**参数**

- `text`: `String` — 写入的文本。

**异常**

- `CuiException` — SDL 无法更新主选择时。

### hasPrimarySelectionText

判断主选择是否有文本。

```cangjie
public static func hasPrimarySelectionText(): Bool
```

**返回值** `Bool` — 有文本时为 `true`。

### getPrimarySelectionText

读取主选择文本；无文本时为空串。

```cangjie
public static func getPrimarySelectionText(): String
```

**返回值** `String` — 主选择文本，或空串。

### setData

以多个 MIME 类型报出二进制数据，供其他应用拉取。SDL 采用回调式供给：数据由本模块持有，其他应用请求时按需交付；再次 `setData`、[`clearData`](#cleardata) 或被其他应用覆盖剪贴板时释放。

```cangjie
public static func setData(items: Array<ClipboardData>): Unit
```

**参数**

- `items`: `Array<ClipboardData>` — 报出的条目；列表须非空，每项 MIME 类型须非空且不含控制字节。

**异常**

- `CuiException` — MIME 类型非法，或 SDL 拒绝数据时。

### clearData

清空非文本剪贴板数据。

```cangjie
public static func clearData(): Unit
```

**异常**

- `CuiException` — SDL 无法清空时。

### hasData

判断剪贴板是否有指定 MIME 类型的数据。

```cangjie
public static func hasData(mimeType: String): Bool
```

**参数**

- `mimeType`: `String` — 查询的 MIME 类型；须非空。

**返回值** `Bool` — 存在该类型数据时为 `true`。

**异常**

- `CuiException` — `mimeType` 为空时。

### getData

读取指定 MIME 类型的数据；不存在时为 `None`。存在但内容为零字节时返回空数组。

```cangjie
public static func getData(mimeType: String): ?Array<UInt8>
```

**参数**

- `mimeType`: `String` — 读取的 MIME 类型；须非空。

**返回值** `?Array<UInt8>` — 数据字节；类型不存在时为 `None`。

**异常**

- `CuiException` — `mimeType` 为空，或 SDL 无法复制其报告为可用的数据时。

### mimeTypes

枚举剪贴板当前可用的 MIME 类型；SDL 未返回列表时为空数组。

```cangjie
public static func mimeTypes(): Array<String>
```

**返回值** `Array<String>` — MIME 类型数组。

## 另请参阅

- [ClipboardData](ClipboardData.md) — `setData` 的条目类型。
