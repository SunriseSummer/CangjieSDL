# 部署 SDL 原生运行库

目标是在不依赖源码目录的环境中启动应用，正确显示文字与图像，并正常关闭。开发时 `cjpm run` 成功，只能证明当前开发环境可用。

## 开发目录与运行目录

`CangjieSDL/cjpm.toml` 将 SDL3、SDL3_ttf、SDL3_image 的 FFI 链接目录设为 `.sdl3/`。Windows 的 `libSDL3*.dll` 是构建用名称；发布时必须提供加载器使用的运行时名称。

| 用途 | Windows x64 文件 |
|---|---|
| 窗口、输入与渲染 | `SDL3.dll` |
| 字体与文字 | `SDL3_ttf.dll` |
| 静态图像 | `SDL3_image.dll` |

三个库都是当前 `[ffi.c]` 声明的依赖。不要沿用只部署 SDL3 与 SDL3_ttf 的旧清单。仓库版本见[环境要求](../../../README.md#环境要求)；库及应用必须匹配目标架构。

## 建立 Windows 发布目录

沿用入门教程的同级目录布局，在应用目录运行：

```powershell
cjpm build
New-Item -ItemType Directory -Force target/package | Out-Null
Copy-Item -LiteralPath target/release/bin/main.exe -Destination target/package/
$sdlRuntime = (Resolve-Path ../CangjieSDL/.sdl3).Path
Copy-Item -LiteralPath "$sdlRuntime/SDL3.dll", "$sdlRuntime/SDL3_ttf.dll", "$sdlRuntime/SDL3_image.dll" -Destination target/package/
```

`main.exe` 是默认产物名，若应用配置改变了输出名，应使用实际构建产物。随后复制程序读取的 `assets/`、配置、字体和许可证，保留应用约定的目录结构。仓颉运行时及原生库的传递依赖也须按所用 SDK、构建方式和目标系统补齐。

```text
target/package/
├─ main.exe
├─ SDL3.dll
├─ SDL3_ttf.dll
├─ SDL3_image.dll
├─ assets/           # 应用实际需要的图像、字体等
└─ licenses/         # 随分发组件的许可证
```

常见静态图像由预置 SDL3_image 处理；WebP、TIFF、AVIF、JPEG XL 的支持取决于构建选项及额外解码库。只交付产品实际需要并验收过的解码器，不能用开发机上的可选库替代发布依赖。

## 在干净环境验收

从发布目录直接启动可执行文件，确认测试环境没有通过开发 `PATH` 或源码目录提供遗漏的库和资源。优先在独立测试机或干净系统镜像中执行。

依次检查窗口创建、中文与拉丁文字、一张产品使用格式的图片、输入和正常关闭。需要诊断时记录 `sdlVersion()`、`imageVersion()`、`platformName()`、渲染器 `driverName()` 及实际加载文件的版本与哈希。截图应在场景结束后、`present()` 之前采集，见[图片与截图](images-textures-screenshot.md)。

加载失败先检查文件名、架构和传递依赖；图片失败再检查编解码器及资源路径；文字失败再检查字体配置。版本函数可运行不等于窗口、字体和 GPU 都可用。

## Linux 与 macOS

准备目标平台的 SDL3、SDL3_ttf、SDL3_image 共享库及依赖，并使 `[ffi.c]` 能在构建时找到它们。Linux 还需正确配置运行时搜索路径或安装路径；macOS 需处理动态库安装名、运行路径和应用包布局。Windows DLL 不能用于这两个平台。

字体发现分别使用 Linux fontconfig 和 macOS CoreText。窗口系统、输入法、对话框及 GPU 后端应在目标系统验收；本地构建不能代替这些检查。

使用 CUI 的应用还需考虑 Windows UI Automation 桥，见 [CUI 打包指南](../../../../CangjieGUI/docs/guide/how-to/package-desktop-app.md)。

参见 [`SdlWindow`](../../api/sdl/SdlWindow.md)、[`Renderer`](../../api/sdl/Renderer.md) 和[构建与运行排错](../troubleshooting/build-runtime-fonts.md)。
