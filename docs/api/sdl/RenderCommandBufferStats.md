[sdl](../index.md) › [sdl](index.md) › RenderCommandBufferStats

# RenderCommandBufferStats

命令缓冲的稳定诊断计数，用于内存规模看护、性能报告和重放命中分析。

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

- `commandCount`：按 z 序保存的绘制与 clip 命令数。
- `clipCommandCount`：其中的 push/pop clip 数；成功录制必定平衡。
- `resourceCount`：按对象身份去重后的 Texture 句柄数。
- `estimatedBytes`：命令及复制载荷的保守运行时估算；用于比较规模，不代表分配器精确占用。
- `replayCount`：本缓冲成功重放或嵌入外层录制的累计次数。
- `batchSubmissionCount`：成功重放中识别出的相邻同色 point/rect/fill-rect 批次数；真实后端每批对应一次 SDL 批量提交。
- `batchedCommandCount`：累计并入这些批次的原始命令数。批处理不跨越颜色、clip、文本或纹理边界，也不重排 z 序。
- `compiledBatchCount`：录制结束时生成的不可变批次数；与重放次数无关。
