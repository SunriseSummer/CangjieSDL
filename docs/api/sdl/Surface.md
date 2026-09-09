[sdl](../index.md) › [sdl](index.md) › Surface

# Surface

位于 `sdl` 包的公开类。

CPU 侧的像素缓冲（解码格式由加载器决定，create 创建 RGBA32），包装 SDL_Surface：可新建、通过 SDL_image 从多种静态图像格式加载、逐像素读写并保存为 BMP、PNG 或 JPEG。表面独立于窗口与渲染器存在；要参与 GPU 绘制，先经 [`Renderer.textureFromSurface`](Renderer.md#texturefromsurface) 转为[纹理](Texture.md)。SDL 无法创建、读写、加载或保存表面时，方法把失败状态转换为 `SdlException`；[`close`](#close) 可重复调用。

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
| [`static load(path: String)`](#load) | 按内容识别静态图像；扩展名作为 TGA 等格式的提示。 |
| [`static loadBmp(path: String)`](#loadbmp) | 加载 BMP 文件；路径含 NUL 时抛出 `IllegalArgumentException`，解码失败时抛出 `SdlException`。 |
| [`static loadPng(path: String)`](#loadpng) | 加载 PNG 文件；路径含 NUL 时抛出 `IllegalArgumentException`，解码失败时抛出 `SdlException`。 |
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

- `SdlException` — SDL 无法分配表面时。

### load

按内容识别静态图像；扩展名作为 TGA 等格式的提示。支持格式由 SDL_image 构建决定，PNG 的混合大小写和无后缀文件均可识别。ImageLoadOptions 独立控制缓存像素边界与预算。

```cangjie
public static func load(path: String, options!: ImageLoadOptions = ImageLoadOptions()): Surface
```

**参数**

- `path`: `String` — 图像文件路径。

**返回值** `Surface` — 加载出的表面。

**异常**

- `SdlException` — 文件无法按推断格式加载时。

### loadBmp

加载 BMP 文件；路径含 NUL 时抛出 `IllegalArgumentException`，解码失败时抛出 `SdlException`。

```cangjie
public static func loadBmp(path: String): Surface
```

**参数**

- `path`: `String` — BMP 文件路径。

**返回值** `Surface` — 加载出的表面。

**异常**

- `SdlException` — 文件无法加载时。

### loadPng

加载 PNG 文件；路径含 NUL 时抛出 `IllegalArgumentException`，解码失败时抛出 `SdlException`。

```cangjie
public static func loadPng(path: String): Surface
```

**参数**

- `path`: `String` — PNG 文件路径。

**返回值** `Surface` — 加载出的表面。

**异常**

- `SdlException` — 文件无法加载时。

### clear

以纯色填满整个表面。

```cangjie
public func clear(color: Color): Unit
```

**参数**

- `color`: `Color` — 填充颜色，含 alpha。

**异常**

- `SdlException` — 表面已关闭，或 SDL 清除失败时。

### writePixel

写入单个像素。

```cangjie
public func writePixel(x: Int32, y: Int32, color: Color): Unit
```

**参数**

- `x`、`y`: `Int32` — 像素坐标，原点在左上角。
- `color`: `Color` — 写入的颜色。

**异常**

- `SdlException` — 表面已关闭，或 SDL 写入失败时。

### saveBmp

把表面保存为 BMP 文件。

```cangjie
public func saveBmp(path: String): Unit
```

**参数**

- `path`: `String` — 输出文件路径。

**异常**

- `SdlException` — 表面已关闭，或 SDL 保存失败时。

### isClosed

判断表面是否已关闭。

```cangjie
public func isClosed(): Bool
```

**返回值** `Bool` — [`close`](#close) 调用之后为 `true`。

### close

释放表面内存；幂等，重复调用为空操作。关闭后再调用其他方法抛出 `SdlException`。

```cangjie
public func close(): Unit
```

## 静态图像扩展

### loadBytes

从编码字节解码一张静态图像。TGA 等无签名格式可用 `typeHint` 指明类型。不保留调用方字节，调用期间不得修改输入。解码失败抛出 `SdlException`，提示含 NUL 时抛出 `IllegalArgumentException`。

```cangjie
public static func loadBytes(bytes: Array<UInt8>, typeHint!: String = "",
        options!: ImageLoadOptions = ImageLoadOptions()): Surface
```

### size

查询像素尺寸；表面已关闭时抛出 `SdlException`。

```cangjie
public func size(): Size
```

### readPixel

读取一个 RGBA 像素；表面已关闭或坐标越界时抛出 `SdlException`。

```cangjie
public func readPixel(x: Int32, y: Int32): Color
```

### resized

创建指定像素尺寸的独立表面，由调用方关闭。宽高非正时抛出 `IllegalArgumentException`；源表面已关闭或分配失败时抛出 `SdlException`。

```cangjie
public func resized(width: Int32, height: Int32, sampling!: TextureScaleMode = TextureScaleMode.Linear): Surface
```

### savePng

保存保留透明度的无损 PNG。路径含 NUL 时抛出 `IllegalArgumentException`；表面已关闭或写入失败时抛出 `SdlException`。

```cangjie
public func savePng(path: String): Unit
```

### saveJpeg

保存不含 Alpha 的 JPEG。质量不在 0..100 内或路径含 NUL 时抛出 `IllegalArgumentException`；表面已关闭或写入失败时抛出 `SdlException`。

```cangjie
public func saveJpeg(path: String, quality!: Int32 = 90): Unit
```

所有图像文件读写接口均拒绝包含 NUL 的路径，避免 C 字符串截断后访问其他文件。加载后的表面格式由解码器选择；Surface.create 创建 RGBA32，像素读写辅助接口使用 RGBA 颜色值。

### alphaMask

返回独立的 RGBA32 表面：RGB 全部置白，保留输入透明度覆盖范围。SDL 格式转换先处理索引调色板／色键透明。不会修改或关闭原表面；调用方负责关闭返回值。

```cangjie
public func alphaMask(): Surface
```

关闭的输入、转换或锁定失败抛出 `SdlException`。直接按行距处理转换后的像素，循环中没有逐像素 FFI 调用。该操作适合资源载入阶段，勿每帧执行。

## 另请参阅

- [ImageFileFormat](ImageFileFormat.md) — 支持的图像格式。
- [Renderer.textureFromSurface](Renderer.md#texturefromsurface) — 把表面上传为 GPU 纹理。
