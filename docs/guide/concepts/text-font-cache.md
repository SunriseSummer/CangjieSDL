# 文字度量、字体与缓存

## 先用一句话说明

文字布局必须用与绘制完全相同的字体、字号和样式测量；渲染器会缓存度量与重复文字纹理，字体路径无效时回退到受支持的系统 UI 字体。

## 为什么重要

文字排版沿用[场景、逻辑坐标与高 DPI](render-scene-coordinates.md)的逻辑空间；设备像素缩放不应由应用再手工乘进字号。

按钮居中、读数右对齐和省略号都依赖真实文字宽度。把“每个字符 8 像素”写死，对英文也不准确，对中文、粗体和混合脚本更会明显错位。`textWidth`、`textHeight`、`textCenter` 和 `text` 使用同一个 SDL3_ttf 后端，只有参数一致，测量结果才代表最终画面。

默认字体从平台常见 UI 字体中选择；没有任何受支持字体时，窗口初始化会失败并报告错误，而不是悄悄使用难以阅读的位图字。应用可通过 `Fonts.register` 等入口给名字绑定字体文件；路径打不开时，渲染器会记住失败并回退，避免每帧重复尝试。粗体优先查找同家族粗体文件，没有时再使用合成效果。

## 工作模型

一次文字请求由四个关键参数决定：字符串、字号、`FontStyle` 和字体名或路径。度量缓存按这些条件分开，普通与粗体不会误用同一宽度；旋转文字还会缓存可复用纹理。`textMeasureCount` 记录度量调用，`textComputeCount` 记录真正计算次数，`textShapeCount` 与 `textDrawCount` 帮助区分重复布局和重复绘制。

下面的对比用默认样式测量，却用粗体绘制，右边界会漂移。

```cangjie role=contrast
let width = renderer.textWidth(value, pointSize: FontSizes.DISPLAY)
renderer.text(value, right - width, y, color,
    pointSize: FontSizes.DISPLAY, style: FontStyle(bold: true))
```

正确做法先保存同一个样式，并在度量与绘制中重复使用。

```cangjie role=trace
let style = FontStyle(bold: true)
let width = renderer.textWidth(value, pointSize: FontSizes.DISPLAY, style: style, font: Some("ui"))
renderer.text(value, right - width, y, color,
    pointSize: FontSizes.DISPLAY, style: style, font: Some("ui"))
```

## 选择与取舍

系统 UI 字体减少分发负担，适合普通桌面工具；应用自带字体能保持品牌一致，但要确认授权、文件路径、CJK 覆盖和发布目录。统一使用 `FontSizes` 的 CAPTION、BODY、CONTROL、TITLE、DISPLAY 有助于形成层级；特殊标题可用自定义字号，但不要让每个控件随意发明一个值。

缓存适合重复 HUD、按钮标签和静态标题。不断生成带时间戳的长字符串会降低命中率；此时应先判断是否真的需要每帧更新。`clearTextTextureCache` 能释放旋转文字等纹理缓存，但频繁清空会抵消缓存收益。headless 渲染器的文字度量是确定性替代值，适合结构测试，不代表真实字体像素或最终宽度。

## 应用这个模型

计算器先用 DISPLAY 测量读数，超出面板宽度才切换到较小字号；右对齐函数把测得宽度从右边界减去。游戏 HUD 的分数变化频繁，但标签固定，可以把固定标签与数值分开绘制。调试缓存时先重置计数器，重复调用同一测量，再比较 measure 与 compute：前者增加而后者不重复增加，说明缓存命中。

视觉验收至少覆盖中文、拉丁字母、数字、粗体和一个长字符串。确认没有方框、上下切边、错误重叠或明显基线跳动。自定义字体失败时记录实际文件路径和回退后的可见结果，不要只验证注册调用没有抛错。

## 常见误解

`textHeight` 不是每个具体字符串的包围盒，它按字号和字体提供稳定高度；多行文本仍需应用决定行距与换行。粗体并不保证总是有独立粗体文件，系统可能使用合成。注册字体名字后也不能删除字体文件再期待后续首次加载成功。最后，headless 下测量通过只能证明布局代码可执行，不能证明中文字体可用或视觉对齐正确。

## 相关 API

- [`Renderer`](../../api/sdl/Renderer.md)：文字绘制、度量、缓存清理与计数器。
- [`FontStyle`](../../api/sdl/FontStyle.md)：粗体、斜体、下划线和删除线组合。
- [`FontSizes`](../../api/sdl/FontSizes.md)：常用文字层级。
- [`Fonts`](../../api/sdl/Fonts.md)：命名字体注册与查询。

## 下一步

进入[文字与字体 how-to](../how-to/text-and-fonts.md)，给首个窗口加入右对齐读数、样式文字和字体回退确认。
