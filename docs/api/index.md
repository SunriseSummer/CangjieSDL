# CangjieSDL API 参考

CangjieSDL 将 SDL 3 和 SDL_ttf 的常用能力封装为类型安全的仓颉 API。窗口布局、输入坐标和绘制统一使用逻辑像素；原生指针只存在于实现内部。

如果正在学习整体用法，请先阅读[使用指南](../guide/index.md)。本参考用于查询精确签名、默认值、返回值、异常和资源约束。

## 快速示例

```cangjie verify role=complete profile=gui-visual
package docexample

import sdl.{Color, SdlWindow, UiEvent, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("你好，SDL", 800, 600))) {
        var running = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case UiEvent.WindowCloseRequested => running = false
                    case _ => ()
                }
            }
            window.renderer.renderFrame(
                Float32(window.width),
                Float32(window.height),
                Color.rgb(30, 30, 46)
            ) {=> ()}
            window.delay(UInt32(16))
        }
    }
}
```

## 按任务选择包

| 目标 | 包 |
|---|---|
| 创建窗口、处理事件、绘制图形和文字、管理图片资源 | [`sdl`](sdl/index.md) |
| 访问剪贴板、键鼠状态和系统光标 | [`sdl.input`](sdl/input/index.md) |
| 显示消息框或异步文件对话框 | [`sdl.dialogs`](sdl/dialogs/index.md) |
| 查询显示器和匹配全屏模式 | [`sdl.displays`](sdl/displays/index.md) |
| 访问路径、文件、元数据、时间、电源和平台信息 | [`sdl.system`](sdl/system/index.md) |

## 共同约定

- `SdlWindow`、`Surface`、`Texture`、`Cursor`、`RenderPass` 和 `TextMeasureSession` 等资源应使用 `try (...)` 或明确调用 `close()`。
- `Renderer`、由它创建的纹理和命令资源只能在渲染器的创建线程使用。
- 设备、目录或平台能力可能不存在；返回 `Option` 或结果枚举的 API 不应强制解包。
- SDL 调用失败通常转换为 `SdlException`；参数、生命周期和线程错误使用对应的仓颉标准异常。
