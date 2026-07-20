# 绘制图形与自适应布局

## 目标

在[首个窗口](../getting-started/first-window.md)的完整程序上，把单一卡片扩展为标题栏、内容区和底部按钮；使用圆角渐变、描边、软阴影与裁剪，同时让窗口缩放后布局仍保持合理边距。完成后，鼠标命中可直接复用绘制时的 `Rect`，不会另算一套坐标。

## 适用场景

适用于自绘工具栏、仪表板、游戏 HUD、设置面板和轻量控件。若应用需要标准辅助功能、复杂表单或系统主题控件，直接自绘会承担键盘导航和可访问性成本，应评估上层 UI 框架。本页专注可控的图形界面，不讨论图片与纹理。

## 准备工作

保留首个窗口的事件循环、`beginScene/endScene/present` 和 try-with-resources，只替换场景内部的布局与绘制。确认 `WindowResized` 已调用 `refreshSize()`。先给每个区域算出一个具名 Rect，再绘制；不要在绘制和事件代码中分别散落相同数字。

## 操作步骤

在 `beginScene` 后、`endScene` 前替换原卡片绘制。外层 `shell` 随当前逻辑尺寸变化，标题栏和按钮从它派生。`pushClip/popClip` 只限制内容区，按钮在裁剪外仍完整可见。软阴影放在卡片之前，描边放在填充之后。

```cangjie role=patch
let shell = Rect(28.0, 28.0, width - 56.0, height - 56.0)
let header = Rect(shell.x, shell.y, shell.w, 72.0)
let content = Rect(shell.x + 24.0, shell.y + 94.0, shell.w - 48.0, shell.h - 182.0)
let action = Rect(shell.x + shell.w - 154.0, shell.y + shell.h - 68.0, 130.0, 44.0)

renderer.fillRoundedRectSoft(shell.shift(0.0, 8.0), 22.0, Color.rgba(0, 0, 0, 100), feather: 14.0)
renderer.fillRoundedRectGradient(shell, 22.0, Color.rgb(30, 41, 59), Color.rgb(15, 23, 42))
renderer.fillPerCornerRoundedRect(header, Color.rgb(30, 64, 175),
    topLeft: 22.0, topRight: 22.0, bottomRight: 0.0, bottomLeft: 0.0)
renderer.strokeRoundedRect(shell, 22.0, Pen(width: 1.5, color: Color.rgba(148, 163, 184, 180)))
renderer.text("任务面板", header.x + 24.0, header.y + 24.0, Color.rgb(255, 255, 255), pointSize: FontSizes.TITLE)

renderer.pushClip(content)
renderer.fillRoundedRect(content, 12.0, Color.rgba(2, 6, 23, 130))
renderer.text("内容只在此区域内显示", content.x + 16.0, content.y + 18.0, Color.rgb(203, 213, 225))
renderer.popClip()

renderer.fillRoundedRect(action, 10.0, Color.rgb(34, 197, 94))
renderer.textCenter("完成", action, Color.rgb(3, 25, 12), pointSize: FontSizes.CONTROL)
```

把同一个 `action` 保存到帧状态或由共享布局函数返回，鼠标分支直接 `action.contains(x, y)`。当窗口很小时，先规定最小尺寸或在布局函数中夹住宽高，避免出现负尺寸矩形。

## 确认结果

窗口正常尺寸下应看到清楚的三层结构：蓝色标题栏、深色内容区、绿色按钮。卡片阴影在下方柔和扩散，描边连续，标题栏只有上角为圆角。拖大窗口后内容区变宽高，四周边距仍是 28；缩小时按钮不越出卡片。把一行很长文字放进内容区，确认它在裁剪边界消失而不是覆盖按钮。点击按钮时打印一次结果，命中位置应与可见矩形一致。

## 常见错误

忘记 `popClip` 会让后续按钮和 HUD 也被裁掉；先画描边再画填充会把描边盖住；负宽高来自窗口小于固定边距，应设置 `setMinimumSize` 或夹住布局。把 `sizeInPixels` 用于 Rect、事件却使用逻辑坐标会造成点击偏移。软阴影 feather 很大时成本增加，应按视觉需要选择，不要给每个小图形都加重阴影。

## 可以继续修改

用视口把内容区当成局部坐标原点，适合列表或小型画布。这个变化不仅改颜色，还改变后续图形的坐标解释；使用后必须恢复视口。

```cangjie role=variation
renderer.setViewport(content)
renderer.fillRoundedRect(Rect(12.0, 12.0, content.w - 24.0, 48.0), 8.0, Color.rgb(51, 65, 85))
renderer.text("局部坐标内容", 28.0, 28.0, Color.rgb(241, 245, 249))
renderer.resetViewport()
```

## 相关 API

- [`Renderer`](../../api/sdl/Renderer.md)：渐变、圆角、软边、裁剪与视口。
- [`Rect`](../../api/sdl/Rect.md)：派生布局、位移和命中。
- [`Pen`](../../api/sdl/Pen.md)：描边宽度与颜色。
- [`SurfaceStyle`](../../api/sdl/SurfaceStyle.md)：上层组件复用的填充、边框和阴影值对象。

## 下一步

阅读[资源所有权](../concepts/resource-ownership.md)，再进入[多文件计算器](../tutorials/multi-file-calculator.md)把布局、状态和事件拆到真实文件。
