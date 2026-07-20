[sdl](../index.md) › [sdl](index.md) › 函数

# 函数 — sdl

`sdl` 包的包级函数。

### clampF32

将值限制在闭区间 [`low`, `high`]。

```cangjie
public func clampF32(value: Float32, low: Float32, high: Float32): Float32
```

**参数**

- `value`: `Float32` — 要限制范围的值。
- `low`、`high`: `Float32` — 区间下界与上界。

**返回值** `Float32` — 落在区间内的值。

### drawIcon

在给定矩形内以圆头粗描边绘制一枚内置矢量图标。图标定义在 24 单位网格上；描边宽度与图标尺寸成比例（大图标不退化为细线，小图标不糊成一团），`weight` 是其下限。

```cangjie
public func drawIcon(r: Renderer, icon: IconName, rect: Rect, color: Color, weight!: Float32 = 1.6): Unit
```

**参数**

- `r`: `Renderer` — 绘制目标；无头渲染器为空操作。
- `icon`: `IconName` — 图标名称。
- `rect`: `Rect` — 图标区域，逻辑像素。
- `color`: `Color` — 描边颜色。
- `weight!`: `Float32` — 描边宽度下限，设备无关像素；默认 `1.6`。

### imageFormatFromPath

按扩展名推断图像文件格式：`.png` / `.PNG` 为 PNG，其余一律为 BMP。

```cangjie
public func imageFormatFromPath(path: String): ImageFileFormat
```

**参数**

- `path`: `String` — 图像文件路径。

**返回值** `ImageFileFormat` — 推断出的格式。

### sdlVersion

返回链接到的 SDL 版本号（SDL_GetVersion 的数值编码）。

```cangjie
public func sdlVersion(): Int32
```

**返回值** `Int32` — 版本编码，如 3002016 表示 3.2.16。

### sdlRevision

返回 SDL 构建的修订串；SDL 未提供时为空串。

```cangjie
public func sdlRevision(): String
```

**返回值** `String` — 修订标识，例如发布 tag 或提交号。
