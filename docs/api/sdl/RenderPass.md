[API 参考](../index.md) › [sdl](index.md) › RenderPass

# RenderPass

`Renderer.beginRenderPass` 和 `beginRenderPassDamage` 返回的场景资源。`close()` 会结束场景并恢复渲染目标、缩放和裁剪状态；重复关闭是安全的。画面提交仍需显式调用 `Renderer.present()`，因此可以在场景结束后、提交前插入截图或性能记录。

```cangjie
public class RenderPass <: Resource {
    public let damagePreserved: Bool
    public func close(): Unit
    public func isClosed(): Bool
}
```

`damagePreserved` 是构造时确定的只读结果，表示本次是否成功保留局部重绘区域以外的上一帧内容。

`RenderPass` 与所属 `Renderer` 使用相同的线程约束。`close()` 和 `isClosed()` 都只能在渲染器的创建线程调用，否则抛出 `IllegalStateException`。

普通整帧绘制优先使用 `Renderer.renderFrame`，它会自动开始、结束并提交场景。只有需要在结束和提交之间执行其他操作时，才直接使用 `RenderPass`。
