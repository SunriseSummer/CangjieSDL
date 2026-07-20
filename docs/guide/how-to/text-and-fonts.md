# 排版文字与选择字体

## 目标

基于[首个窗口](../getting-started/first-window.md)，加入右对齐数字、居中按钮标签、粗体标题和可选命名字体；度量与绘制使用完全相同的字符串、字号、样式和字体。完成后，中英文、数字和长文本都能得到可解释的对齐结果。

## 适用场景

适用于计算器读数、HUD、表格数值、按钮标签、标题和状态栏。系统 UI 字体适合普通工具，自带字体适合品牌或像素风，但要确保授权和字符覆盖。需要复杂段落换行、富文本或双向排版时，当前基础接口只提供单行绘制与度量，应用需建立更高层布局。

## 准备工作

先阅读[文字度量、字体与缓存](../concepts/text-font-cache.md)。保留首个窗口完整程序，在绘制阶段定义一次 `FontStyle`，并在 `textWidth` 与 `text` 中复用。若注册自定义字体，使用发布目录中的真实文件路径，并准备字体缺失时的系统回退视觉检查。

## 操作步骤

把下面片段放在场景绘制内部。`right` 是读数右边界，标题与读数使用不同层级；按钮标签用 `textCenter`，不再手算基线。这里先使用系统字体，因此 `font` 参数省略。

```cangjie role=patch
let titleStyle = FontStyle(bold: true)
renderer.text("本月用量", 64.0, 70.0, Color.rgb(191, 219, 254),
    pointSize: FontSizes.TITLE, style: titleStyle)

let value = "12,480"
let valueStyle = FontStyle(bold: true)
let valueWidth = renderer.textWidth(value, pointSize: FontSizes.DISPLAY, style: valueStyle)
let right: Float32 = width - 64.0
renderer.text(value, right - valueWidth, 118.0, Color.rgb(255, 255, 255),
    pointSize: FontSizes.DISPLAY, style: valueStyle)

let button = Rect(width - 184.0, height - 98.0, 120.0, 44.0)
renderer.fillRoundedRect(button, 10.0, Color.rgb(56, 189, 248))
renderer.textCenter("导出", button, Color.rgb(8, 47, 73),
    pointSize: FontSizes.CONTROL, style: FontStyle(bold: true))
```

长读数可先测 DISPLAY 宽度，超出可用范围后改用 TITLE 或自定义较小字号；不要只缩放绘制而继续使用旧度量。若需要字体名，先通过 `Fonts` 注册，再在度量和绘制中都传 `font: Some("brand")`。

## 确认结果

窗口应显示粗体标题、右对齐读数和居中按钮。把值换成 `"中文 12,480 ms"`，确认没有方框或切边；把窗口变窄，确认降级字号后仍在右边界内。调用同一测量两次并观察计数器时，measure 次数增加而 compute 不应重复增加，说明缓存命中。自定义字体路径故意写错一次，确认程序使用系统 UI 字体仍可读，并在日志中清楚记录回退。

## 常见错误

测量 regular、绘制 bold 会导致右对齐漂移；`textWidth` 使用默认字体、`text` 使用命名字体也会错。把 `textHeight` 当多行布局高度会让行间距不足。每帧注册字体或清空纹理缓存会造成不必要工作。headless 度量适合测试控制流，不应拿来承诺最终像素宽度；视觉验收必须在真实窗口中完成。

## 可以继续修改

加入带删除线的旋转状态标签，验证组合样式与旋转纹理缓存。下面变化使用不同绘制入口，肉眼应看到围绕指定中心旋转的文字。

```cangjie role=variation
let warningStyle = FontStyle(bold: true, italic: true, strikethrough: true)
renderer.textRotated("已过期", width - 120.0, 88.0, -12.0,
    Color.rgb(253, 186, 116), pointSize: FontSizes.TITLE, style: warningStyle)
```

## 相关 API

- [`Renderer`](../../api/sdl/Renderer.md)：文字度量、绘制、旋转、居中和缓存统计。
- [`FontStyle`](../../api/sdl/FontStyle.md)：文字样式组合。
- [`FontSizes`](../../api/sdl/FontSizes.md)：常用字号层级。
- [`Fonts`](../../api/sdl/Fonts.md)：命名字体注册。

## 下一步

继续[Surface、Texture 与图片](../concepts/surface-texture-image.md)，把文字之外的位图资源纳入同一场景和生命周期。
