# 构建、动态库与字体排错

## 先看现象

本页按失败阶段区分三类问题：编译器找不到 `sdl`，程序启动时找不到 SDL3/SDL3_ttf，窗口创建时字体后端失败。不要同时修改依赖路径、DLL 和字体设置；先用最小探针确定边界，再恢复完整 GUI。每个分支都要求实际命令、退出码和可观察结果。

## 可能原因

编译期通常是 `cjpm.toml` 路径、包名或工具链版本；进程启动前的加载错误通常是 DLL 名称、架构或搜索路径；进入 `SdlWindow` 构造后才出现的文字错误通常是 SDL3_ttf、系统字体候选或自定义字体路径。无显示环境也会让窗口失败，但平台命令行探针仍可能成功。

## 诊断步骤

### 症状一：`import sdl` 无法解析或构建失败

在应用目录运行 `cjpm build`，检查错误是否发生在依赖解析。核对依赖路径最终指向含 `sdl/cjpm.toml` 的目录，而不是 `src` 或 `.sdl3`。把程序缩成下面探针，只调用包级版本函数；若仍不能编译，问题与窗口、字体和显示器无关。确认标准是构建退出码为 0，运行能打印正版本值。

```cangjie role=probe
package guide_examples

import sdl.{sdlRevision, sdlVersion}

main(): Unit {
    println("version=${sdlVersion()}")
    println("revision=${sdlRevision()}")
}
```

依赖修复后，用完整窗口烟雾帧代替只导入探针，确保核心类型和渲染入口能解析。这个修复程序仍只画一帧并立即释放，便于把运行库问题和长期事件循环分开。确认退出码为 0，并在桌面短暂看到窗口。

```cangjie role=fix
package guide_examples

import sdl.{Color, SdlWindow, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("运行时探针", 360, 220))) {
        window.renderer.beginScene(360.0, 220.0, Color.rgb(15, 23, 42))
        window.renderer.endScene()
        window.renderer.present()
        window.delay(UInt32(250))
    }
}
```

### 症状二：编译成功，启动提示找不到 DLL 或架构不匹配

记录完整加载错误和实际启动目录，检查发布目录是否同时存在 `SDL3.dll` 与 `SDL3_ttf.dll`，不要只看仓库 `.sdl3`。比较 exe 与 DLL 架构，确认没有把链接用的 `libSDL3.dll` 当运行时文件。临时从干净目录启动，避免开发 PATH 提供隐形成功。恢复正确 DLL 后复测版本探针和一帧窗口，确认两者退出码都为 0；仅版本探针成功还不能证明文字后端可用。

### 症状三：窗口构造时报找不到字体、TTF 初始化或文字为空

先确认 `SDL3_ttf.dll` 与 SDL3 版本配套，再检查当前系统是否有支持的 UI 字体。Windows 通常有 Microsoft YaHei UI 或 Segoe UI，精简镜像可能没有；Linux 容器通常需要安装 Noto Sans CJK 或 DejaVu Sans。运行仓库 `font_test` 与 `bold_companion_test`，记录失败点。恢复字体后用中英文、数字和粗体实际绘制，确认没有方框、空白和切边；只让窗口创建成功不足以证明文字可读。

## 修复方法

依赖错误只修真实项目路径和工具链兼容性；不要把 SDL 源码复制进应用。运行库错误把正确架构的两个 DLL 放在 exe 同目录或受控搜索路径。字体错误安装受支持字体或随应用分发有授权的字体，并保留系统回退。每次只改一层，重跑相应最小探针，再回到完整首个窗口。

## 确认已经修复

依次确认：`cjpm build` 退出码 0；版本探针运行并打印非零版本；一帧窗口真实显示；中英文与粗体可读；完整[首个窗口](../getting-started/first-window.md)可调整大小并正常关闭。记录命令、工作目录、DLL 哈希、字体环境和截图，另一台机器应能复现。

## 避免再次发生

仓库保留命令行版本探针、无窗口逻辑测试和真实 GUI 冒烟测试三层门禁。发布产物固定两个 DLL 的来源与哈希，不依赖全局 PATH。容器或精简镜像明确安装字体。升级工具链或 SDL 后先跑探针，再跑 API 示例和指南视觉示例，避免把旧证据沿用到新二进制。

## 相关 API

- [`CuiException`](../../api/sdl/CuiException.md)：原生失败转换后的异常。
- [`SdlWindow`](../../api/sdl/SdlWindow.md)：窗口与字体后端初始化边界。
- [`Fonts`](../../api/sdl/Fonts.md)：应用字体注册。
- [`sdl` 包](../../api/sdl/index.md)：版本与包级入口。

## 下一步

程序能启动但画面空白、模糊或截图异常时，继续[渲染与截图排错](render-output.md)。
