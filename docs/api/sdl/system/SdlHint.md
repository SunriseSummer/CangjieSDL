[API 参考](../../index.md) › [sdl.system](index.md) › SdlHint

# SdlHint

常用 SDL 配置提示的名称。提示通常应在受影响的子系统初始化前设置；读回值只说明 SDL 保存了配置，不保证所有平台都会采用。

```cangjie
public enum SdlHint {
    | AppId
    | AppName
    | FileDialogDriver
    | ImeImplementedUi
    | MouseFocusClickthrough
    | RenderVSync
    | ReturnKeyHidesIme
    | VideoAllowScreensaver
    | VideoDriver
    | WindowsCloseOnAltF4
    | CustomHint(String)
}
```

| 值 | 含义 |
|---|---|
| `AppId` | 应用标识。 |
| `AppName` | 应用显示名。 |
| `FileDialogDriver` | 文件对话框后端。 |
| `ImeImplementedUi` | 输入法界面由谁实现。 |
| `MouseFocusClickthrough` | 点击未聚焦窗口时是否同时传递该次点击。 |
| `RenderVSync` | 渲染器垂直同步默认值。 |
| `ReturnKeyHidesIme` | 回车是否收起软键盘或输入法。 |
| `VideoAllowScreensaver` | 是否允许屏保运行。 |
| `VideoDriver` | 视频后端。 |
| `WindowsCloseOnAltF4` | Windows 上 Alt+F4 是否关闭窗口。 |
| `CustomHint(String)` | 完整的自定义 SDL hint 名；空名会被拒绝。 |

通过 [`SdlHints`](SdlHints.md) 读写和重置提示。
