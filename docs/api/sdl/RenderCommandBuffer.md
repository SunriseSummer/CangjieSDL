[sdl](../index.md) › [sdl](index.md) › RenderCommandBuffer

# RenderCommandBuffer

由一个 [`Renderer`](Renderer.md) 录制的不可变绘制命令序列。命令保存颜色、几何、clip、文本参数和显式
[`Texture`](Texture.md) 句柄，不保存可执行闭包，也不截取祖先背景；因此它适合作为透明 display list 重放，
而不是每节点 GPU 位图缓存。

```cangjie
public class RenderCommandBuffer {
    public func stats(): RenderCommandBufferStats
    public func paintBounds(): ?Rect
    public func isReplayable(renderer: Renderer): Bool
    public func replay(renderer: Renderer): Bool
}
```

缓冲只能交回创建它的 Renderer。显式 renderer epoch 改变（例如 `setScale` 或设备资源释放）以及任一捕获
Texture 已关闭时，`isReplayable` / `replay` 在提交任何命令前返回 `false`；调用方应重新录制或走普通绘制。
底层绘制本身失败时仍抛出 `SdlException`。重放始终恢复调用方进入时的 clip 栈，即使中途抛错也不会污染
后续兄弟绘制。

连续至少四条、类型与颜色相同的 point/rect/fill-rect 会在录制完成时编译为批次。回放不再临时构造 Cangjie 集合，Renderer 还会复用按需扩容的原生提交缓冲。任何颜色、clip、文本、纹理或其他命令都会切断批次；实现不按材质跨命令排序，因此透明混合与 z 序保持不变。批次诊断见 [`RenderCommandBufferStats`](RenderCommandBufferStats.md)。

嵌套录制是隔离的；把内层缓冲 `replay` 到仍在录制的同一 Renderer，会按原 z 序把值命令附加进外层，
不会执行 widget 闭包。录制时传入的可变点集和 alpha 集会复制，之后修改调用方集合不会改变缓冲。

## 示例

```cangjie
let commands = renderer.recordCommands {
    renderer.pushClip(Rect(0.0, 0.0, 120.0, 60.0))
    renderer.fillRoundedRect(Rect(4.0, 4.0, 112.0, 52.0), 8.0, Color.rgb(35, 48, 70))
    renderer.text("cached", 16.0, 18.0, Color.rgb(245, 245, 248))
    renderer.popClip()
}

if (!commands.replay(renderer)) {
    // renderer/resource epoch changed: re-record the current state.
}
```

`beginScene`、`present`、视口/缩放修改、截图和其他帧/设备控制不能出现在录制体中；调用会抛出
`IllegalStateException`，避免录制时意外改变真实 SDL 状态。

`paintBounds()` 返回考虑嵌套 clip 后的保守逻辑像素并集；文本使用同一字体度量，描边、软边与旋转内容向外扩张。无绘制命令时为 `None`。它适合 damage、空间索引和诊断，不能替代 clip 或 z 序正确性检查。
