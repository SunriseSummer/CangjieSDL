[sdl](../../index.md) › [sdl.displays](index.md) › 函数

# 函数 — sdl.displays

`sdl.displays` 包的包级函数。`primaryDisplayInfo`、`displayIds` 与经后者实现的 `allDisplayInfos` 会按需初始化视频子系统；其他查询不会调用 `SDL_Init`，须先创建窗口或调用上述入口。除 `closestFullscreenDisplayMode` 明确以 `None` 表示 SDL 的失败结果外，其余带失败状态的 SDL 查询会转换为 `CuiException`。

### primaryDisplayInfo

返回主显示器的聚合信息。

```cangjie
public func primaryDisplayInfo(): DisplayInfo
```

**返回值** `DisplayInfo` — 主显示器信息。

**异常**

- `CuiException` — SDL 无法初始化视频或查询主显示器时。

### displayInfo

返回指定编号显示器的聚合信息。

调用前须已初始化视频子系统；本函数不会主动初始化。

```cangjie
public func displayInfo(id: UInt32): DisplayInfo
```

**参数**

- `id`: `UInt32` — SDL 显示器编号；须非零。

**返回值** `DisplayInfo` — 该显示器信息。

**异常**

- `CuiException` — 编号为零，或 SDL 无法查询该显示器时。

### displayIds

枚举当前连接的全部显示器编号。

```cangjie
public func displayIds(): Array<UInt32>
```

**返回值** `Array<UInt32>` — 显示器编号数组。

**异常**

- `CuiException` — SDL 无法枚举显示器时。

### allDisplayInfos

枚举全部显示器并逐台查询聚合信息。

```cangjie
public func allDisplayInfos(): Array<DisplayInfo>
```

**返回值** `Array<DisplayInfo>` — 与 [`displayIds`](#displayids) 顺序一致的信息数组。

**异常**

- `CuiException` — SDL 无法查询其中任何一台显示器时。

### fullscreenDisplayModes

枚举指定显示器支持的全屏显示模式。

调用前须已初始化视频子系统；本函数不会主动初始化。

```cangjie
public func fullscreenDisplayModes(id: UInt32): Array<DisplayMode>
```

**参数**

- `id`: `UInt32` — 显示器编号；须非零。

**返回值** `Array<DisplayMode>` — 支持的模式列表。

**异常**

- `CuiException` — 编号为零，或 SDL 无法枚举模式时。

### closestFullscreenDisplayMode

在指定显示器上查找与请求最接近的全屏显示模式；SDL 返回未找到时为 `None`。

调用前须已初始化视频子系统；本函数不会主动初始化。

```cangjie
public func closestFullscreenDisplayMode(id: UInt32, request: FullscreenModeRequest): ?DisplayMode
```

**参数**

- `id`: `UInt32` — 显示器编号；须非零。
- `request`: `FullscreenModeRequest` — 期望的分辨率、刷新率与高密度开关。

**返回值** `?DisplayMode` — 最接近的模式；SDL 返回 `false` 时为 `None`，这既可能表示没有匹配模式，也可能表示底层查询失败。

**异常**

- `CuiException` — 编号为零时。

### displayInfoForPoint

返回包含指定桌面坐标点的显示器信息。

调用前须已初始化视频子系统；本函数不会主动初始化。

```cangjie
public func displayInfoForPoint(point: Point): DisplayInfo
```

**参数**

- `point`: `Point` — 桌面坐标系中的点。

**返回值** `DisplayInfo` — 包含该点的显示器信息。

**异常**

- `CuiException` — SDL 无法定位或查询显示器时。

### displayInfoForRect

返回与指定桌面坐标矩形重叠最多的显示器信息。

调用前须已初始化视频子系统；本函数不会主动初始化。

```cangjie
public func displayInfoForRect(rect: Rect): DisplayInfo
```

**参数**

- `rect`: `Rect` — 桌面坐标系中的矩形。

**返回值** `DisplayInfo` — 对应显示器信息。

**异常**

- `CuiException` — SDL 无法定位或查询显示器时。
