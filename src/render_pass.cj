package sdl

/**
 * Exception-safe ownership of one begun renderer scene. `close()` resolves the scene exactly once;
 * presenting remains explicit so callers can snapshot or profile between resolve and present.
 */
public class RenderPass <: Resource {
    private let renderer: Renderer
    private var closed = false
    /** Whether the requested damage region could preserve pixels outside it. */
    public let damagePreserved: Bool

    internal init(renderer: Renderer, damagePreserved!: Bool) {
        this.renderer = renderer
        this.damagePreserved = damagePreserved
    }

    /** Resolves this pass; idempotent. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        renderer.endScene()
    }

    /**
     * Reports whether this pass has already resolved its scene.
     */
    public func isClosed(): Bool {
        closed
    }
}

extend Renderer {
    /** Begins a full render pass whose resource lifetime guarantees `endScene`. */
    public func beginRenderPass(logicalWidth: Float32, logicalHeight: Float32, clearColor: Color): RenderPass {
        beginScene(logicalWidth, logicalHeight, clearColor)
        RenderPass(this, damagePreserved: false)
    }

    /** Begins a damage-aware pass and reports whether the persistent target preserved other pixels. */
    public func beginRenderPassDamage(
        logicalWidth: Float32,
        logicalHeight: Float32,
        clearColor: Color,
        damage: Rect
    ): RenderPass {
        RenderPass(this, damagePreserved: beginSceneDamage(logicalWidth, logicalHeight, clearColor, damage))
    }

    /** Full begin/draw/resolve/present transaction with deterministic resolve on exceptions. */
    public func renderFrame(
        logicalWidth: Float32,
        logicalHeight: Float32,
        clearColor: Color,
        body: () -> Unit
    ): Unit {
        let pass = beginRenderPass(logicalWidth, logicalHeight, clearColor)
        try {
            body()
        } finally {
            pass.close()
        }
        present()
    }
}
