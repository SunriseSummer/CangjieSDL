# 无窗口测试与渲染计数

## 目标

基于[平台诊断工具](../tutorials/platform-toolbox.md)，使用 `Renderer.headless()` 验证布局、裁剪栈、默认查询值和文字缓存控制流，并明确哪些结论必须由真实窗口截图补足。完成后，自动测试不会把 headless 的确定性替代值冒充成字体或 GPU 视觉结果。

## 适用场景

适用于 CI、无显示终端、快速单元测试和回归定位。headless 渲染入口是无操作，查询返回中性值，文字宽高使用确定性替代算法；它能验证代码路径与状态栈，不验证系统字体、抗锯齿、纹理像素、显示器缩放或真实截图。GUI 发布仍需桌面环境中的人工或自动捕获。

## 准备工作

先把业务布局写成接收宽高并返回 Rect 的纯函数；把渲染函数接收 Renderer，不在内部创建窗口。这样测试可传 headless，应用传真实 Renderer。每条测试写明证据类型：编译、执行断言、人工观察或真实图像，不使用模糊的“已验证”。

## 操作步骤

在平台教程完整程序中加入一个无窗口自检。headless 下所有绘制调用应安全无操作，裁剪栈仍按逻辑维护，文字重复度量可通过计数器观察。下面片段执行后以打印和退出码确认。

```cangjie role=patch
let renderer = Renderer.headless()
renderer.beginScene(640.0, 360.0, Color.rgb(0, 0, 0))
renderer.pushClip(Rect(20.0, 20.0, 200.0, 80.0))
renderer.text("缓存测试", 28.0, 36.0, Color.rgb(255, 255, 255))
match (renderer.currentClip()) {
    case Some(rect) => println("clip=${rect.w}x${rect.h}")
    case None => throw CuiException("裁剪栈为空")
}
renderer.popClip()
renderer.endScene()
renderer.present()
println("vsync=${renderer.vsync()}")
```

真实测试还应调用纯布局函数并断言矩形不越界。若无头查询返回 viewport 零矩形、colorScale 1.0、vsync 0，这是契约的中性值，不代表真实设备。

## 确认结果

程序无需打开窗口，退出码为 0，打印的裁剪宽高是 200×80，pop 后 currentClip 为 None，vsync 为 0。相同输入多次运行输出一致。随后在真实窗口运行同一绘制函数并截图，确认字体、颜色、边缘和裁剪实际正确；两类证据都通过才覆盖完整能力。CI 若没有 GUI，应明确标记视觉步骤未在该节点执行，而不是写 PASS。

## 常见错误

把 headless 的文字宽度用于像素级黄金图会得到虚假稳定；调用 `captureBmp` 无操作也不会生成真实图片。只测 draw 不测纯布局会错过负尺寸。计数器只说明调用和缓存行为，不说明文字可读。自动构建通过与真实窗口能创建是两层门禁，部署前都要执行。

## 可以继续修改

重置文字计数器，重复测量同一字符串，再测量不同样式；确认 compute 对相同键只增加一次，对粗体键再次增加。

```cangjie role=variation
renderer.resetTextMeasureCount()
let plain1 = renderer.textWidth("状态", pointSize: FontSizes.BODY)
let plain2 = renderer.textWidth("状态", pointSize: FontSizes.BODY)
let bold = renderer.textWidth("状态", pointSize: FontSizes.BODY, style: FontStyle(bold: true))
println("measure=${renderer.textMeasureCount()}, compute=${renderer.textComputeCount()}")
println("widths=${plain1},${plain2},${bold}")
```

## 相关 API

- [`Renderer`](../../api/sdl/Renderer.md)：headless、裁剪、查询和文字计数器。
- [`Rect`](../../api/sdl/Rect.md)：纯布局与边界断言。
- [`FontStyle`](../../api/sdl/FontStyle.md)：区分缓存键的样式。
- [`CuiException`](../../api/sdl/CuiException.md)：自检失败的明确错误。

## 下一步

进入[构建、动态库与字体排错](../troubleshooting/build-runtime-fonts.md)，把这些最小探针用于真实失败定位。
