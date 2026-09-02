[API 参考](../index.md) › [sdl](index.md) › RenderCommandBufferStats

# RenderCommandBufferStats

命令缓冲的只读统计，用于观察规模、批处理效果和重放次数。

```cangjie
public struct RenderCommandBufferStats {
    public let commandCount: Int64
    public let clipCommandCount: Int64
    public let resourceCount: Int64
    public let estimatedBytes: UInt64
    public let replayCount: UInt64
    public let batchSubmissionCount: UInt64
    public let batchedCommandCount: UInt64
    public let compiledBatchCount: Int64
}
```

| 字段 | 含义 |
|---|---|
| `commandCount` | 按绘制顺序保存的命令总数。 |
| `clipCommandCount` | 其中的裁剪入栈和出栈命令数；成功录制时两者平衡。 |
| `resourceCount` | 按对象身份去重后的纹理数量。 |
| `estimatedBytes` | 命令及复制数据的保守内存估算，不是分配器的精确占用。 |
| `replayCount` | 成功重放或嵌入外层录制的累计次数。 |
| `batchSubmissionCount` | 累计提交到后端的批次数。 |
| `batchedCommandCount` | 累计并入批次的原始点或矩形命令数。 |
| `compiledBatchCount` | 录制结束时生成的不可变批次数，与重放次数无关。 |

通过 [`RenderCommandBuffer.stats`](RenderCommandBuffer.md) 获取该结构体。
