# 资源所有权与关闭顺序

## 先用一句话说明

窗口、Surface、Texture 和 Cursor 都要有一个明确拥有者；拥有者在最后一次使用后关闭一次，任何借用者都不得保存超出拥有者生命周期的引用。

## 为什么重要

先掌握[窗口与事件循环](window-events-lifecycle.md)，才能准确判断最后一次事件、绘制和关闭分别发生在何时。

这些类型背后是原生资源，仓颉对象离开局部变量并不等于底层资源立即安全释放。窗口关闭会释放内部渲染器、停止文本输入、销毁窗口并退出视频子系统；Texture 与创建它的渲染器关联；Cursor 激活后仍需在不用时关闭；Surface 关闭后不能再读取像素或创建纹理。关闭过早会得到 `CuiException` 或无效绘制，忘记关闭则会累积显存、像素内存或系统对象。

异常路径尤其容易暴露问题。若程序在加载图片后、创建纹理前失败，Surface 仍要释放；若窗口构造后的字体初始化失败，已经创建的部分资源也要回收。try-with-resources 和 `finally` 的价值是让正常退出、用户关闭和异常使用同一条清理路径。

## 工作模型

把资源关系画成树：`SdlWindow` 拥有 `Renderer`；Renderer 创建的 Texture 必须在 Renderer 仍有效时使用并关闭；Surface 独立存在，可先加载或生成，再由 Renderer 上传为 Texture；上传完成不代表 Surface 自动关闭，也不代表 Texture 可脱离 Renderer。Cursor 通常由应用或某个窗口工具拥有，但激活是全局可见效果，替换时要保留当前资源直到新光标生效。

下面的反例从函数返回 Texture，却先关闭了窗口；返回值失去有效渲染器。

```cangjie role=contrast
func loadBadge(path: String): Texture {
    let window = SdlWindow(WindowSpec("临时", 64, 64))
    let texture = window.renderer.loadTexture(path)
    window.close()
    texture
}
```

安全边界让窗口覆盖纹理的整个使用期，并用嵌套资源块表达关闭顺序。

```cangjie role=trace
try (window = SdlWindow(WindowSpec("徽标", 640, 360))) {
    try (surface = Surface.load("badge.png")) {
        try (texture = window.renderer.textureFromSurface(surface)) {
            drawBadge(window, texture)
        }
    }
}
```

## 选择与取舍

短生命资源适合局部 try-with-resources；跨帧资源适合集中到 `Assets` 或应用状态对象，由应用退出时统一关闭。集中管理减少遗漏，但要明确关闭顺序并防止业务对象任意持有资源。资源缓存可以提高性能，代价是更长生命周期和失效管理；动态加载后立即丢弃 Surface、保留 Texture，通常适合只绘制不读像素的图片。

窗口本身也可显式 `close()`，但只有在无法使用资源块时才需要。若调用显式关闭，后续代码应停止事件和渲染，并让 `isClosed()` 成为可观察保护。不要依赖重复关闭来掩盖边界不清，也不要在多个模块都写“保险 close”。

## 应用这个模型

计算器只有窗口和内部文本资源，入口用一个资源块即可。图片应用可把 `Surface.load → textureFromSurface → Surface.close` 放在初始化，Texture 放入 `Assets`，退出时先关闭 Texture 再关闭窗口。游戏的多个纹理和光标可由 `GameAssets` 统一拥有；状态和模拟只保存资源键或尺寸，不直接负责关闭。

排查资源问题时列出创建点、最后使用点和关闭点，按时间排序。检查异常是否能越过关闭语句，检查窗口关闭后是否仍有定时回调绘制，检查纹理是否由另一个 Renderer 创建。仓库的窗口生命周期测试证明关闭一个窗口不应破坏另一个，这也是多窗口改动后的必要回归。

## 常见误解

“窗口关闭会释放所有 Surface 和 Cursor”不成立；独立资源仍由创建者负责。“Texture 是图片数据，可以在任何窗口绘制”也不成立，它绑定创建它的 Renderer。try-with-resources 不是只为异常服务，它还把正常路径的关闭顺序写进结构。最后，Surface 转 Texture 不是移动所有权：转换后两个资源同时存在，直到各自关闭。

## 相关 API

- [`SdlWindow`](../../api/sdl/SdlWindow.md)：主窗口资源与关闭行为。
- [`Surface`](../../api/sdl/Surface.md)：CPU 像素表面及其关闭边界。
- [`Texture`](../../api/sdl/Texture.md)：渲染器相关纹理资源。
- [`Cursor`](../../api/sdl/input/Cursor.md)：系统光标资源与激活。

## 下一步

完成[多文件计算器](../tutorials/multi-file-calculator.md)，观察入口怎样成为资源所有者，而逻辑和渲染只接受借用。
