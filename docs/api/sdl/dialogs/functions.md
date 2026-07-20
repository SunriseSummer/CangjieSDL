[sdl](../../index.md) › [sdl.dialogs](index.md) › 函数

# 函数 — sdl.dialogs

`sdl.dialogs` 包的包级函数。两者都是同步调用：消息框关闭后才返回。SDL 无法创建或显示消息框时，函数把失败状态转换为 `CuiException`。

### showSimpleMessageBox

弹出只有一个"确定"按钮的原生消息框，用户关闭后返回。

```cangjie
public func showSimpleMessageBox(title: String, message: String, kind!: MessageBoxKind = MessageBoxKind.Information, window!: ?SdlWindow = None): Unit
```

**参数**

- `title`: `String` — 对话框标题。
- `message`: `String` — 正文文本。
- `kind!`: `MessageBoxKind` — 严重级别，决定图标；默认值为 `MessageBoxKind.Information`，即信息级。
- `window!`: `?SdlWindow` — 作为父窗口的窗口；默认 `None`（无父窗口）。

**异常**

- `CuiException` — SDL 无法显示原生消息框时。

### showMessageBox

按 [`MessageBoxOptions`](MessageBoxOptions.md) 弹出自定义按钮的原生消息框，返回用户点击的按钮编号。

```cangjie
public func showMessageBox(options: MessageBoxOptions, window!: ?SdlWindow = None): Int32
```

**参数**

- `options`: `MessageBoxOptions` — 标题、正文、级别、按钮与配色；按钮列表须非空。
- `window!`: `?SdlWindow` — 作为父窗口的窗口；默认 `None`。

**返回值** `Int32` — 被点击按钮的 `id`；对话框被系统关闭而没有点击时为 -1。

**异常**

- `CuiException` — 选项非法（如按钮列表为空），或 SDL 无法显示消息框时。
