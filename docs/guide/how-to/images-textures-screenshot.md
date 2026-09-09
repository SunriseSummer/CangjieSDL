# 加载图片、绘制纹理并保存截图

本页在一个完整程序中完成内存图像解码、纹理上传、跨帧绘制和截图。先掌握[首个窗口](../getting-started/first-window.md)与[资源所有权](../concepts/resource-ownership.md)。

## 选择加载入口

| 需求 | 入口 |
|---|---|
| 直接绘制文件 | `renderer.loadTexture(path, options: ...)` |
| 读取或修改像素后绘制 | `Surface.load(path)` → `textureFromSurface(surface)` |
| 从编码字节加载 | `Surface.loadBytes(bytes, typeHint: ...)` → `textureFromSurface(surface)` |
| 生成图片文件 | `Surface.create`、`writePixel`、`saveBmp`／`savePng`／`saveJpeg` |

`Surface.load` 通过 SDL3_image 按内容识别格式；无文件签名的格式可能需要扩展名或 `typeHint`，如 TGA。格式支持取决于原生库构建，当前接口只解码静态图像。

## 完整程序

以下 SVG 字节直接包含在程序中，无需外部素材。按 S 保存 `window-capture.bmp` 到当前工作目录。

```cangjie verify role=complete profile=gui-visual
package docexample

import sdl.*

main(): Unit {
    let bytes = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"160\" height=\"100\"><rect width=\"160\" height=\"100\" rx=\"12\" fill=\"#287d93\"/><circle cx=\"80\" cy=\"50\" r=\"30\" fill=\"#f2cc78\"/></svg>".toArray()
    try (window = SdlWindow(WindowSpec("图片与截图", 480, 320), hidden: true)) {
        let renderer = window.renderer
        try (surface = Surface.loadBytes(bytes, typeHint: "SVG", options: ImageLoadOptions(width: 640))) {
            try (texture = renderer.textureFromSurface(surface)) {
                var running = true
                var firstFrame = true
                var capture = false
                while (running) {
                    while (let Some(event) <- window.pollEvent()) {
                        match (event) {
                            case UiEvent.Quit | UiEvent.WindowCloseRequested => running = false
                            case UiEvent.KeyDown(Key.Letter(code), _) where code == UInt8(83) => capture = true
                            case _ => ()
                        }
                    }
                    if (!running) { break }
                    try (pass = renderer.beginRenderPass(Float32(window.width), Float32(window.height),
                            Color.rgb(24, 30, 40))) {
                        renderer.textureStyled(texture, Rect(80.0, 50.0, 320.0, 200.0),
                            style: TextureStyle(opacity: 0.9, radius: 16.0))
                        renderer.text("按 S 保存截图", 80.0, 270.0, Color.rgb(240, 240, 240))
                    }
                    if (capture) {
                        renderer.captureBmp("window-capture.bmp")
                        capture = false
                    }
                    renderer.present()
                    if (firstFrame) {
                        window.show()
                        firstFrame = false
                        continue
                    }
                    window.delay(UInt32(8))
                }
            }
        }
    }
}
```

窗口是最外层资源；纹理先于表面和窗口关闭。示例为清楚展示嵌套关系而保留 Surface；上传后不再读取 CPU 像素的应用可以更早关闭它。帧循环只绘制已有纹理，不重复解码。

## 显示尺寸与解码尺寸

目标 `Rect` 使用逻辑像素，`ImageLoadOptions` 使用解码像素。`width`、`height` 为零表示该轴不受限；非零值限制尺寸并保持比例。

位图先完整解码，再按比例缩小；SVG 可直接按请求尺寸栅格化。`maxPixels` 在解码后、位图缩小前检查，不能限制解码器的临时分配。因此请求很小的缩略图，也可能因原图超过预算而失败。参数非法抛出 `IllegalArgumentException`；解码、资源或像素预算失败抛出 `SdlException`。

`TextureStyle` 为一次绘制提供着色、透明度、圆角、采样和镜像。它使用独立的标准 Alpha 合成，并在绘制后恢复纹理混合与采样状态。需要图集或旋转时，另查 `textureStyled` 的 `source` 及 `textureRotated`／`TextureRenderOptions`。

## 截图时机与验收

`captureBmp` 读回当前渲染目标。完整窗口截图的顺序是：结束 `RenderPass` → `captureBmp` → `present`。在场景内部截图可能得到超采样中间目标；提交后后备缓冲内容不应再作为截图依据。`renderFrame` 已包含 `present`，需要这个中间步骤时使用显式 `RenderPass`。

运行后检查图形比例、圆角、透明度及缩放效果；按 S 后打开 BMP，确认尺寸和画面。headless 模式下 `captureBmp` 是空操作，不产生文件。保存失败还应检查输出目录与权限。

继续阅读[输入、光标与拖放](input-cursor-drop.md)，接入用户图片。精确接口见 [`Surface`](../../api/sdl/Surface.md)、[`ImageLoadOptions`](../../api/sdl/ImageLoadOptions.md)、[`TextureStyle`](../../api/sdl/TextureStyle.md) 与 [`Renderer`](../../api/sdl/Renderer.md)。
