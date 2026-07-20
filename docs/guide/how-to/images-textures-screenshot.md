# 加载图片、绘制纹理并保存截图

## 目标

在[首个窗口](../getting-started/first-window.md)上加载 PNG/BMP 图片，创建一次 Texture 并跨帧绘制，退出前保存真实 BMP 截图。完成后能说明 Surface 与 Texture 的关闭顺序，并用文件存在、图片尺寸和人工打开三种证据确认结果。

## 适用场景

适用于应用徽标、游戏精灵、背景图、图集区域、旋转图标和问题复现截图。若需要逐像素生成或检查，先用 Surface；若只需重复绘制文件图片，直接 `loadTexture` 更简洁。大量动态图像不要每帧重新加载。

## 准备工作

先阅读[Surface、Texture 与图片](../concepts/surface-texture-image.md)。准备一张合法 `badge.png`，放在示例运行目录可访问的位置。首个窗口的 try-with-resources 是外层拥有者；纹理资源块应包住事件与渲染循环，使纹理先关闭、窗口后关闭。

## 操作步骤

在创建窗口之后、进入 `while` 之前加载纹理，并把原循环放进纹理资源块。绘制时给出逻辑目标矩形；按 `S` 时在 `present` 后保存一次截图，避免每帧覆盖同一文件。

```cangjie role=patch
try (badge = window.renderer.loadTexture("badge.png")) {
    var saved = false
    while (running) {
        handleEvents(window)
        let r = window.renderer
        r.beginScene(Float32(window.width), Float32(window.height), Color.rgb(15, 23, 42))
        r.texture(badge, Rect(64.0, 84.0, 256.0, 144.0))
        r.endScene()
        r.present()
        if (saveRequested && !saved) {
            r.captureBmp("window-capture.bmp")
            saved = true
        }
    }
}
```

若要先检查像素或生成图片，使用 `try (surface = Surface.load(...))`，再 `textureFromSurface(surface)`。上传后若不再读 CPU 像素，可立即离开 Surface 资源块，只让 Texture 跨帧存在。

## 确认结果

窗口中图片应保持正确宽高比例、透明区域不出现黑底，移动或缩放窗口后仍可见。触发截图后，`window-capture.bmp` 必须存在、大小大于 BMP 头部，并能被图片查看器打开；记录像素尺寸和 SHA-256。截图中的背景、图片和文字应与窗口一致。关闭窗口后进程退出码为 0，文件没有继续被占用。若只编译通过但没打开图片，不算视觉验证完成。

## 常见错误

把 `loadTexture` 放在帧循环内会重复解码和分配；Texture 由另一个窗口的 Renderer 创建时不能直接共享。目标 Rect 宽高为零或负数会得到不可见结果；源图片太小再放大容易模糊。截图在 `beginScene` 中途执行可能记录不完整帧，应在场景结束和提交后按明确时机调用。关闭纹理后仍绘制会抛出资源状态错误。

## 可以继续修改

只绘制图集中的一个区域，并围绕目标中心旋转、水平翻转。这个变化同时验证 source Rect、旋转和 TextureRenderOptions，而不是简单换文件。

```cangjie role=variation
let options = TextureRenderOptions(
    source: Some(Rect(64.0, 0.0, 64.0, 64.0)),
    center: Some(Point(48.0, 48.0)),
    flip: TextureFlip.Horizontal
)
renderer.textureRotated(badge, Rect(360.0, 120.0, 96.0, 96.0), 18.0, options: options)
```

## 相关 API

- [`Surface`](../../api/sdl/Surface.md)：加载、像素读写和 BMP 保存。
- [`Texture`](../../api/sdl/Texture.md)：纹理属性与资源状态。
- [`TextureRenderOptions`](../../api/sdl/TextureRenderOptions.md)：源区域、中心和翻转。
- [`Renderer`](../../api/sdl/Renderer.md)：纹理绘制与 `captureBmp`。
- [`ImageFileFormat`](../../api/sdl/ImageFileFormat.md)：Surface 文件格式选择。

## 下一步

继续[输入、光标与拖放](input-cursor-drop.md)，让用户能拖入图片、选择光标并触发截图。
