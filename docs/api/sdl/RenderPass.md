[sdl](../index.md) › [sdl](index.md) › RenderPass

# RenderPass

`Renderer.beginRenderPass` / `beginRenderPassDamage` 返回的异常安全场景资源。`close()` 幂等并执行 `endScene`，因此 widget 绘制抛错也能恢复 render target、scale 与 clip；呈现仍显式调用，便于 resolve 后截图或分段剖析。

```cangjie
public class RenderPass <: Resource {
    public let damagePreserved: Bool
    public func close(): Unit
    public func isClosed(): Bool
}
```

`Renderer.renderFrame` 是完整 begin/draw/resolve/present 便利事务；body 抛错时执行 resolve 清理但不呈现残缺帧。
