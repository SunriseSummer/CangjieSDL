[sdl](../index.md) › [sdl](index.md) › Surface

# Surface

`sdl` 包中的 public class

CPU 侧的 RGBA 像素缓冲，包装 SDL_Surface：可新建、从 BMP/PNG 文件加载、逐像素写入并存回 BMP 文件。表面独立于窗口与渲染器存在；要参与 GPU 绘制，先经 [`Renderer.textureFromSurface`](Renderer.md#texturefromsurface) 转为[纹理](Texture.md)。SDL 无法创建、读写、加载或保存表面时，方法把失败状态转换为 `CuiException`；[`close`](#close) 可重复调用。

## 声明

```cangjie
public class Surface <: Resource
```

## 继承

- `Resource`（标准库 `std.core`）——支持 `try (…)` 资源语法；[`close`](#close) 幂等。

## 示例

```cangjie verify
package docexample

import sdl.{Color, Surface}

main(): Unit {
    // 无需窗口：表面是纯 CPU 缓冲。写一个 2×2 图案并保存为 BMP。
    try (canvas = Surface.create(2, 2)) {
        canvas.clear(Color.rgb(30, 30, 46))
        canvas.writePixel(0, 0, Color.rgb(255, 0, 0))
        canvas.saveBmp("docexample_surface.bmp")
        println(canvas.isClosed())
    }
    // 输出: false
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`static create(width: Int32, height: Int32)`](#create) | 新建指定尺寸的 RGBA 表面。 |
| [`static load(path: String)`](#load) | 按扩展名推断格式加载图像文件。 |
| [`static loadBmp(path: String)`](#loadbmp) | 加载 BMP 文件。 |
| [`static loadPng(path: String)`](#loadpng) | 加载 PNG 文件。 |
| [`clear(color: Color)`](#clear) | 以纯色填满整个表面。 |
| [`writePixel(x: Int32, y: Int32, color: Color)`](#writepixel) | 写入单个像素。 |
| [`saveBmp(path: String)`](#savebmp) | 把表面保存为 BMP 文件。 |
| [`isClosed()`](#isclosed) | 判断表面是否已关闭。 |
| [`close()`](#close) | 释放表面内存；幂等，重复调用为空操作。 |

## 方法

### create

新建指定尺寸的 RGBA 表面。

```cangjie
public static func create(width: Int32, height: Int32): Surface
```

**参数**

- `width`、`height`: `Int32` — 表面尺寸，像素。

**返回值** `Surface` — 新建的表面，像素格式为 RGBA32。

**异常**

- `CuiException` — SDL 无法分配表面时。

### load

按扩展名推断格式加载图像文件。`.png` / `.PNG` 按 PNG 读取，其余按 BMP 读取（与 [`imageFormatFromPath`](functions.md#imageformatfrompath) 的规则一致）。

```cangjie
public static func load(path: String): Surface
```

**参数**

- `path`: `String` — 图像文件路径。

**返回值** `Surface` — 加载出的表面。

**异常**

- `CuiException` — 文件无法按推断格式加载时。

### loadBmp

加载 BMP 文件。

```cangjie
public static func loadBmp(path: String): Surface
```

**参数**

- `path`: `String` — BMP 文件路径。

**返回值** `Surface` — 加载出的表面。

**异常**

- `CuiException` — 文件无法加载时。

### loadPng

加载 PNG 文件。

```cangjie
public static func loadPng(path: String): Surface
```

**参数**

- `path`: `String` — PNG 文件路径。

**返回值** `Surface` — 加载出的表面。

**异常**

- `CuiException` — 文件无法加载时。

### clear

以纯色填满整个表面。

```cangjie
public func clear(color: Color): Unit
```

**参数**

- `color`: `Color` — 填充颜色，含 alpha。

**异常**

- `CuiException` — 表面已关闭，或 SDL 清除失败时。

### writePixel

写入单个像素。

```cangjie
public func writePixel(x: Int32, y: Int32, color: Color): Unit
```

**参数**

- `x`、`y`: `Int32` — 像素坐标，原点在左上角。
- `color`: `Color` — 写入的颜色。

**异常**

- `CuiException` — 表面已关闭，或 SDL 写入失败时。

### saveBmp

把表面保存为 BMP 文件。

```cangjie
public func saveBmp(path: String): Unit
```

**参数**

- `path`: `String` — 输出文件路径。

**异常**

- `CuiException` — 表面已关闭，或 SDL 保存失败时。

### isClosed

判断表面是否已关闭。

```cangjie
public func isClosed(): Bool
```

**返回值** `Bool` — [`close`](#close) 调用之后为 `true`。

### close

释放表面内存；幂等，重复调用为空操作。关闭后再调用其他方法抛出 `CuiException`。

```cangjie
public func close(): Unit
```

## 另请参阅

- [ImageFileFormat](ImageFileFormat.md) — 支持的图像格式。
- [Renderer.textureFromSurface](Renderer.md#texturefromsurface) — 把表面上传为 GPU 纹理。
