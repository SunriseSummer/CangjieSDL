# 场景、逻辑坐标与高 DPI

## 先用一句话说明

应用用稳定的逻辑坐标做布局和命中，窗口与渲染器把它映射到显示器实际像素；`renderFrame`/`RenderPass` 还可用更高分辨率绘制后缩回窗口，以改善斜线和圆角边缘。

## 为什么重要

本页建立在[窗口与事件循环](window-events-lifecycle.md)之上：先保证每帧和缩放事件顺序正确，再讨论尺寸映射。

同一个 420×640 计算器在 100% 与 200% 系统缩放下，应用布局都应保持 420×640 的逻辑关系，但实际像素数量可能不同。若绘制用实际像素、命中测试却用逻辑坐标，鼠标会点偏；若字体和矩形分别乘不同缩放，文字会溢出；若窗口缩放后继续把 `beginScene` 设为旧尺寸，画面会被拉伸或裁掉。

`WindowSpec.scale` 是应用要求的逻辑缩放，非法的非正值会归一化为 1。`highDpi` 决定是否请求高像素密度窗口。`WindowDisplayMetrics` 明确分开四个量：`contentScale` 是应用逻辑单位到原生窗口坐标，`pixelDensity` 是原生坐标到后备像素，`renderScale` 是两者乘积，`displayScale` 是尚未叠加应用 zoom 的 SDL 显示缩放。`sizeInPixels()` 是实际像素尺寸，`width`/`height` 是当前逻辑尺寸；两者回答不同问题。

## 工作模型

先用逻辑坐标定义 `Rect`、`Point` 和 `Size`，事件中的鼠标坐标也按同一逻辑空间解释。每帧把当前逻辑宽高交给 `renderFrame`；它会成对执行 begin/resolve/present，并在绘制抛错时恢复目标、scale 和 clip 而不呈现残缺帧。需要分段截图或手工控制提交时，可使用 `beginRenderPass` 的资源块，或最低层的 `beginScene/endScene/present`。渲染器按 `supersample` 建立更大的离屏目标，在场景结束时解析回窗口。超采样改善几何边缘，但会增加像素工作量，不应把它当作布局缩放。

下面的对比把实际像素尺寸直接当布局尺寸，在高 DPI 屏上会让卡片逻辑上变大，并破坏事件坐标一致性。

```cangjie role=contrast
let pixels = window.sizeInPixels()
renderer.beginScene(Float32(pixels.width), Float32(pixels.height), background)
let button = Rect(40.0, 40.0, Float32(pixels.width) - 80.0, 64.0)
```

稳定做法以窗口逻辑尺寸构图，只把像素密度用于诊断或选择资源分辨率。

```cangjie role=trace
let logicalWidth = Float32(window.width)
let logicalHeight = Float32(window.height)
renderer.renderFrame(logicalWidth, logicalHeight, background) {
    let button = Rect(40.0, logicalHeight - 104.0, logicalWidth - 80.0, 64.0)
    renderer.fillRoundedRect(button, 12.0, accent)
}
```

## 选择与取舍

固定逻辑尺寸适合像素风游戏和简单工具，可把窗口设为不可调整大小；自适应布局适合桌面应用，应在每帧或尺寸变化时重算矩形。`supersample = 2` 是清晰度与性能的常见平衡；低端设备或大窗口可降为 1，高质量静态场景可评估更高值。垂直同步限制提交节奏，超采样决定内部绘制分辨率，它们互不替代。

图片资源需要另一个选择：若纹理本身分辨率低，超采样不会创造细节；应根据 `pixelDensity` 选择合适资源，再用逻辑目的矩形布局。文字由字体后端按字号绘制，仍要用同一字号测量和绘制，不要再手工乘设备缩放。

## 应用这个模型

标准的窗口 poll/wait API 会在尺寸、像素大小或显示缩放事件返回前刷新动态尺度，下一帧重新计算卡片、按钮和裁剪区；直接使用原生事件时才手工调用 `refreshDisplayMetrics()`。调试时一次打印逻辑尺寸、`sizeInPixels` 与 `WindowDisplayMetrics` 四个尺度：逻辑尺寸决定布局，像素尺寸证明设备输出，尺度分解可揭示是否把系统 DPI 与应用 zoom 重复相乘。命中错位时把鼠标坐标和按钮 `Rect` 放在同一日志中比较，通常比盲目乘除缩放更快。

截图由渲染输出像素生成，尺寸应和实际渲染目标一致；视觉验收同时记录图片宽高和 SHA-256。不同设备抗锯齿细节可能不同，但文字可读、布局不裁切、交互命中一致是稳定标准。

## 常见误解

“高 DPI 就是把所有坐标乘 2”是错误的；窗口和渲染器已经处理坐标映射。`displayScale` 也不是永远等于 `pixelDensity`，平台可分别报告内容缩放和像素密度。`beginScene` 不是普通 `clear` 的别名，它还管理超采样目标；若选择 `drawDirect` 或直接 `clear/present`，就要清楚自己放弃了哪部分场景处理。最后，不要在标准事件入口已自动刷新后再叠加一次自定义缩放。

## 相关 API

- [`WindowSpec`](../../api/sdl/WindowSpec.md)：高 DPI、逻辑缩放、垂直同步和超采样设置。
- [`SdlWindow`](../../api/sdl/SdlWindow.md)：逻辑尺寸、像素尺寸、密度与显示缩放。
- [`WindowDisplayMetrics`](../../api/sdl/WindowDisplayMetrics.md)：动态 DPI 的四个尺度。
- [`Renderer`](../../api/sdl/Renderer.md)：场景目标、缩放、视口、裁剪和提交。
- [`RenderPass`](../../api/sdl/RenderPass.md)：异常安全的 begin/end 场景边界。
- [`Rect`](../../api/sdl/Rect.md)：统一布局与命中的逻辑矩形。

## 下一步

进入[绘制图形与布局](../how-to/draw-shapes-and-layout.md)，把这个坐标模型应用到卡片、按钮、渐变和裁剪。
