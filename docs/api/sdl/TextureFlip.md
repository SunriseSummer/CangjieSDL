[sdl](../index.md) › [sdl](index.md) › TextureFlip

# TextureFlip

`sdl` 包中的 public enum

旋转绘制纹理时的镜像方式，作为 [`TextureRenderOptions`](TextureRenderOptions.md) 的一项传入 [`Renderer.textureRotated`](Renderer.md#texturerotated)。

## 声明

```cangjie
public enum TextureFlip
```

## 示例

```cangjie verify
package docexample

import sdl.{Color, Rect, SdlWindow, Surface, TextureFlip, TextureRenderOptions, UiEvent, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("镜像", 640, 480))) {
        try (surface = Surface.create(2, 1)) {
            surface.writePixel(0, 0, Color.rgb(220, 40, 60))
            surface.writePixel(1, 0, Color.rgb(64, 128, 255))
            try (sprite = window.renderer.textureFromSurface(surface)) {
                let options = TextureRenderOptions(flip: TextureFlip.Horizontal)
                var running = true
                while (running) {
                    while (let Some(event) <- window.pollEvent()) {
                        match (event) {
                            case UiEvent.Quit => running = false
                            case _ => ()
                        }
                    }
                    if (!running) {
                        break
                    }
                    let renderer = window.renderer
                    renderer.beginScene(640.0, 480.0, Color.rgb(30, 30, 46))
                    renderer.textureRotated(sprite, Rect(192.0, 176.0, 256.0, 128.0), 0.0, options: options)
                    renderer.endScene()
                    renderer.present()
                    window.delay(16)
                }
            }
        }
    }
    // 运行后红蓝纹理会水平镜像，蓝色显示在左侧；点击关闭按钮退出。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `None` | 不镜像。 |
| `Horizontal` | 水平镜像。 |
| `Vertical` | 垂直镜像。 |
| `Both` | 水平加垂直镜像。 |

## 另请参阅

- [TextureRenderOptions](TextureRenderOptions.md) — 旋转绘制的选项集。
