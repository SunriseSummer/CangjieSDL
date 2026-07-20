[sdl](../index.md) › [sdl](index.md) › TextureRenderOptions

# TextureRenderOptions

`sdl` 包中的 public struct

[`Renderer.textureRotated`](Renderer.md#texturerotated) 的可选项集合：源区域裁剪、旋转中心与镜像方式。全部字段带默认值，只需设置关心的项。

## 声明

```cangjie
public struct TextureRenderOptions
```

## 示例

```cangjie verify
package docexample

import sdl.{Color, Point, Rect, SdlWindow, Surface, TextureFlip, TextureRenderOptions, UiEvent, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("纹理选项", 640, 480))) {
        try (surface = Surface.create(2, 2)) {
            surface.clear(Color.rgb(255, 210, 80))
            surface.writePixel(0, 0, Color.rgb(220, 40, 60))
            try (sprite = window.renderer.textureFromSurface(surface)) {
                let options = TextureRenderOptions(
                    source: Some(Rect(0.0, 0.0, 2.0, 2.0)),
                    center: Some(Point(64.0, 64.0)),
                    flip: TextureFlip.Vertical
                )
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
                    renderer.textureRotated(sprite, Rect(256.0, 176.0, 128.0, 128.0), 30.0, options: options)
                    renderer.endScene()
                    renderer.present()
                    window.delay(16)
                }
            }
        }
    }
    // 运行后会显示一张绕指定中心旋转并垂直镜像的纹理；点击关闭按钮退出。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(source!: ?Rect, center!: ?Point, flip!: TextureFlip)`](#init) | 以命名参数构造，全部可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`source`](#source) | 纹理上的源区域；`None` 使用整张纹理。 |
| [`center`](#center) | 旋转中心（相对目标区域）；`None` 绕目标区域中心旋转。 |
| [`flip`](#flip) | 镜像方式；默认不镜像。 |

## 构造函数

### init

以命名参数构造，全部可选。

```cangjie
public init(source!: ?Rect = None, center!: ?Point = None, flip!: TextureFlip = TextureFlip.None)
```

**参数**

- `source!`: `?Rect` — 源区域，纹理像素坐标；默认 `None`（整张纹理）。
- `center!`: `?Point` — 旋转中心，相对目标区域；默认 `None`（目标区域中心）。
- `flip!`: `TextureFlip` — 镜像方式；默认 `TextureFlip.None`。

## 字段

### source

纹理上的源区域；`None` 使用整张纹理。

```cangjie
public let source: ?Rect
```

### center

旋转中心（相对目标区域）；`None` 绕目标区域中心旋转。

```cangjie
public let center: ?Point
```

### flip

镜像方式；默认不镜像。

```cangjie
public let flip: TextureFlip
```

## 另请参阅

- [Renderer.textureRotated](Renderer.md#texturerotated) — 消费本选项集的旋转绘制。
- [TextureFlip](TextureFlip.md) — 镜像方式。
