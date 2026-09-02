[sdl](../index.md) › [sdl](index.md) › RenderCommandSlot

# RenderCommandSlot

一个由单一 [`Renderer`](Renderer.md) 拥有的稳定层次化 display-list 引用。父
[`RenderCommandBuffer`](RenderCommandBuffer.md) 在录制期间调用 `slot.replay(renderer)` 时只保存一个槽引用；
之后 `replace` 可以原子替换不可变子缓冲，而不把子命令、纹理句柄和编译批次复制到所有祖先。

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

第一次 `replace` 把槽永久绑定到该缓冲的 Renderer；以后换入其他 Renderer 的缓冲抛出
`IllegalArgumentException`。直接或传递形成引用环同样被拒绝。绑定后全部公开操作——替换、清空、配置、
验证、重放和诊断读取——都必须发生在 Renderer 所属线程，错误线程抛出 `IllegalStateException`。未绑定空槽
还没有线程身份：可以预配一次稳定边界或查询其为空；第一次 `replace` 才原子绑定 Renderer，此后不再转移。

`setReplayBounds` 为持久空间索引配置保守边界；实际子缓冲绘制必须完全包含在该边界中。边界是 slot 身份的一部分，
第一次配置后只能重复传入相同值，改变它会抛出 `IllegalStateException`。几何变化应清空旧 slot 并创建新 slot，
使引用旧身份的祖先永久保持不可重放，不能带着过期 BVH 复活。连续且全部具有稳定边界的 slot run 会在父缓冲
录制完成时建立保持声明/z 序的持久 BVH；任一槽没有边界时自动使用安全的线性查询。

`clear` 后所有引用该槽的祖先都会在提交任何绘制前变为不可重放。Renderer/resource epoch 不匹配、纹理已关闭
或任一后代槽无效也会沿层次传播为 `false`；不会出现“父列表已画一半才发现子列表失效”。根缓冲只保存/恢复
一次 clip 栈，已验证子缓冲以内联方式保持原 z 序和配对 clip，因此层次数量不会引入重复 clip 快照。
`replayIntersecting` 只预验证并重放与 damage 相交的前沿；区外无效槽不会阻塞本次局部重放，相交集合仍在提交
任何绘制前完整验证。

```cangjie
let slot = RenderCommandSlot()
slot.setReplayBounds(Rect(0.0, 0.0, 40.0, 20.0))
slot.replace(renderer.recordCommands {
    renderer.fill(Rect(0.0, 0.0, 40.0, 20.0), Color.rgb(30, 70, 110))
})

let parent = renderer.recordCommands {
    if (!slot.replay(renderer)) {
        throw IllegalStateException("child scene is not ready")
    }
}

// 父缓冲身份保持不变；下一次重放会看到新子内容。
slot.replace(renderer.recordCommands {
    renderer.fill(Rect(0.0, 0.0, 40.0, 20.0), Color.rgb(90, 130, 170))
})
let _ = parent.replay(renderer)
```

普通单层缓存继续直接使用 `RenderCommandBuffer`。`RenderCommandSlot` 面向 retained scene graph、编辑器画布和
其他“子树更新频繁、祖先结构稳定”的内核；每个很小的绘制节点都建立槽会增加一次间接调用，应由实测决定边界。
