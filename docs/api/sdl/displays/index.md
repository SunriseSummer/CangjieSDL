[sdl](../../index.md) › sdl.displays

# sdl.displays

```cangjie
import sdl.displays.*
```

显示器信息查询与全屏显示模式枚举。`primaryDisplayInfo`、`displayIds` 与经后者实现的 `allDisplayInfos` 会按需初始化视频子系统；其余查询不会主动初始化，须先创建窗口或调用前述入口。坐标沿用 [`sdl`](../index.md) 包的 [`Rect`](../Rect.md)/[`Point`](../Point.md)（此处为桌面坐标）。多显示器布局、DPI 感知的窗口摆放与全屏模式选择从这里入手。

## 类型

**结构体**

| 类型 | 说明 |
|---|---|
| [`DisplayGeometry`](DisplayGeometry.md) | 显示器的几何信息：完整边界、去除任务栏等系统区域后的可用边界，以及系统建议的内容缩放。 |
| [`DisplayInfo`](DisplayInfo.md) | 一台显示器的聚合信息：编号、名称、几何、朝向与显示模式。 |
| [`DisplayMode`](DisplayMode.md) | 显示器可用的分辨率、像素密度与刷新率组合。 |
| [`DisplayModes`](DisplayModes.md) | 显示器的桌面显示模式与当前显示模式；SDL 无法提供时对应项为 `None`。 |
| [`DisplayOrientations`](DisplayOrientations.md) | 显示器的自然朝向与当前朝向的组合。 |
| [`FullscreenModeRequest`](FullscreenModeRequest.md) | 查找最接近的全屏显示模式时的期望参数：目标分辨率、刷新率与是否考虑高像素密度模式。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`DisplayOrientation`](DisplayOrientation.md) | 显示器的朝向。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`primaryDisplayInfo`](functions.md#primarydisplayinfo) | 返回主显示器的聚合信息。 |
| [`displayInfo`](functions.md#displayinfo) | 返回指定编号显示器的聚合信息。 |
| [`displayIds`](functions.md#displayids) | 枚举当前连接的全部显示器编号。 |
| [`allDisplayInfos`](functions.md#alldisplayinfos) | 枚举全部显示器并逐台查询聚合信息。 |
| [`fullscreenDisplayModes`](functions.md#fullscreendisplaymodes) | 枚举指定显示器支持的全屏显示模式。 |
| [`closestFullscreenDisplayMode`](functions.md#closestfullscreendisplaymode) | 在指定显示器上查找与请求最接近的全屏显示模式；SDL 返回未找到时为 `None`。 |
| [`displayInfoForPoint`](functions.md#displayinfoforpoint) | 返回包含指定桌面坐标点的显示器信息。 |
| [`displayInfoForRect`](functions.md#displayinfoforrect) | 返回与指定桌面坐标矩形重叠最多的显示器信息。 |
