# Surface、Texture 与图片

## 先用一句话说明

Surface 是 CPU 可以读取和修改的像素表面，Texture 是与 Renderer 绑定、适合重复绘制的 GPU 资源；从 Surface 创建 Texture 后，两者仍各自拥有并关闭自己的资源。

## 为什么重要

先阅读[资源所有权](resource-ownership.md)，因为 Surface 与 Texture 的主要区别不仅是存放位置，还包括拥有者和关闭顺序。

截图、离线像素生成和图片保存需要 CPU 表面；游戏精灵、图标和背景需要每帧快速绘制的纹理。若每帧重新 `Surface.load` 再上传，会反复解码、分配和传输；若只保留 Surface 而不用纹理，渲染路径无法获得重复绘制优势；若关闭 Texture 后仍绘制，封装会报告无效状态。

`Surface.load` 按扩展名选择 BMP 或 PNG，也可显式调用相应加载函数。Surface 支持创建、清屏、读写像素与保存 BMP。Renderer 的 `textureFromSurface` 上传现有 Surface，`loadTexture` 则直接从文件完成加载与上传。Texture 可设置混合模式和颜色、透明度调制，绘制时可指定源区域、旋转中心和翻转。

## 工作模型

典型初始化流程是“读文件到 Surface → 必要时检查或改像素 → 上传为 Texture → 关闭 Surface”；帧循环只使用 Texture；退出时先关闭 Texture，再关闭窗口。若程序还要保存修改后的 CPU 图像，可让 Surface 生命周期延长，但要明确它与 Texture 内容不会自动双向同步。

下面的对比把图片加载放进每帧循环，虽然容易写，却会不断创建和关闭资源。

```cangjie role=contrast
while (running) {
    try (image = Surface.load("badge.png")) {
        try (texture = renderer.textureFromSurface(image)) {
            renderer.texture(texture, destination)
        }
    }
}
```

稳定结构在初始化阶段创建一次纹理，帧循环只借用。

```cangjie role=trace
try (surface = Surface.load("badge.png")) {
    try (texture = renderer.textureFromSurface(surface)) {
        while (running) {
            drawScene(renderer, texture)
        }
    }
}
```

## 选择与取舍

只需要绘制文件图片时优先 `loadTexture`，代码更短；需要检查尺寸、改像素、合成或另存时先用 Surface。大量小图片可合并为图集并用 source Rect 选择区域，减少资源数量；代价是需要维护图集坐标。旋转和翻转适合 Texture，复杂 CPU 滤镜适合 Surface；不要为了使用一个 API 而在两边来回转换。

透明图片应使用 Blend 模式，纯不透明背景可用更简单模式。颜色和透明度调制会影响后续所有该纹理绘制，若同一纹理承担不同效果，绘制前明确设置并在需要时恢复。纹理与创建它的 Renderer 绑定，不能跨窗口随意共享。

## 应用这个模型

应用启动时加载徽标，读取 Surface 尺寸确认资源正确，再上传 Texture；绘制时用逻辑目标矩形缩放。截图走另一方向：Renderer 读取当前输出并写 BMP，随后用文件尺寸、图片尺寸和人工查看确认。若要保存程序生成的小图，可 `Surface.create`、`clear`、`writePixel` 后 `saveBmp`，这个流程完全不需要可见窗口。

排查黑块或透明失效时检查混合模式、源矩形是否越界、目标矩形是否为正尺寸，以及纹理是否已关闭。排查图片模糊时比较源像素尺寸、目标逻辑尺寸和窗口像素密度；超采样不会补回低分辨率纹理缺失的细节。

## 常见误解

Texture 不是普通像素数组，不能像 Surface 那样随意读写。上传 Texture 后关闭 Surface 是安全的，但关闭窗口后继续保留 Texture 不是安全的。`Surface.load` 支持的格式由封装明确限定，不能把任意扩展名交给它碰运气。截图成功返回也不代表画面正确，仍要读取图片尺寸并实际打开检查。

## 相关 API

- [`Surface`](../../api/sdl/Surface.md)：CPU 像素、文件加载与 BMP 保存。
- [`Texture`](../../api/sdl/Texture.md)：纹理尺寸、混合与调制。
- [`TextureRenderOptions`](../../api/sdl/TextureRenderOptions.md)：旋转中心和翻转。
- [`Renderer`](../../api/sdl/Renderer.md)：上传、绘制与截图。

## 下一步

进入[图片、纹理与截图](../how-to/images-textures-screenshot.md)，把图片资源接入首个窗口并形成可复核文件。
