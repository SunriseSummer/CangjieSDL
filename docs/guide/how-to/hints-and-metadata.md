# 设置应用元数据与 SDL Hints

## 目标

基于[首个窗口](../getting-started/first-window.md)，在构造 `SdlWindow` 之前设置应用名称、版本、标识符和关键 SDL Hint，并在运行时读回确认。完成后，初始化前设置与运行时设置有明确边界，不把 Hint 当作必然生效的业务配置。

## 适用场景

适用于应用身份、视频驱动选择、垂直同步提示、屏保策略、IME 行为、文件对话框驱动和 Windows Alt+F4 行为。Hint 是给 SDL 后端的建议或覆盖，不是所有平台都保证相同效果；业务必须依赖的设置应使用明确 API 和可观察确认。

## 准备工作

把元数据与 Hints 放在 `main` 最前面、窗口构造之前。标识符使用稳定的反向域名形式，名称和版本与发布清单一致。不要在库内部悄悄 `resetAll`，那会删除宿主应用设置；测试若修改全局 Hint，应只重置自己改过的项。

## 操作步骤

在首个窗口 `try (window = ...)` 之前加入下面代码。先应用元数据，再设置允许屏保和渲染垂直同步提示；立即读回可以证明值已保存，但最终后端行为仍需运行时观察。

```cangjie role=patch
var metadata = AppMetadata(
    name: Some("SDL Guide App"),
    version: Some("0.2.0"),
    identifier: Some("org.example.sdlguide")
)
metadata.creator = Some("GuideLab")
metadata.appType = Some(AppMetadataType.Application)
ApplicationMetadata.apply(metadata)

SdlHints.setBool(SdlHint.VideoAllowScreensaver, true)
SdlHints.set(SdlHintSetting(SdlHint.RenderVSync, "1", priority: HintPriority.Normal))
println("screensaver=${SdlHints.getBool(SdlHint.VideoAllowScreensaver, false)}")
```

创建窗口后可通过 `renderer.vsync()` 查询实际渲染器状态；若明确传入 `WindowSpec.vsync`，以该构造设置和实际查询解释结果，不要只看 Hint。

## 确认结果

程序启动前没有创建窗口，元数据版本可通过 `ApplicationMetadata.get` 读回。Hint 读回 true，窗口仍正常显示与关闭；渲染器查询给出实际 VSync 值。移除或重置某个 Hint 后再次读取，结果回到默认或 None。把设置移到窗口创建后做一次对照，记录哪些后端行为不再变化，以证明初始化时机的重要性。

## 常见错误

窗口已经创建后再设置视频驱动 Hint 通常太晚；把 Hint 读回值当作硬件最终状态也不准确。`CustomHint` 或 `CustomMetadataProperty` 名称不能为空。全局 `resetAll` 会影响同进程其他模块。元数据 URL、标识符和版本应由构建配置统一提供，不要在多个文件复制不同值。

## 可以继续修改

为开发构建设置自定义元数据属性，并在退出前只移除该属性。这个变化验证属性级生命周期，不清空其他应用身份。

```cangjie role=variation
let channel = AppMetadataProperty.CustomMetadataProperty("org.example.build-channel")
ApplicationMetadata.set(channel, "development")
match (ApplicationMetadata.get(channel)) {
    case Some(value) => println("channel=${value}")
    case None => println("channel missing")
}
ApplicationMetadata.remove(channel)
```

## 相关 API

- [`ApplicationMetadata`](../../api/sdl/system/ApplicationMetadata.md) 与 [`AppMetadata`](../../api/sdl/system/AppMetadata.md)：应用身份。
- [`SdlHints`](../../api/sdl/system/SdlHints.md)：设置、读取和重置。
- [`SdlHint`](../../api/sdl/system/SdlHint.md) 与 [`HintPriority`](../../api/sdl/system/HintPriority.md)：支持项与优先级。
- [`WindowSpec`](../../api/sdl/WindowSpec.md)：窗口级 VSync 等明确构造设置。

## 下一步

继续[系统、时间与电源](system-time-power.md)，把静态启动配置与运行中的动态快照区分开。
