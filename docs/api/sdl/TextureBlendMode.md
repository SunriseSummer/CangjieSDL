[sdl](../index.md) › [sdl](index.md) › TextureBlendMode

# TextureBlendMode

`sdl` 包中的 public enum

纹理绘制时与目标像素的混合方式，对应 SDL 的 SDL_BLENDMODE_*。

## 声明

```cangjie
public enum TextureBlendMode
```

## 示例

```cangjie verify
package docexample

import sdl.{Color, Rect, SdlWindow, Surface, TextureBlendMode, UiEvent, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("混合模式", 640, 480))) {
        try (surface = Surface.create(1, 1)) {
            surface.clear(Color.rgba(255, 80, 80, 160))
            try (texture = window.renderer.textureFromSurface(surface)) {
                texture.setBlendMode(TextureBlendMode.Blend)
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
                    renderer.beginScene(640.0, 480.0, Color.rgb(30, 60, 120))
                    renderer.texture(texture, Rect(192.0, 112.0, 256.0, 256.0))
                    renderer.endScene()
                    renderer.present()
                    window.delay(16)
                }
            }
        }
    }
    // 运行后会看到半透明红色纹理与蓝色背景进行 Alpha 混合；点击关闭按钮退出。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `None` | 不混合，直接覆盖目标像素。 |
| `Blend` | 标准 alpha 混合。 |
| `Add` | 加法混合（发光叠加）。 |
| `Mod` | 颜色调制（相乘变暗）。 |
| `Mul` | 预乘式相乘混合。 |

## 另请参阅

- [Texture.setBlendMode](Texture.md#setblendmode) — 应用混合模式。
