[sdl](index.md) › FontRole

# FontRole

跨平台通用族名：system-ui、sans-serif、serif、monospace、emoji。用作 fontFamily 或 Fonts.setDefault 的名称。应用显式注册同名族时优先使用应用定义。

## 声明与成员

```cangjie
public struct FontRole
public static let systemUI: String = "system-ui"
public static let sansSerif: String = "sans-serif"
public static let serif: String = "serif"
public static let monospace: String = "monospace"
public static let emoji: String = "emoji"
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。

`emoji` 定向查询平台 Emoji 字体，不加载完整目录。Windows：Segoe UI Emoji；Linux：Noto Color Emoji／Noto Emoji／Twemoji Mozilla；macOS：Apple Color Emoji。不可用时按常规字体回退规则处理；系统字体覆盖与实际图形由平台决定。
