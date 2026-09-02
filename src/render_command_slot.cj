package sdl

/**
 * A stable indirection in a hierarchical display list. Parent buffers retain the slot identity,
 * while an incremental renderer can atomically replace the immutable child buffer without copying
 * its commands or resources into every ancestor. A cleared or otherwise invalid child makes every
 * referencing ancestor fail validation before any drawing is submitted. Once bound, every public
 * operation is confined to the owner Renderer's thread.
 */
public class RenderCommandSlot {
    private var owner: ?Renderer = None
    private var current: ?RenderCommandBuffer = None
    private var replayBounds: ?Rect = None
    private var replayBoundsConfigured = false
    private var revision: UInt64 = UInt64(0)

    public init() {}

    /** Replaces the referenced immutable command buffer, rejecting direct or transitive cycles. */
    public func replace(buffer: RenderCommandBuffer): Unit {
        buffer.ensureOwnerAccess("replace render command slot")
        match (owner) {
            case Some(existing) =>
                if (!refEq(existing, buffer.rendererOwner())) {
                    throw IllegalArgumentException("A render command slot cannot change its owning Renderer")
                }
            case None => owner = Some(buffer.rendererOwner())
        }
        if (buffer.referencesSlot(this)) {
            throw IllegalArgumentException("Render command slots must form an acyclic hierarchy")
        }
        current = Some(buffer)
        revision = nextRenderCommandEpoch(revision)
    }

    /** Removes the current child buffer; referencing parents become unreplayable. */
    public func clear(): Unit {
        ensureSlotAccess("clear render command slot")
        if (current.isSome()) {
            current = None
            revision = nextRenderCommandEpoch(revision)
        }
    }

    /**
     * Installs a conservative stable bound for persistent spatial indexing. The bound is part of
     * this slot's identity and cannot change after its first configuration; geometry changes must
     * use a new slot so an old ancestor can never revive with a stale spatial index.
     */
    public func setReplayBounds(bounds: Rect): Unit {
        ensureSlotAccess("update render command slot bounds")
        let normalized: ?Rect = if (bounds.w > 0.0 && bounds.h > 0.0) {
            Some(bounds)
        } else {
            None
        }
        if (replayBoundsConfigured) {
            if (sameOptionalSlotBounds(replayBounds, normalized)) {
                return
            }
            throw IllegalStateException("A render command slot's stable replay bounds cannot change; use a new slot")
        }
        replayBounds = normalized
        replayBoundsConfigured = true
        revision = nextRenderCommandEpoch(revision)
    }

    /** Whether this slot and its complete transitive command subtree can be replayed. */
    public func isReplayable(renderer: Renderer): Bool {
        ensureSlotAccess("validate render command slot")
        isReplayableValidated(renderer)
    }

    internal func isReplayableValidated(renderer: Renderer): Bool {
        match (current) {
            case Some(buffer) => buffer.isReplayableValidated(renderer)
            case None => false
        }
    }

    /** Whether the current child subtree intersecting `damage` can be replayed atomically. */
    public func isReplayableIntersecting(renderer: Renderer, damage: Rect): Bool {
        ensureSlotAccess("validate damage-intersecting render command slot")
        isReplayableIntersectingValidated(renderer, damage)
    }

    internal func isReplayableIntersectingValidated(renderer: Renderer, damage: Rect): Bool {
        match (current) {
            case Some(buffer) => buffer.isReplayableIntersectingValidated(renderer, damage)
            case None => false
        }
    }

    /**
     * Replays the current child, or records one stable reference when called inside a parent
     * recording. Returns false without appending or drawing when the complete subtree is invalid.
     */
    public func replay(renderer: Renderer): Bool {
        ensureSlotAccess("replay render command slot")
        match (current) {
            case Some(buffer) =>
                if (!buffer.isReplayableValidated(renderer)) {
                    return false
                }
                if (renderer.isRecordingCommands()) {
                    renderer.appendRecordedCommand(RenderCommand.ReplaySlot(this))
                    true
                } else {
                    let noCull: ?Rect = None
                    buffer.replayValidated(renderer, noCull)
                    true
                }
            case None => false
        }
    }

    /** Replays only nested child slots whose paint bounds intersect `damage`. */
    public func replayIntersecting(renderer: Renderer, damage: Rect): Bool {
        ensureSlotAccess("replay damage-intersecting render command slot")
        match (current) {
            case Some(buffer) =>
                if (!buffer.isReplayableIntersectingValidated(renderer, damage)) {
                    return false
                }
                if (renderer.isRecordingCommands()) {
                    renderer.appendRecordedCommand(RenderCommand.ReplaySlot(this))
                    true
                } else {
                    buffer.replayValidated(renderer, Some(damage))
                    true
                }
            case None => false
        }
    }

    /** Current child paint bounds, resolved lazily through the stable reference. */
    public func paintBounds(): ?Rect {
        ensureSlotAccess("inspect render command slot bounds")
        paintBoundsValidated()
    }

    internal func paintBoundsValidated(): ?Rect {
        match (current) {
            case Some(buffer) => buffer.paintBoundsValidated()
            case None => None
        }
    }

    /** Monotonic replacement/clear revision, intended for patch diagnostics. */
    public func contentRevision(): UInt64 {
        ensureSlotAccess("inspect render command slot revision")
        revision
    }

    /** Whether a child buffer is currently installed. */
    public func hasCommands(): Bool {
        ensureSlotAccess("inspect render command slot")
        current.isSome()
    }

    internal func referencesSlot(target: RenderCommandSlot): Bool {
        match (current) {
            case Some(buffer) => buffer.referencesSlot(target)
            case None => false
        }
    }

    internal func replayValidatedInline(renderer: Renderer, cull: ?Rect): Unit {
        match (current) {
            case Some(buffer) => buffer.replayValidatedInline(renderer, cull)
            case None => throw IllegalStateException("A validated render command slot was cleared during replay")
        }
    }

    internal func intersectsCull(cull: ?Rect): Bool {
        match (cull) {
            case Some(damage) => match (paintBoundsValidated()) {
                case Some(bounds) =>
                    let overlap = bounds.intersection(damage)
                    overlap.w > 0.0 && overlap.h > 0.0
                case None => true
            }
            case None => true
        }
    }

    internal func stableReplayBounds(): ?Rect {
        replayBounds
    }

    private func ensureSlotAccess(operation: String): Unit {
        match (owner) {
            case Some(renderer) => renderer.ensureRenderAccess(operation)
            case None => ()
        }
    }
}

private func sameOptionalSlotBounds(left: ?Rect, right: ?Rect): Bool {
    match ((left, right)) {
        case (Some(a), Some(b)) => a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h
        case (None, None) => true
        case _ => false
    }
}
