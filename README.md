# CangjieSDL

CangjieSDL 是对 [SDL3](https://github.com/libsdl-org/SDL) 及其扩展组件的仓颉封装，提供核心图形及媒体接口，可用于桌面图形软件、数据可视化和游戏开发。

## 核心能力

- 窗口创建、状态控制、DPI 缩放、垂直同步与超采样抗锯齿。
- 线条、矩形、圆角矩形、圆、凸多边形、渐变、虚线边框和阴影。
- 不可变绘制命令缓冲、可替换的子命令槽和局部重绘，适合上层 GUI 框架实现增量绘制。
- 基于 SDL3_ttf 的 UTF-8 文本绘制、度量、居中、旋转和字体注册。
- 支持加载多种图像格式文件，支持表面与纹理、纹理三角带、图像变换等。
- 捕获键盘、鼠标、文本、滚轮、拖放与窗口事件。
- 剪贴板、系统光标、消息框、文件对话框、显示器与系统信息。

## 文档与示例

- [入门指南](docs/guide/index.md)
- [API 文档](docs/api/index.md)
- [示例应用](examples/)

## 环境要求

- Cangjie SDK `1.0.5`
- Windows/Mac/Linux
- [SDL-3.4.12](https://github.com/libsdl-org/SDL/releases/tag/release-3.4.12)/[SDL_ttf-3.2.2](https://github.com/libsdl-org/SDL_ttf/releases/tag/release-3.2.2)/[SDL_image-3.4.6](https://github.com/libsdl-org/SDL_image/releases/tag/release-3.4.6) 动态库，下载到 `.sdl3/` 目录。

执行单元测试，确认开发环境和项目可正常使用：

```shell
cjpm test
```

> [!NOTE]
>
> `Windows x64` 版本动态库已经预置到 `.sdl3/` 目录，在此平台本项目开箱即用。对于 Linux、Mac、Android 等平台，请在以上官方 Release 板块下载相关发布件，将动态库文件放到 `.sdl3/` 目录中。如果官方 Release 中没有匹配平台规格的发布件，可以用系统包管理工具安装（如 Mac 上执行 `brew install sdl3 sdl3_ttf sdl3_image`），或直接从 SDL 项目源码构建。

> [!IMPORTANT]
>
> 发布和部署基于 CangjieSDL 的软件时，请确保 SDL/SDL_ttf/SDL_image 动态库位于仓颉可执行文件目录，或在目标平台的动态库搜索路径中，即可以作为私有资产打包或在目标平台作为公共运行时安装。


## 快速开始

执行 `cjpm init` 新建仓颉项目，在 `cjpm.toml` 中配置依赖本包，然后在 `src/main.cj` 中写入代码：

```cangjie verify role=complete profile=gui-visual
package docexample

import sdl.{Color, Pen, Rect, SdlWindow, UiEvent, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("Hello CangjieSDL", 800, 600))) {
        var running = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case UiEvent.WindowCloseRequested => running = false
                    case _ => ()
                }
            }

            let renderer = window.renderer
            renderer.renderFrame(Float32(window.width), Float32(window.height), Color.rgb(15, 23, 42)) {
                renderer.strokeRoundedRect(
                    Rect(220.0, 180.0, 360.0, 180.0),
                    24.0,
                    Pen(width: 3.0, color: Color.rgb(46, 232, 159))
                )
                renderer.textCenter(
                    "Hello, CangjieSDL",
                    Rect(220.0, 180.0, 360.0, 180.0),
                    Color.rgb(255, 255, 255),
                    pointSize: 30.0
                )
            }
            window.delay(16)
        }
    }
}
```

执行 `cjpm run` 即可查看效果。
