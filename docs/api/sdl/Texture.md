[sdl](../index.md) › [sdl](index.md) › Texture

# Texture

`sdl` 包中的 public class

GPU 侧图像资源，由渲染器创建（[`loadTexture`](Renderer.md#loadtexture) / [`textureFromSurface`](Renderer.md#texturefromsurface)），经 [`Renderer.texture`](Renderer.md#texture) / [`textureRotated`](Renderer.md#texturerotated) / [`texturedStrip`](Renderer.md#texturedstrip) 绘制。颜色调制、不透明度与混合模式设置在纹理上生效于其后的每次绘制。

## 声明

```cangjie
public class Texture <: Resource
```

## 继承

- `Resource`（标准库 `std.core`）——支持 `try (…)` 资源语法；[`close`](#close) 幂等。

## 说明

关闭后的纹理再调用设置方法抛出 `CuiException`；把关闭的纹理交给渲染器绘制同样抛出。宽高在创建时查询一次并缓存为字段，读取不触发 SDL 调用。

纹理仍有效但 SDL 拒绝颜色、不透明度或混合模式设置时，方法把失败状态转换为 `CuiException`。

## 示例

```cangjie verify
package docexample

import sdl.{Color, Rect, SdlWindow, Surface, Texture, TextureBlendMode, UiEvent, WindowSpec}

main(): Unit {
    try (window = SdlWindow(WindowSpec("纹理", 640, 480))) {
        try (surface = Surface.create(2, 2)) {
            surface.clear(Color.rgb(255, 210, 80))
            surface.writePixel(0, 0, Color.rgb(220, 40, 60))
            let sprite: Texture = window.renderer.textureFromSurface(surface)
            try {
                sprite.setBlendMode(TextureBlendMode.Blend)
                sprite.setAlpha(220)
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
                    renderer.texture(sprite, Rect(192.0, 112.0, 256.0, 256.0))
                    renderer.endScene()
                    renderer.present()
                    window.delay(16)
                }
            } finally {
                sprite.close()
            }
        }
    }
    // 运行后会显示一张由内存像素生成的半透明纹理；点击关闭按钮退出。
}
```

## 成员概览

**字段**

| 成员 | 说明 |
|---|---|
| [`width`](#width) | 纹理宽度，像素；创建时查询并缓存。 |
| [`height`](#height) | 纹理高度，像素；创建时查询并缓存。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`size()`](#size) | 以 `Size` 返回宽高。 |
| [`setColorMod(color: Color)`](#setcolormod) | 设置颜色调制，其后每次绘制的像素按该色相乘（255 为不变）。 |
| [`setAlpha(alpha: Int64)`](#setalpha) | 设置整体不透明度，输入限制在 0–255。 |
| [`setBlendMode(mode: TextureBlendMode)`](#setblendmode) | 设置与目标像素的混合方式。 |
| [`isClosed()`](#isclosed) | 判断纹理是否已关闭。 |
| [`close()`](#close) | 销毁 GPU 资源；幂等，重复调用为空操作。 |

## 字段

### width

纹理宽度，像素；创建时查询并缓存。

```cangjie
public let width: Float32
```

### height

纹理高度，像素；创建时查询并缓存。

```cangjie
public let height: Float32
```

## 方法

### size

以 [`Size`](Size.md) 返回宽高。

```cangjie
public func size(): Size
```

**返回值** `Size` — `Size(width, height)`。

### setColorMod

设置颜色调制，其后每次绘制的像素按该色相乘（255 为不变）。

```cangjie
public func setColorMod(color: Color): Unit
```

**参数**

- `color`: `Color` — 调制色；alpha 通道不参与本调用。

**异常**

- `CuiException` — 纹理已关闭，或 SDL 拒绝设置时。

### setAlpha

设置整体不透明度，输入限制在 0–255。

```cangjie
public func setAlpha(alpha: Int64): Unit
```

**参数**

- `alpha`: `Int64` — 不透明度；小于 0 按 0、大于 255 按 255 处理。

**异常**

- `CuiException` — 纹理已关闭，或 SDL 拒绝设置时。

### setBlendMode

设置与目标像素的混合方式。

```cangjie
public func setBlendMode(mode: TextureBlendMode): Unit
```

**参数**

- `mode`: `TextureBlendMode` — 混合模式。

**异常**

- `CuiException` — 纹理已关闭，或 SDL 拒绝设置时。

### isClosed

判断纹理是否已关闭。

```cangjie
public func isClosed(): Bool
```

**返回值** `Bool` — [`close`](#close) 调用之后为 `true`。

### close

销毁 GPU 资源；幂等，重复调用为空操作。

```cangjie
public func close(): Unit
```

## 另请参阅

- [TextureBlendMode](TextureBlendMode.md) — 混合模式。
- [Renderer.loadTexture](Renderer.md#loadtexture) — 从图像文件创建纹理。
