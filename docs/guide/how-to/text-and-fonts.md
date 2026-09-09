# 排版文字与选择字体

本页为 SDL 窗口加入标题、右对齐读数和居中文字，再说明字体注册与诊断。文字度量和绘制必须使用相同字符串、字号、样式、字体及栅格比例。

## 绘制与度量

下面的程序无需随附字体，使用平台 UI 字体。右对齐由“右边界减文字宽度”得到，居中由 `textCenter` 完成。

```cangjie verify role=complete profile=gui-visual
package docexample

import sdl.*

main(): Unit {
    Fonts.setDefault(FontRole.systemUI)
    try (window = SdlWindow(WindowSpec("文字排版", 560, 320), hidden: true)) {
        let renderer = window.renderer
        let style = FontStyle(weight: FontWeight.semiBold)
        let foreground = Color.rgb(240, 242, 246)
        var running = true
        var firstFrame = true
        while (running) {
            while (let Some(event) <- window.pollEvent()) {
                match (event) {
                    case UiEvent.Quit | UiEvent.WindowCloseRequested => running = false
                    case _ => ()
                }
            }
            if (!running) { break }
            renderer.renderFrame(Float32(window.width), Float32(window.height), Color.rgb(24, 30, 40)) {
                renderer.text("仓颉文字排版", 32.0, 32.0, foreground, pointSize: 24.0, style: style)
                let value = "12,480 ms"
                let width = renderer.textWidth(value, pointSize: 32.0, style: style)
                renderer.text(value, Float32(window.width) - 32.0 - width, 100.0, foreground,
                    pointSize: 32.0, style: style)
                renderer.textCenter("居中标签", Rect(32.0, 180.0, Float32(window.width) - 64.0, 64.0),
                    foreground, pointSize: 20.0)
            }
            if (firstFrame) {
                window.show()
                firstFrame = false
                continue
            }
            window.delay(UInt32(8))
        }
    }
}
```

`pointSize` 使用逻辑像素。需要在场景外先测量布局时，调用 `prepareTextLayout(logicalWidth, logicalHeight)`，再用相同尺寸开启场景；尺寸或帧间比例变化后重新准备。在场景内测量则直接采用当前比例，不要自行再乘 DPI。

`textHeight` 是稳定行高，`textBounds` 是具体字符串的保守栅格框，`textInkBounds` 排除行框留白，`textCenter` 据墨迹范围做视觉居中。headless 使用近似度量，仅适合结构与控制流测试。

## 选择字体

| 需求 | 做法 |
|---|---|
| 普通应用默认字体 | `Fonts.setDefault(FontRole.systemUI)` |
| 指定系统族名 | 在度量和绘制中都传 `font: Some(name)` |
| 为系统族名建立应用别名 | `Fonts.registerSystem(alias, family)`，检查返回结果 |
| 随附字体及真实粗斜体 | `Fonts.registerFamily(name, FontFamily(...))` |
| 查询一个族的字体面与轴 | `Fonts.familyFaces(name)` |
| 完整字体选择器 | 显式调用 `Fonts.systemFamilyNames()`／`systemFonts()` |

普通族名与角色请求定向匹配，不扫描完整系统目录。平台服务使用 Windows DirectWrite、Linux fontconfig、macOS CoreText；无法取得可访问字体文件的系统字体可能不能交给 SDL_ttf。当前文件元数据解析支持 SFNT 字体（TTF、OTF、TTC、OTC）。

注册应在首次渲染前完成。下面的路径须替换成实际文件；注册本身不读取文件，不能作为成功加载的证据。

```cangjie verify role=complete
package docexample

import sdl.*

main(): Unit {
    Fonts.registerFamily("Brand", FontFamily(FontSource("assets/Brand-Regular.ttf"),
        bold: FontSource("assets/Brand-Bold.ttf"),
        italic: FontSource("assets/Brand-Italic.ttf"),
        fallbacks: [FontSource("assets/CJK.ttc", faceIndex: 0)],
        faces: [FontFaceDefinition(FontSource("assets/Brand-Medium.ttf"), weight: FontWeight.medium)]))
    Fonts.setDefault("Brand")
}
```

可用的应用默认文件可直接用于渲染器初始化；后续按需尝试平台 UI 字体与配置的后备。全部不可用时报告错误。`setSearchDirectories` 增加应用目录，`setFallbacks` 配置全局缺字链与随附保底字体。

## 字重、样式与设计轴

`FontStyle(weight: FontWeight(625))` 请求数值字重，粗体快捷方式对应 700。静态字体按倾斜、字宽和字重匹配；没有精确面时可能近似或合成。真实斜体优先，应用不需要用字距补偿倾斜。

变量字体通过 `FontVariations` 设置文件实际提供的轴。先查询轴范围；未知轴、重复标签、非有限或越界的显式坐标会报错，普通 `fontWeight` 超出字体范围则钳制并诊断。`opsz` 不随字号自动改变。

`FontSource.faceIndex` 选择集合面，`instanceIndex` 固定命名实例，源级 `variations` 固定设计坐标。固定源不被普通字重请求重置；动态字重应注册基础文件。`Fonts.supportsVariations()` 查询运行库版本能力，不能证明某个字体具有指定设计轴。

## 长文本、命中与字素

对同一字符串多次测量时，用 `textMeasureSession` 保留字体和 UTF-8 数据，使用后关闭。`measure` 接受精确字节范围；`fit` 返回适合宽度的前缀字节数；`hitTest` 返回字形簇附近的插入边界。

`fit` 的公共保证是 UTF-8 码点安全，不等同于语言换行、完整字素或段落双向排版。上层编辑器可用 [`sdl.text`](../../api/sdl/text/index.md) 的字素函数处理组合附加符、ZWJ 与旗帜，再实现所需断行规则。底层字形簇命中也不能代替完整双向编辑策略。

## Emoji 后备

包含 Emoji 候选字符时，框架按需尝试平台 Emoji 字体，以完整字素选择来源，并合并相邻同字体片段进行整形。普通文本不会因此扫描完整目录。主字体与显式后备优先；VS16 请求 Emoji 外观时优先尝试彩色字体，VS15 不触发这项替换。

彩色字形保留字体调色板，普通字形采用请求颜色，透明度对两者均生效。自动 Emoji 后备不继承合成粗斜体与变量轴。同行文字应作为完整字符串传给 `text`，由布局处理共同基线；不要给 Emoji 叠加固定垂直偏移。

字素完整不保证字体覆盖全部序列。最新 Emoji、旗帜或组合缺字时，应提供合适字体并在目标平台检查。`FontRole.emoji` 可显式选择平台 Emoji 角色。

## 诊断与恢复

用 `renderer.resolveFont(...)` 比较请求字重、实际面、源坐标、合成状态与警告；用 `fontCacheStats()` 检查缓存成本。少量稳定字号与字重有助于复用，连续轴变化仍需生成新轮廓。

补齐缺失字体后，重新注册或调用 `Fonts.reload()`。替换正在使用的文件前，先关闭测量会话、调用 `renderer.reloadFonts()` 释放缓存，再替换并通知注册表重载。存活会话固定旧配置，具体所有权与预算见[字体缓存](../concepts/text-font-cache.md)。

完整系统目录由显式枚举加载。可选 `Fonts.setMetadataCache(path)` 持久保存元数据，应用先准备父目录；文件变化使记录失效，`refreshSystemFonts(force: true)` 可强制重建。

验收时检查中文、数字、粗斜体、Emoji、长文本和缺失字体回退；比较不同窗口尺寸与 DPI 下的度量和绘制。接口见 [`Renderer`](../../api/sdl/Renderer.md)、[`Fonts`](../../api/sdl/Fonts.md)、[`FontStyle`](../../api/sdl/FontStyle.md) 和 [`TextMeasureSession`](../../api/sdl/TextMeasureSession.md)。
