[sdl](../index.md) › [sdl](index.md) › RenderSamplingStats

# RenderSamplingStats

`sdl` 包中的 public struct

Renderer 当前采样决策的只读快照。

```cangjie
public struct RenderSamplingStats {
    public let requestedFactor: Int32
    public let selectedFactor: Int32
    public let targetWidth: Int32
    public let targetHeight: Int32
    public let estimatedTargetBytes: UInt64
    public let maxTextureSize: Int32
    public let status: RenderSamplingStatus
}
```

- `requestedFactor`：`WindowSpec.supersample` 的原始请求，0 表示 Auto。
- `selectedFactor`：密度、预算和硬件预检后的选择，最小为 1；原生分配是否成功由 `status` 表示。
- `targetWidth`、`targetHeight`：计划离屏目标尺寸；直接绘制时为 0。
- `estimatedTargetBytes`：按 RGBA8 计算的目标字节数，不包含驱动对齐或其他纹理。
- `maxTextureSize`：SDL renderer 报告的最大纹理边长；无法查询时为 `Int32.Max`。
- `status`：采样或回退原因，见 [`RenderSamplingStatus`](RenderSamplingStatus.md)。

快照不进行 GPU 查询或分配，可用于性能 overlay、遥测和基准环境记录。
