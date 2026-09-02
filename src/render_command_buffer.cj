package sdl

import std.collection.ArrayList

/*
 * Value commands deliberately retain parameters and resource handles, never executable closures.
 * This keeps replay deterministic, inspectable, and independent of skipped widget object graphs.
 */
internal enum RenderCommand {
    | PushClip(Rect)
    | PopClip
    | DrawPoint(Float32, Float32, Color)
    | DrawLine(Float32, Float32, Float32, Float32, Color)
    | DrawRect(Rect, Color)
    | FillRect(Rect, Color)
    | StrokeLine(Float32, Float32, Float32, Float32, Pen)
    | StrokeRoundedRect(Rect, Float32, Pen)
    | StrokeRoundedRectDashed(Rect, Float32, Pen, Float32, Float32)
    | FillRoundedRect(Rect, Float32, Color)
    | FillRoundedRectGradient(Rect, Float32, Color, Color, Bool)
    | FillPerCornerRoundedRect(Rect, Color, Float32, Float32, Float32, Float32)
    | FillRoundedRectSoft(Rect, Float32, Color, Float32)
    | StrokeCircle(Float32, Float32, Float32, Pen, Int64)
    | FillCircle(Float32, Float32, Float32, Color)
    | FillConvexPolygon(ArrayList<Point>, Color)
    | DrawTexturedStrip(Texture, ArrayList<Point>, ArrayList<Point>, ?ArrayList<Float32>)
    | DrawText(String, Float32, Float32, Color, Float32, FontStyle, ?String)
    | DrawTextRotated(String, Float32, Float32, Float64, Color, Float32, FontStyle, ?String)
    | DrawTexture(Texture, Rect, ?Rect)
    | DrawTextureRotated(Texture, Rect, Float64, TextureRenderOptions)
    | ReplaySlot(RenderCommandSlot)
}

/* Primitive runs are compiled once when recording finishes, never rebuilt on every replay. */
internal enum ReplayCommand {
    | Single(RenderCommand)
    | FillRects(Array<Rect>, Color)
    | DrawRects(Array<Rect>, Color)
    | DrawPoints(Array<Point>, Color)
    | SlotRun(RenderCommandSlotRun)
}

/** Stable counters describing one immutable renderer command buffer. */
public struct RenderCommandBufferStats {
    public let commandCount: Int64
    public let clipCommandCount: Int64
    public let resourceCount: Int64
    public let estimatedBytes: UInt64
    public let replayCount: UInt64
    public let batchSubmissionCount: UInt64
    public let batchedCommandCount: UInt64
    public let compiledBatchCount: Int64

    internal init(
        commandCount: Int64,
        clipCommandCount: Int64,
        resourceCount: Int64,
        estimatedBytes: UInt64,
        replayCount: UInt64,
        batchSubmissionCount: UInt64,
        batchedCommandCount: UInt64,
        compiledBatchCount: Int64
    ) {
        this.commandCount = commandCount
        this.clipCommandCount = clipCommandCount
        this.resourceCount = resourceCount
        this.estimatedBytes = estimatedBytes
        this.replayCount = replayCount
        this.batchSubmissionCount = batchSubmissionCount
        this.batchedCommandCount = batchedCommandCount
        this.compiledBatchCount = compiledBatchCount
    }
}

/**
 * An immutable, ordered display list recorded by one Renderer. Commands contain copied values and
 * explicit Texture handles; replay never re-enters the widget closures that produced them. Every
 * public operation is confined to the owner Renderer's thread; recursive validation uses an
 * already-checked internal path so hierarchy depth does not multiply ownership checks.
 */
public class RenderCommandBuffer {
    private let owner: Renderer
    private let ownerEpoch: UInt64
    private let commands: Array<RenderCommand>
    private let replayCommands: Array<ReplayCommand>
    private let clipCommandCount: Int64
    private let resources: Array<Texture>
    private let slots: Array<RenderCommandSlot>
    private let estimatedBytes: UInt64
    private let bounds: ?Rect
    private let entryClip: ?Rect
    private let hasSlots: Bool
    private var replayCount: UInt64 = UInt64(0)
    private var batchSubmissionCount: UInt64 = UInt64(0)
    private var batchedCommandCount: UInt64 = UInt64(0)

    internal init(
        owner: Renderer,
        ownerEpoch: UInt64,
        commands: Array<RenderCommand>,
        replayCommands: Array<ReplayCommand>,
        clipCommandCount: Int64,
        resources: Array<Texture>,
        slots: Array<RenderCommandSlot>,
        estimatedBytes: UInt64,
        bounds: ?Rect,
        entryClip: ?Rect,
        hasSlots: Bool
    ) {
        this.owner = owner
        this.ownerEpoch = ownerEpoch
        this.commands = commands
        this.replayCommands = replayCommands
        this.clipCommandCount = clipCommandCount
        this.resources = resources
        this.slots = slots
        this.estimatedBytes = estimatedBytes
        this.bounds = bounds
        this.entryClip = entryClip
        this.hasSlots = hasSlots
    }

    /** Current command, clip, resource, memory-estimate, and successful-replay counters. */
    public func stats(): RenderCommandBufferStats {
        ensureOwnerAccess("inspect render command buffer statistics")
        RenderCommandBufferStats(
            commands.size,
            clipCommandCount,
            resources.size,
            estimatedBytes,
            replayCount,
            batchSubmissionCount,
            batchedCommandCount,
            compiledBatchCount(replayCommands)
        )
    }

    /** Whether this buffer retains stable child scene slots instead of flattening all child commands. */
    public func hasSceneReferences(): Bool {
        ensureOwnerAccess("inspect render command hierarchy")
        hasSlots
    }

    /** Conservative logical-pixel union of recorded paint after clip intersection. */
    public func paintBounds(): ?Rect {
        ensureOwnerAccess("inspect render command buffer bounds")
        paintBoundsValidated()
    }

    internal func paintBoundsValidated(): ?Rect {
        if (hasSlots) {
            renderCommandBounds(owner, commands, entryClip)
        } else {
            bounds
        }
    }

    /**
     * Whether this buffer can be replayed without partially drawing: the Renderer/epoch match and
     * every captured Texture is still open.
     */
    public func isReplayable(renderer: Renderer): Bool {
        ensureOwnerAccess("validate render command buffer")
        isReplayableValidated(renderer)
    }

    internal func isReplayableValidated(renderer: Renderer): Bool {
        if (!localResourcesAreReplayable(renderer)) {
            return false
        }
        for (slot in slots) {
            if (!slot.isReplayableValidated(renderer)) {
                return false
            }
        }
        true
    }

    /** Whether every child subtree intersecting `damage` can be replayed without partial drawing. */
    public func isReplayableIntersecting(renderer: Renderer, damage: Rect): Bool {
        ensureOwnerAccess("validate damage-intersecting render commands")
        isReplayableIntersectingValidated(renderer, damage)
    }

    internal func isReplayableIntersectingValidated(renderer: Renderer, damage: Rect): Bool {
        localResourcesAreReplayable(renderer) && replayCommandsAreReplayableIntersectingValidated(renderer,
            replayCommands, damage)
    }

    /**
     * Replays commands in their original z order. Returns false before drawing when the owner,
     * renderer epoch, or a Texture resource is invalid. The caller's clip stack is always restored.
     */
    public func replay(renderer: Renderer): Bool {
        ensureOwnerAccess("replay render commands")
        let noCull: ?Rect = None
        replayWithCull(renderer, noCull)
    }

    /** Replays only hierarchical child slots whose current paint bounds intersect `damage`. */
    public func replayIntersecting(renderer: Renderer, damage: Rect): Bool {
        ensureOwnerAccess("replay damage-intersecting render commands")
        replayWithCull(renderer, Some(damage))
    }

    private func replayWithCull(renderer: Renderer, cull: ?Rect): Bool {
        let replayable = match (cull) {
            case Some(damage) => isReplayableIntersectingValidated(renderer, damage)
            case None => isReplayableValidated(renderer)
        }
        if (!replayable) {
            return false
        }
        replayValidated(renderer, cull)
        true
    }

    private func localResourcesAreReplayable(renderer: Renderer): Bool {
        if (!refEq(owner, renderer) || ownerEpoch != renderer.renderCommandEpoch()) {
            return false
        }
        for (resource in resources) {
            if (resource.isClosed()) {
                return false
            }
        }
        true
    }

    /* Replays a graph already validated by its root without repeating transitive checks. */
    internal func replayValidated(renderer: Renderer, cull: ?Rect): Unit {
        if (renderer.isRecordingCommands()) {
            for (command in commands) {
                renderer.appendRecordedCommand(command)
            }
            replayCount = nextRenderCommandEpoch(replayCount)
            return
        }
        let savedClips = renderer.captureCommandClipStack()
        var batchStats = ReplayBatchStats()
        try {
            batchStats = replayCompiledCommands(renderer, replayCommands, cull)
        } finally {
            renderer.restoreCommandClipStack(savedClips)
        }
        batchSubmissionCount += batchStats.submissions
        batchedCommandCount += batchStats.commands
        replayCount = nextRenderCommandEpoch(replayCount)
    }

    /* A child slot is balanced by construction, so its validated commands can share the root save. */
    internal func replayValidatedInline(renderer: Renderer, cull: ?Rect): Unit {
        let batchStats = replayCompiledCommands(renderer, replayCommands, cull)
        batchSubmissionCount += batchStats.submissions
        batchedCommandCount += batchStats.commands
        replayCount = nextRenderCommandEpoch(replayCount)
    }

    /* Whether this immutable buffer would create a cycle if installed into `target`. */
    internal func referencesSlot(target: RenderCommandSlot): Bool {
        for (slot in slots) {
            if (sameRenderCommandSlot(slot, target) || slot.referencesSlot(target)) {
                return true
            }
        }
        false
    }

    internal func rendererOwner(): Renderer {
        owner
    }

    internal func ensureOwnerAccess(operation: String): Unit {
        owner.ensureRenderAccess(operation)
    }
}

private struct ReplayBatchStats {
    let submissions: UInt64
    let commands: UInt64

    init(submissions!: UInt64 = UInt64(0), commands!: UInt64 = UInt64(0)) {
        this.submissions = submissions
        this.commands = commands
    }
}

private func replayCompiledCommands(
    renderer: Renderer,
    commands: Array<ReplayCommand>,
    cull: ?Rect
): ReplayBatchStats {
    var submissions: UInt64 = 0
    var batched: UInt64 = 0
    for (command in commands) {
        match (command) {
            case ReplayCommand.Single(value) => replayRenderCommand(renderer, value, cull)
            case ReplayCommand.FillRects(rects, color) =>
                renderer.fillBatch(rects, color)
                submissions += UInt64(1)
                batched += UInt64(rects.size)
            case ReplayCommand.DrawRects(rects, color) =>
                renderer.rectBatch(rects, color)
                submissions += UInt64(1)
                batched += UInt64(rects.size)
            case ReplayCommand.DrawPoints(points, color) =>
                renderer.pointBatch(points, color)
                submissions += UInt64(1)
                batched += UInt64(points.size)
            case ReplayCommand.SlotRun(run) => run.replay(renderer, cull)
        }
    }
    ReplayBatchStats(submissions: submissions, commands: batched)
}

private func replayCommandsAreReplayableIntersectingValidated(
    renderer: Renderer,
    commands: Array<ReplayCommand>,
    damage: Rect
): Bool {
    for (command in commands) {
        match (command) {
            case ReplayCommand.Single(RenderCommand.ReplaySlot(slot)) =>
                if (slot.intersectsCull(Some(damage)) && !slot.isReplayableIntersectingValidated(renderer, damage)) {
                    return false
                }
            case ReplayCommand.SlotRun(run) =>
                if (!run.isReplayableIntersecting(renderer, damage)) {
                    return false
                }
            case _ => ()
        }
    }
    true
}

// Flat value-command dispatch table; each branch performs exactly one Renderer operation.
private func replayRenderCommand(renderer: Renderer, command: RenderCommand, cull: ?Rect): Unit {
    match (command) {
        case RenderCommand.PushClip(rect) => renderer.pushClip(rect)
        case RenderCommand.PopClip => renderer.popClip()
        case RenderCommand.DrawPoint(x, y, color) => renderer.point(x, y, color)
        case RenderCommand.DrawLine(x1, y1, x2, y2, color) => renderer.line(x1, y1, x2, y2, color)
        case RenderCommand.DrawRect(rect, color) => renderer.rect(rect, color)
        case RenderCommand.FillRect(rect, color) => renderer.fill(rect, color)
        case RenderCommand.StrokeLine(x1, y1, x2, y2, pen) => renderer.strokeLine(x1, y1, x2, y2, pen)
        case RenderCommand.StrokeRoundedRect(rect, radius, pen) => renderer.strokeRoundedRect(rect, radius, pen)
        case RenderCommand.StrokeRoundedRectDashed(rect, radius, pen, dash, gap) => renderer.strokeRoundedRectDashed(
            rect, radius, pen, dash: dash, gap: gap)
        case RenderCommand.FillRoundedRect(rect, radius, color) => renderer.fillRoundedRect(rect, radius, color)
        case RenderCommand.FillRoundedRectGradient(rect, radius, start, end, vertical) => renderer
            .fillRoundedRectGradient(rect, radius, start, end, vertical: vertical)
        case RenderCommand.FillPerCornerRoundedRect(rect, color, topLeft, topRight, bottomRight, bottomLeft) => renderer
            .fillPerCornerRoundedRect(rect, color, topLeft: topLeft, topRight: topRight, bottomRight: bottomRight,
                bottomLeft: bottomLeft)
        case RenderCommand.FillRoundedRectSoft(rect, radius, color, feather) => renderer.fillRoundedRectSoft(rect,
            radius, color, feather: feather)
        case RenderCommand.StrokeCircle(cx, cy, radius, pen, segments) => renderer.strokeCircle(cx, cy, radius, pen,
            segments: segments)
        case RenderCommand.FillCircle(cx, cy, radius, color) => renderer.fillCircle(cx, cy, radius, color)
        case RenderCommand.FillConvexPolygon(points, color) => renderer.fillConvexPolygon(points, color)
        case RenderCommand.DrawTexturedStrip(texture, points, texPoints, alphas) => renderer.texturedStrip(texture,
            points, texPoints, alphas: alphas)
        case RenderCommand.DrawText(text, x, y, color, pointSize, style, font) => renderer.text(text, x, y, color,
            pointSize: pointSize, style: style, font: font)
        case RenderCommand.DrawTextRotated(text, centerX, centerY, angle, color, pointSize, style, font) => renderer
            .textRotated(text, centerX, centerY, angle, color, pointSize: pointSize, style: style, font: font)
        case RenderCommand.DrawTexture(texture, destination, source) => renderer.texture(texture, destination,
            source: source)
        case RenderCommand.DrawTextureRotated(texture, destination, angle, options) => renderer.textureRotated(texture,
            destination, angle, options: options)
        case RenderCommand.ReplaySlot(slot) =>
            if (slot.intersectsCull(cull)) {
                slot.replayValidatedInline(renderer, cull)
            }
    }
}

internal func nextRenderCommandEpoch(current: UInt64): UInt64 {
    if (current == UInt64.Max) {
        UInt64(0)
    } else {
        current + UInt64(1)
    }
}
