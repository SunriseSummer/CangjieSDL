[sdl](../../index.md) › [sdl.system](index.md) › SdlHint

# SdlHint

`sdl.system` 包中的 public enum

常用 SDL hint 的名称；`CustomHint` 携带任意 SDL hint 名。hint 是 SDL 的运行时配置开关，须在受影响的子系统初始化之前设置才可靠生效。

## 声明

```cangjie
public enum SdlHint
```

## 示例

```cangjie verify
package docexample

import sdl.system.{SdlHint, SdlHints}

main(): Unit {
    SdlHints.set(SdlHint.AppName, "绘图板")
    match (SdlHints.get(SdlHint.AppName)) {
        case Some(value) => println(value)
        case None => println("未设置")
    }
    // 输出: 绘图板
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`AppId`](#appid) | 应用标识（SDL_HINT_APP_ID）。 |
| [`AppName`](#appname) | 应用显示名（SDL_HINT_APP_NAME）。 |
| [`FileDialogDriver`](#filedialogdriver) | 文件对话框后端选择。 |
| [`ImeImplementedUi`](#imeimplementedui) | 输入法 UI 的实现方归属。 |
| [`MouseFocusClickthrough`](#mousefocusclickthrough) | 点击未聚焦窗口时，是否把这次点击同时交给窗口处理。 |
| [`RenderVSync`](#rendervsync) | 渲染器 vsync 默认值。 |
| [`ReturnKeyHidesIme`](#returnkeyhidesime) | 回车是否收起软键盘/输入法。 |
| [`VideoAllowScreensaver`](#videoallowscreensaver) | 是否允许屏保运行（SDL 默认阻止）。 |
| [`VideoDriver`](#videodriver) | 视频后端选择。 |
| [`WindowsCloseOnAltF4`](#windowscloseonaltf4) | Windows 上 Alt+F4 是否关闭窗口。 |
| [`CustomHint(String)`](#customhint) | 任意 hint，携带完整 SDL hint 名（如 `"SDL_RENDER_DRIVER"`）；空名在读写时抛 `CuiException`。 |

## 枚举值

### AppId

应用标识（SDL_HINT_APP_ID）。

```cangjie
AppId
```

### AppName

应用显示名（SDL_HINT_APP_NAME）。

```cangjie
AppName
```

### FileDialogDriver

文件对话框后端选择。

```cangjie
FileDialogDriver
```

### ImeImplementedUi

输入法 UI 的实现方归属。

```cangjie
ImeImplementedUi
```

### MouseFocusClickthrough

点击未聚焦窗口时，是否把这次点击同时交给窗口处理。

```cangjie
MouseFocusClickthrough
```

### RenderVSync

渲染器 vsync 默认值。

```cangjie
RenderVSync
```

### ReturnKeyHidesIme

回车是否收起软键盘/输入法。

```cangjie
ReturnKeyHidesIme
```

### VideoAllowScreensaver

是否允许屏保运行（SDL 默认阻止）。

```cangjie
VideoAllowScreensaver
```

### VideoDriver

视频后端选择。

```cangjie
VideoDriver
```

### WindowsCloseOnAltF4

Windows 上 Alt+F4 是否关闭窗口。

```cangjie
WindowsCloseOnAltF4
```

### CustomHint

任意 hint，携带完整 SDL hint 名（如 `"SDL_RENDER_DRIVER"`）；空名在读写时抛 `CuiException`。

```cangjie
CustomHint(String)
```

## 另请参阅

- [SdlHints](SdlHints.md) — 读写入口。
