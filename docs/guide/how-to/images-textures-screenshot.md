# 加载图片、绘制纹理并保存截图

## 目标

在[首个窗口](../getting-started/first-window.md)上加载 PNG/BMP 图片，创建一次 Texture 并跨帧绘制，退出前保存真实 BMP 截图。完成后能说明 Surface 与 Texture 的关闭顺序，并用文件存在、图片尺寸和人工打开三种证据确认结果。

## 适用场景

适用于应用徽标、游戏精灵、背景图、图集区域、旋转图标和问题复现截图。若需要逐像素生成或检查，先用 Surface；若只需重复绘制文件图片，直接 `loadTexture` 更简洁。大量动态图像不要每帧重新加载。

## 准备工作

先阅读[Surface、Texture 与图片](../concepts/surface-texture-image.md)。准备一张合法 `badge.png`，放在示例运行目录可访问的位置。窗口的 `try (...)` 是外层资源块，纹理资源块包住事件与渲染循环，因此退出时会先关闭纹理、再关闭窗口。

## 操作步骤

在创建窗口之后、进入循环之前调用 `window.renderer.loadTexture("badge.png")`，并让纹理资源块包住整个事件和渲染循环。每帧用逻辑目标矩形调用 `texture`；需要截图时，在完整场景提交后只调用一次 `captureBmp("window-capture.bmp")`，避免每帧覆盖同一文件。

若要先检查像素或生成图片，使用 `try (surface = Surface.load(...))`，再 `textureFromSurface(surface)`。上传后若不再读 CPU 像素，可立即离开 Surface 资源块，只让 Texture 跨帧存在。

## 确认结果

窗口中图片应保持正确宽高比例、透明区域不出现黑底，移动或缩放窗口后仍可见。触发截图后，`window-capture.bmp` 必须存在、大小大于 BMP 头部，并能被图片查看器打开；记录像素尺寸和 SHA-256。截图中的背景、图片和文字应与窗口一致。关闭窗口后进程退出码为 0，文件没有继续被占用。若只编译通过但没打开图片，不算视觉验证完成。

## 常见错误

把 `loadTexture` 放在帧循环内会重复解码和分配；Texture 由另一个窗口的 Renderer 创建时不能直接共享。目标 Rect 宽高为零或负数会得到不可见结果；源图片太小再放大容易模糊。截图在 `beginScene` 中途执行可能记录不完整帧，应在场景结束和提交后按明确时机调用。关闭纹理后仍绘制会抛出资源状态错误。

## 可以继续修改

用 `TextureRenderOptions` 把源区域设为图集中的 64×64 矩形，旋转中心设为 96×96 目标矩形的中心，并选择 `TextureFlip.Horizontal`；随后用 `textureRotated` 绘制。这样可以同时验证图集裁剪、旋转中心和水平翻转。

## 相关 API

- [`Surface`](../../api/sdl/Surface.md)：加载、像素读写和 BMP 保存。
- [`Texture`](../../api/sdl/Texture.md)：纹理属性与资源状态。
- [`TextureRenderOptions`](../../api/sdl/TextureRenderOptions.md)：源区域、中心和翻转。
- [`Renderer`](../../api/sdl/Renderer.md)：纹理绘制与 `captureBmp`。
- [`ImageFileFormat`](../../api/sdl/ImageFileFormat.md)：Surface 文件格式选择。

## 下一步

继续[输入、光标与拖放](input-cursor-drop.md)，让用户能拖入图片、选择光标并触发截图。
