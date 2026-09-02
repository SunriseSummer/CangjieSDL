[API 参考](../index.md) › [sdl](index.md) › RenderSamplingStats

# RenderSamplingStats

渲染器当前采样方案的只读快照。查询不会访问 GPU、分配资源或改变渲染状态。

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

| 字段 | 含义 |
|---|---|
| `requestedFactor` | `WindowSpec.supersample` 的原始值；0 表示自动选择。 |
| `selectedFactor` | 密度、尺寸和资源检查后的倍率，最小为 1。 |
| `targetWidth`、`targetHeight` | 计划创建的离屏目标尺寸；直接绘制时为 0。 |
| `estimatedTargetBytes` | 按 RGBA8 估算的目标字节数，不含驱动对齐和附加纹理。 |
| `maxTextureSize` | SDL 渲染器报告的最大纹理边长；无法查询时为 `Int32.Max`。 |
| `status` | 当前采用或放弃超采样的原因。 |

通过 [`Renderer.renderSamplingStats`](Renderer.md#rendersamplingstats) 获取快照。
