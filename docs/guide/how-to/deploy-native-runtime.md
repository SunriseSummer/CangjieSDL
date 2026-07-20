# 部署 SDL 原生运行库

## 目标

基于[平台诊断工具](../tutorials/platform-toolbox.md)，构建 Windows 发布目录，使可执行文件在没有仓库工作目录和全局 DLL 路径的干净位置仍能运行。最终目录包含应用、`SDL3.dll` 与 `SDL3_ttf.dll`，并记录架构、版本、启动命令和退出码。

## 适用场景

适用于把桌面工具或游戏交给另一台 Windows 机器、制作压缩包、安装程序或 CI 产物。开发期 `cjpm run` 能找到库，不代表复制出的 exe 能找到；链接阶段的 `libSDL3.dll` 名称与运行时 `SDL3.dll` 也不是同一个用途。macOS/Linux 需要目标平台匹配的动态库与 `[ffi.c]` 配置，本页不假装 Windows 文件可跨平台使用。

## 准备工作

确认 `sdl/cjpm.toml` 的 `[ffi.c]` 指向 `.sdl3`，并检查应用与 DLL 都是 x86_64 Windows 架构。先运行平台探针，再构建 GUI 应用。发布测试使用新建的明确子目录，不修改系统全局 PATH，也不依赖开发机已经安装的 SDL。

## 操作步骤

发布布局应保持简单：

```text
release/
├─ app.exe
├─ SDL3.dll
└─ SDL3_ttf.dll
```

构建后把可执行文件和两个运行时 DLL 复制到同一目录。以下 PowerShell 命令中的源路径按真实产物调整；执行前先确认目标是专用发布目录。

```powershell
cjpm build --release
New-Item -ItemType Directory -Force .\release
Copy-Item .\target\release\bin\app.exe .\release\
Copy-Item ..\sdl\.sdl3\SDL3.dll, ..\sdl\.sdl3\SDL3_ttf.dll .\release\
```

在应用启动最前面保留简短版本探针，便于用户报告环境。它基于平台教程的完整程序增加 SDL 版本，不替代真实窗口测试。

```cangjie role=patch
import sdl.{sdlRevision, sdlVersion}

println("sdlVersion=${sdlVersion()}")
println("sdlRevision=${sdlRevision()}")
println("platform=${platformName()}")
```

复制完成后，从 `release` 目录直接运行，记录标准输出和退出码。GUI 应用还要实际打开窗口、显示文字并关闭，才能同时验证 SDL3、SDL3_ttf、显示环境与字体。

## 确认结果

临时移除开发 PATH 中 `.sdl3` 后，发布目录里的程序仍能启动；平台探针退出码为 0，GUI 窗口真实可见，中文正常，关闭后返回。删除测试副本中的任一 DLL 应产生可解释的加载失败，再恢复 DLL 后复测通过。记录三个文件大小与 SHA-256，确保打包过程没有拿错架构或旧版本。

## 常见错误

只复制 `libSDL3.dll` 而缺少运行时名 `SDL3.dll` 会启动失败；只带 SDL3 不带 SDL3_ttf 会在文字后端初始化时失败。依赖开发机全局 PATH 会让测试产生假通过。32/64 位混用通常表现为无法加载而不是仓颉源码错误。精简系统镜像可能没有受支持字体，即使两个 DLL 都存在也要单独验证文字。

## 可以继续修改

为诊断模式打印 Renderer 驱动名和像素密度，但只在成功创建窗口后执行。这个变化能区分“DLL 加载成功”和“真实渲染器建立成功”。

```cangjie role=variation
try (window = SdlWindow(WindowSpec("部署探针", 480, 280))) {
    println("renderer=${window.renderer.driverName()}")
    println("pixelDensity=${window.pixelDensity()}")
    runVisibleSmokeFrame(window)
}
```

## 相关 API

- [`sdl` 包](../../api/sdl/index.md)：版本函数和核心运行时。
- [`SdlWindow`](../../api/sdl/SdlWindow.md)：真实窗口与渲染器探针。
- [`Renderer`](../../api/sdl/Renderer.md)：驱动名和场景提交。
- [部署与 FFI 源文档](../../../../../sdl/docs/deployment-and-ffi.md)：仓库原生库布局与 ABI 边界。

## 下一步

继续[无窗口测试与渲染计数](test-headless-and-instrument.md)，建立部署前可快速运行的逻辑门禁，同时保留 GUI 截图门禁。
