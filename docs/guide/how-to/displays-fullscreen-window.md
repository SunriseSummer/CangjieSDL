# 查询显示器、控制窗口并切换全屏

## 目标

基于[首个窗口](../getting-started/first-window.md)，读取当前主显示器、像素密度和刷新率，设置最小尺寸与宽高比，并在用户请求时切换全屏。全屏模式来自当前显示器实际枚举，不把显示器 ID 或分辨率永久写进配置。

## 适用场景

适用于游戏、演示、视频工具、多显示器工作台和需要窗口进度状态的桌面应用。普通工具通常只需可调整窗口和最小尺寸；独占模式选择只有在确实需要固定分辨率或刷新率时才值得增加复杂度。平台不支持的窗口能力可能抛出 `CuiException`，调用方应提供可恢复路径。

## 准备工作

确认首个窗口已处理 `WindowResized`，并在普通桌面会话运行。记录切换前窗口位置和尺寸，保证退出全屏能恢复。显示器 ID 由 SDL 管理，只在当前运行中使用；设备插拔后重新查询 `allDisplayInfos()`。

## 操作步骤

窗口创建后先设置最小尺寸和宽高比，再打印显示信息。按 F 的具体物理键可用 `Key.Letter(UInt8(70))` 匹配；切换失败时捕获并显示错误，不要让应用丢失退出能力。

```cangjie role=patch
window.setMinimumSize(640, 360)
window.setAspectRatio(16.0 / 10.0, 16.0 / 9.0)
let display = primaryDisplayInfo()
println("display=${display.name}")
match (display.modes.current) {
    case Some(mode) => println("mode=${mode.width}x${mode.height}@${mode.refreshRate}")
    case None => println("current mode unavailable")
}

case UiEvent.KeyDown(Key.Letter(code), false) =>
    if (code == UInt8(70)) {
        fullscreen = !fullscreen
        window.setFullscreen(fullscreen)
        window.sync()
    }
```

窗口运行时可查询 `pixelDensity()`、`displayScale()`、`safeArea()` 和 flags 解释设备状态。设置透明度、置顶、边框或进度条时，只在业务需要时调用，并提供恢复操作。

## 确认结果

终端打印真实显示器名和当前模式，宽高与系统设置相符。窗口不能缩到 640×360 以下，拖动时宽高比保持设定范围。按 F 进入全屏，再按一次恢复，原窗口仍可移动和关闭；多显示器环境将窗口移到另一屏后重新查询，结果应对应当前位置或明确使用主显示器。切换失败时程序继续响应并显示错误，而不是停在黑屏。

## 常见错误

把显示器 ID 保存到下次运行会引用错误设备；硬编码 1920×1080 忽略实际支持模式和高密度模式。把 `sizeInPixels` 当逻辑布局尺寸会导致高 DPI 错位。只进入全屏、不保留恢复路径会增加用户风险。`setAlwaysOnTop`、透明度和输入抓取具有明显副作用，调试结束应恢复。

## 可以继续修改

枚举当前显示器全屏模式，并选择最接近 1280×720、60Hz 的模式；没有结果时保留桌面全屏，不把 None 当成异常。

```cangjie role=variation
let request = FullscreenModeRequest(1280, 720, refreshRate: 60.0, includeHighDensityModes: true)
match (closestFullscreenDisplayMode(display.id, request)) {
    case Some(mode) => status = "候选 ${mode.width}x${mode.height}@${mode.refreshRate}"
    case None => status = "没有匹配模式，保留桌面全屏"
}
```

## 相关 API

- [显示器函数](../../api/sdl/displays/functions.md)：枚举、查询和匹配模式。
- [`DisplayInfo`](../../api/sdl/displays/DisplayInfo.md) 与 [`DisplayMode`](../../api/sdl/displays/DisplayMode.md)：设备快照。
- [`FullscreenModeRequest`](../../api/sdl/displays/FullscreenModeRequest.md)：模式匹配条件。
- [`SdlWindow`](../../api/sdl/SdlWindow.md)：窗口状态、全屏、密度与进度。
- [`WindowFlags`](../../api/sdl/WindowFlags.md)：读取当前窗口状态位。

## 下一步

继续[应用元数据与 SDL Hints](hints-and-metadata.md)，把必须在窗口初始化前设置的选项放到正确位置。
