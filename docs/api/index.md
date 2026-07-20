# sdl

SDL3 与 SDL3_ttf 的仓颉安全封装：窗口、GPU 渲染（缓存网格几何、超采样抗锯齿）、文本、事件、剪贴板、对话框与系统设施。可独立用于游戏和图形应用，也可作为上层 UI 框架的底层运行时。应用 API 全部以仓颉类型表达，不暴露原始 C 指针；坐标统一为逻辑像素。

模块在 `cjpm.toml` 中按路径依赖引入（示例）：

```toml
[dependencies]
sdl = { path = "../sdl" }
```

## 快速示例

```cangjie verify
package docexample

import sdl.{Color, SdlWindow, UiEvent, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("你好，SDL", 800, 600))) {
        var running = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case _ => ()
                }
            }
            window.renderer.beginScene(800.0, 600.0, Color.rgb(30, 30, 46))
            window.renderer.endScene()
            window.renderer.present()
            window.delay(16)
        }
    }
}
```

## 包

| 包 | 说明 |
|---|---|
| [`sdl`](sdl/index.md) | 核心包：窗口与渲染器、事件解码、二维几何类型、文本与字体、纹理与表面。 |
| [`sdl.dialogs`](sdl/dialogs/index.md) | 原生消息框与异步文件对话框。 |
| [`sdl.displays`](sdl/displays/index.md) | 显示器信息查询与全屏显示模式枚举。 |
| [`sdl.input`](sdl/input/index.md) | 剪贴板、鼠标状态、键盘修饰键与系统光标。 |
| [`sdl.system`](sdl/system/index.md) | 应用元数据、路径与文件系统、SDL hint、时钟与日历时间、平台与电源信息。 |
