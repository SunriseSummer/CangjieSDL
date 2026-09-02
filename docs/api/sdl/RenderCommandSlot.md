[API 参考](../index.md) › [sdl](index.md) › RenderCommandSlot

# RenderCommandSlot

`RenderCommandSlot` 是父命令缓冲中的稳定子节点引用。父缓冲录制一次后，可以通过 `replace` 换入新的子缓冲，而不必把整棵命令树重新复制到所有祖先。它适合上层 GUI 框架的保留式场景树和局部更新。

```cangjie
public class RenderCommandSlot {
    public init()
    public func replace(buffer: RenderCommandBuffer): Unit
    public func clear(): Unit
    public func setReplayBounds(bounds: Rect): Unit
    public func isReplayable(renderer: Renderer): Bool
    public func isReplayableIntersecting(renderer: Renderer, damage: Rect): Bool
    public func replay(renderer: Renderer): Bool
    public func replayIntersecting(renderer: Renderer, damage: Rect): Bool
    public func paintBounds(): ?Rect
    public func contentRevision(): UInt64
    public func hasCommands(): Bool
}
```

## 所有权与有效性

第一次 `replace` 会把槽绑定到子缓冲的 `Renderer`。之后不能换入其他渲染器创建的缓冲，也不能形成直接或间接引用环。绑定后，替换、清空、验证、重放和查询都只能在渲染器的创建线程执行。

`clear` 会移除当前子缓冲。所有引用这个槽的父缓冲随后都不可完整重放，直到换入新的有效缓冲。

## 稳定边界与局部重放

`setReplayBounds` 为槽设置一个保守的固定边界，实际绘制必须完全落在其中。边界首次设置后只能重复写入相同值；几何范围发生变化时应创建新槽。这个限制可防止父缓冲继续使用已经过时的空间索引。

连续且都具有稳定边界的槽会在父缓冲录制结束时建立空间索引。局部重放通常只访问与损坏区域相交的节点；缺少稳定边界时会安全退回线性检查。空间索引只优化查找，不改变原有绘制顺序。

## 示例

```cangjie verify role=complete
package docexample

import sdl.{Color, Rect, RenderCommandSlot, Renderer}

main(): Unit {
    let renderer = Renderer.headless()
    let slot = RenderCommandSlot()
    slot.setReplayBounds(Rect(0.0, 0.0, 40.0, 20.0))
    slot.replace(renderer.recordCommands {
        renderer.fill(Rect(0.0, 0.0, 40.0, 20.0), Color.rgb(30, 70, 110))
    })

    let parent = renderer.recordCommands {
        if (!slot.replay(renderer)) {
            throw IllegalStateException("child commands are unavailable")
        }
    }

    slot.replace(renderer.recordCommands {
        renderer.fill(Rect(0.0, 0.0, 40.0, 20.0), Color.rgb(90, 130, 170))
    })
    let _ = parent.replay(renderer)
}
```

`contentRevision()` 在内容替换、清空或首次设置边界时递增，可用于增量更新诊断。`hasCommands()` 只表示当前是否安装了子缓冲；是否可以安全播放应查询 `isReplayable`。

普通的单层缓存直接使用 [`RenderCommandBuffer`](RenderCommandBuffer.md) 即可。只有在子树频繁变化而父结构长期稳定时，才需要引入槽和空间索引。
