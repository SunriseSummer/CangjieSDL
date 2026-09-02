[API 参考](../index.md) › [sdl](index.md) › RenderSamplingStatus

# RenderSamplingStatus

说明渲染器当前使用直接绘制、超采样，或为何退回直接绘制。

```cangjie
public enum RenderSamplingStatus {
    | Direct
    | Supersampled
    | AutomaticPixelBudget
    | TextureSizeLimit
    | OutputUnavailable
    | TargetAllocationFailure
}
```

| 值 | 含义 |
|---|---|
| `Direct` | 策略选择 1 倍绘制，不需要离屏目标。 |
| `Supersampled` | 已计划或成功建立大于 1 倍的离屏目标。 |
| `AutomaticPixelBudget` | 自动方案超过 32 Mi 个目标像素，改为直接绘制。 |
| `TextureSizeLimit` | 目标尺寸溢出，或超过 SDL 报告的最大纹理边长。 |
| `OutputUnavailable` | SDL 暂时无法提供有效输出尺寸。 |
| `TargetAllocationFailure` | 尺寸可行，但原生目标分配失败；同一尺寸不会每帧重复尝试。 |

窗口尺寸、DPI、设备重置或目标分配结果变化时，状态也可能变化。通过 [`Renderer.renderSamplingStats`](Renderer.md#rendersamplingstats) 查询当前值。
