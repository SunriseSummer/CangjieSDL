[sdl](../index.md) › [sdl](index.md) › RenderSamplingStatus

# RenderSamplingStatus

`sdl` 包中的 public enum

说明 Renderer 当前采样计划及其回退原因。

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

- `Direct`：策略选择 1x，不需要离屏目标。
- `Supersampled`：已计划或建立大于 1x 的离屏目标。
- `AutomaticPixelBudget`：Auto 的目标超过 32 Mi 像素，选择直接绘制。
- `TextureSizeLimit`：乘法或 SDL 最大纹理边长使目标不可表示。
- `OutputUnavailable`：SDL 暂时不能提供有效输出尺寸。
- `TargetAllocationFailure`：尺寸可行，但原生目标分配失败；同尺寸不会逐帧重试抖动。

状态随 DPI、输出尺寸、设备重置或目标分配变化；通过 [`Renderer.renderSamplingStats`](Renderer.md#rendersamplingstats) 获取。
