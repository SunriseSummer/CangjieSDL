# 场景、逻辑坐标与高 DPI

## 先用一句话说明

应用用稳定的逻辑坐标做布局和命中，窗口与渲染器把它映射到显示器实际像素；`renderFrame`/`RenderPass` 还可用更高分辨率绘制后缩回窗口，以改善斜线和圆角边缘。

## 为什么重要

本页建立在[窗口与事件循环](window-events-lifecycle.md)之上：先保证每帧和缩放事件顺序正确，再讨论尺寸映射。

同一个 420×640 计算器在 100% 与 200% 系统缩放下，应用布局都应保持 420×640 的逻辑关系，但实际像素数量可能不同。若绘制用实际像素、命中测试却用逻辑坐标，鼠标会点偏；若字体和矩形分别乘不同缩放，文字会溢出；若窗口缩放后继续把 `beginScene` 设为旧尺寸，画面会被拉伸或裁掉。

`WindowSpec.scale` 是应用要求的逻辑缩放，非正值按 1 处理；`highDpi` 决定是否请求高像素密度窗口。`WindowDisplayMetrics` 分开记录四个量：`contentScale` 表示逻辑单位到窗口坐标，`pixelDensity` 表示窗口坐标到后备像素，`renderScale` 是两者乘积，`displayScale` 是尚未叠加应用缩放的 SDL 建议值。`sizeInPixels()` 返回实际像素尺寸，`width` 和 `height` 返回逻辑尺寸。

## 工作模型

先用逻辑坐标定义 `Rect`、`Point` 和 `Size`，鼠标事件也使用同一坐标空间。每帧把当前逻辑宽高交给 `renderFrame`；它会完成场景开始、离屏解析和提交，并在绘制抛错时恢复渲染状态。需要在场景结束后、提交前截图时，可使用 `beginRenderPass`；只有需要完全控制边界时才直接调用 `beginScene`、`endScene` 和 `present`。超采样会增加内部绘制像素，但不会改变布局尺寸。

整个 `Renderer` 状态，包括无窗口查询、诊断计数、命令录制和 `RenderPass`，都绑定创建它的仓颉线程。后台线程可以准备模型或布局输入，但查询和调用渲染 API 必须回到创建线程。这样渲染目标、裁剪、字体缓存、命令版本和资源生命周期始终按一个顺序变化。

布局应读取 `window.width` 和 `window.height`，并把它们传给 `renderFrame`。`sizeInPixels()` 只用于诊断或选择图片分辨率；若用它创建布局矩形，高 DPI 屏上的界面会在逻辑坐标中被重复放大，鼠标命中也会偏移。

## 选择与取舍

固定逻辑尺寸适合像素风游戏和简单工具；自适应桌面应用应在尺寸变化后重新计算布局。默认 `supersample = 0` 表示自动选择：物理密度低于 2 像素/逻辑单位时尝试 2 倍，否则直接绘制。自动方案还受 32 Mi 个目标像素和硬件最大纹理边长限制，避免超大窗口申请过多显存。显式正数表示固定请求，`1` 为关闭；它不受框架像素预算限制，但仍受算术、硬件和实际分配能力限制。垂直同步控制提交节奏，超采样控制内部绘制分辨率，两者用途不同。

`renderer.renderSamplingStats()` 可解释当前选择：`targetWidth × targetHeight` 是计划像素数，`estimatedTargetBytes` 是 RGBA8 内存估算，`status` 给出直接绘制、预算限制、硬件限制或分配失败等原因。低分辨率图片不会因超采样获得新细节；仍应根据 `pixelDensity` 选择资源，再用逻辑矩形布局。

## 应用这个模型

标准的事件轮询和等待方法会在返回尺寸、像素大小或显示缩放事件前刷新动态尺度，下一帧再计算布局。只有直接处理原生事件时才手工调用 `refreshDisplayMetrics()`。调试时同时打印逻辑尺寸、`sizeInPixels()` 和 `WindowDisplayMetrics`：逻辑尺寸决定布局，像素尺寸描述输出，四个尺度可以发现系统 DPI 与应用缩放是否被重复计算。

截图由渲染输出像素生成，尺寸应和实际渲染目标一致；视觉验收同时记录图片宽高和 SHA-256。不同设备抗锯齿细节可能不同，但文字可读、布局不裁切、交互命中一致是稳定标准。

## 常见误解

“高 DPI 就是把所有坐标乘 2”并不正确，窗口和渲染器已经处理坐标映射。`displayScale` 也不一定等于 `pixelDensity`，因为平台可以分别报告内容缩放和像素密度。`beginScene` 还负责超采样目标，不是普通的清屏方法；不要在标准事件入口已经刷新尺度后再叠加一次自定义换算。

## 相关 API

- [`WindowSpec`](../../api/sdl/WindowSpec.md)：高 DPI、逻辑缩放、垂直同步和超采样设置。
- [`SdlWindow`](../../api/sdl/SdlWindow.md)：逻辑尺寸、像素尺寸、密度与显示缩放。
- [`WindowDisplayMetrics`](../../api/sdl/WindowDisplayMetrics.md)：动态 DPI 的四个尺度。
- [`Renderer`](../../api/sdl/Renderer.md)：场景目标、缩放、视口、裁剪和提交。
- [`RenderPass`](../../api/sdl/RenderPass.md)：异常安全的 begin/end 场景边界。
- [`Rect`](../../api/sdl/Rect.md)：统一布局与命中的逻辑矩形。

## 下一步

进入[绘制图形与布局](../how-to/draw-shapes-and-layout.md)，把这个坐标模型应用到卡片、按钮、渐变和裁剪。
