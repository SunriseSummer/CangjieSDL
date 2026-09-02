[API 参考](../index.md) › [sdl](index.md) › RenderCommandBuffer

# RenderCommandBuffer

由一个 [`Renderer`](Renderer.md) 录制的不可变绘制命令序列。缓冲保存绘制参数和纹理引用，不保存应用闭包；重复播放时不会再次执行最初的业务或组件代码。

```cangjie
public class RenderCommandBuffer {
    public func stats(): RenderCommandBufferStats
    public func hasSceneReferences(): Bool
    public func paintBounds(): ?Rect
    public func isReplayable(renderer: Renderer): Bool
    public func isReplayableIntersecting(renderer: Renderer, damage: Rect): Bool
    public func replay(renderer: Renderer): Bool
    public func replayIntersecting(renderer: Renderer, damage: Rect): Bool
}
```

## 何时使用

静态背景、图标或其他重复绘制内容可通过 `Renderer.recordCommands` 录制一次，再跨帧重放。缓冲只接受创建它的渲染器；缩放或设备状态变化、捕获的纹理关闭，或者引用的子槽无效后，重放会在绘制前返回 `false`。

`replayIntersecting` 用于局部重绘。它始终保留当前缓冲中的直接命令，只跳过绘制边界与 `damage` 不相交的子槽。相交部分会先完整验证，因此不会出现画到一半才发现资源失效的情况。

所有公开方法都只能在所属渲染器的创建线程调用，否则抛出 `IllegalStateException`。

## 示例

```cangjie verify role=complete
package docexample

import sdl.{Color, Rect, Renderer}

main(): Unit {
    let renderer = Renderer.headless()
    let commands = renderer.recordCommands {
        renderer.fill(Rect(0.0, 0.0, 120.0, 40.0), Color.rgb(30, 70, 110))
    }
    if (!commands.replay(renderer)) {
        throw IllegalStateException("render commands must be recorded again")
    }
    println("commands=${commands.stats().commandCount}")
}
```

## 录制限制

录制体内可以调用几何、文字、纹理和裁剪绘制方法。`beginScene`、`present`、视口或缩放修改、截图以及其他帧或设备控制会抛出 `IllegalStateException`。

传入的可变点集和透明度列表会在录制时复制，调用方后续修改不会改变缓冲。相邻且类型、颜色相同的点、矩形轮廓和填充矩形会在录制结束时合并为批次，但不会跨越颜色、裁剪、文字或纹理边界，也不会改变绘制顺序。

`paintBounds()` 返回考虑裁剪后的保守逻辑边界；没有绘制命令时返回 `None`。文字、描边、软边和旋转内容会适当扩张边界。缓冲包含子槽时，边界按子槽的当前内容计算。

## 另请参阅

- [`RenderCommandSlot`](RenderCommandSlot.md) — 在父缓冲不变的情况下替换子命令。
- [`RenderCommandBufferStats`](RenderCommandBufferStats.md) — 查询命令、批处理、资源和重放计数。
- [`Renderer.recordCommands`](Renderer.md#recordcommands) — 创建命令缓冲。
