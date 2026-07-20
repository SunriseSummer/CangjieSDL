# 仓颉跨平台图形接口库

CangjieSDL 是对跨平台多媒体库 [SDL](https://github.com/libsdl-org) 的轻量安全封装，当前聚焦于图形接口，提供窗口、GPU 二维绘制、纹理管理、文本、事件、剪贴板、原生对话框、显示器查询和系统设施等。可用于开发图形软件、数据可视化与 2D 游戏等。

## 核心能力

- 窗口创建、状态控制、DPI 缩放、垂直同步与超采样抗锯齿。
- 线条、矩形、圆角矩形、圆、凸多边形、渐变、虚线边框和阴影。
- 基于 SDL3_ttf 的 UTF-8 文本绘制、度量、居中、旋转和字体注册。
- BMP/PNG 表面与纹理、旋转/镜像绘制、纹理三角带。
- 捕获键盘、鼠标、文本、滚轮、拖放与窗口事件。
- 剪贴板、系统光标、消息框、文件对话框、显示器与系统信息。

## 文档与示例

- [入门指南](docs/guide/index.md)
- [API 手册](docs/api/index.md)
- [示例应用](examples/)

## 环境要求

- Cangjie SDK `1.0.5`
- Windows/Mac/Linux
- [SDL-3.4.12](https://github.com/libsdl-org/SDL/releases/tag/release-3.4.12) 与 [SDL_ttf-3.2.2](https://github.com/libsdl-org/SDL_ttf/releases/tag/release-3.2.2) 动态库，放到 `.sdl3/` 目录。

执行单元测试，确认开发环境和项目可正常使用：

```shell
cjpm test
```

> [!NOTE]
>
> `Windows x64` 版本动态库已经预置到 `.sdl3/` 目录，在此平台本项目开箱即用。对于 Linux、Mac、Android 等平台，请在 SDL/SDL_ttf 项目官方 Release 板块下载相关发布件，解压后将动态库文件放到 `.sdl3/` 目录中。如果官方 Release 中没有匹配平台规格的发布件，可以用系统包管理工具安装（如 Mac 上执行 `brew install sdl3 sdl3_ttf`），或直接从 SDL 项目源码构建。

> [!IMPORTANT]
>
> 发布和部署基于 CangjieSDL 的软件时，请确保 SDL 和 SDL_ttf 动态库位于仓颉可执行文件目录，或在目标平台的动态库搜索路径中，即可以作为私有资产打包或在目标平台作为公共运行时安装。


## 快速开始

执行 `cjpm init` 新建仓颉项目，在 `cjpm.toml` 中配置依赖本包，然后在 `src/main.cj` 中写入代码：

```cangjie
import sdl.{Color, Pen, Rect, SdlWindow, UiEvent, WindowSpec}

main() {
    try (window = SdlWindow(WindowSpec("Hello CangjieSDL", 800, 600))) {
        var running = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit => running = false
                    case _ => ()
                }
            }

            let renderer = window.renderer
            renderer.beginScene(800.0, 600.0, Color.rgb(15, 23, 42))
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
            renderer.endScene()
            renderer.present()
            window.delay(16)
        }
    }
}
```

执行 `cjpm run` 即可运行查看效果。这段代码创建了一个深色背景窗口，并在中间绘制一个绿色圆角矩形边框，内部呈现白色文字“Hello，CangjieSDL”。每帧都执行动作 `beginScene → 绘制 → endScene → present` 。`SdlWindow` 实现了仓颉预定义的 `Resource` 资源管理接口，结合 `try-with-resources` 语法糖使用，在正常退出和异常路径下都能自动释放窗口及渲染资源。

## 许可证

本项目采用 [MIT License](LICENSE)。
