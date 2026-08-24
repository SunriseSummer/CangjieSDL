package sdl

import std.collection.ArrayList

private let COMMAND_BASE_BYTES: UInt64 = UInt64(64)
private let POINT_BYTES: UInt64 = UInt64(8)
private let FLOAT_BYTES: UInt64 = UInt64(4)
private let MIN_PRIMITIVE_BATCH: Int64 = 4

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
}

/* Primitive runs are compiled once when recording finishes, never rebuilt on every replay. */
internal enum ReplayCommand {
    | Single(RenderCommand)
    | FillRects(Array<Rect>, Color)
    | DrawRects(Array<Rect>, Color)
    | DrawPoints(Array<Point>, Color)
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
 * explicit Texture handles; replay never re-enters the widget closures that produced them.
 */
public class RenderCommandBuffer {
    private let owner: Renderer
    private let ownerEpoch: UInt64
    private let commands: Array<RenderCommand>
    private let replayCommands: Array<ReplayCommand>
    private let clipCommandCount: Int64
    private let resources: Array<Texture>
    private let estimatedBytes: UInt64
    private let bounds: ?Rect
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
        estimatedBytes: UInt64,
        bounds: ?Rect
    ) {
        this.owner = owner
        this.ownerEpoch = ownerEpoch
        this.commands = commands
        this.replayCommands = replayCommands
        this.clipCommandCount = clipCommandCount
        this.resources = resources
        this.estimatedBytes = estimatedBytes
        this.bounds = bounds
    }

    /** Current command, clip, resource, memory-estimate, and successful-replay counters. */
    public func stats(): RenderCommandBufferStats {
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

    /** Conservative logical-pixel union of recorded paint after clip intersection. */
    public func paintBounds(): ?Rect {
        bounds
    }

    /**
     * Whether this buffer can be replayed without partially drawing: the Renderer/epoch match and
     * every captured Texture is still open.
     */
    public func isReplayable(renderer: Renderer): Bool {
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

    /**
     * Replays commands in their original z order. Returns false before drawing when the owner,
     * renderer epoch, or a Texture resource is invalid. The caller's clip stack is always restored.
     */
    public func replay(renderer: Renderer): Bool {
        if (!isReplayable(renderer)) {
            return false
        }
        if (renderer.isRecordingCommands()) {
            for (command in commands) {
                renderer.appendRecordedCommand(command)
            }
            replayCount = nextRenderCommandEpoch(replayCount)
            return true
        }
        let savedClips = renderer.captureCommandClipStack()
        var batchStats = ReplayBatchStats()
        try {
            batchStats = replayCompiledCommands(renderer, replayCommands)
        } finally {
            renderer.restoreCommandClipStack(savedClips)
        }
        batchSubmissionCount += batchStats.submissions
        batchedCommandCount += batchStats.commands
        replayCount = nextRenderCommandEpoch(replayCount)
        true
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

internal class RenderCommandRecorder {
    private let commands = ArrayList<RenderCommand>()
    private let localClips = ArrayList<Rect>()
    private let resources = ArrayList<Texture>()
    private let entryClip: ?Rect
    private var clipCommandCount: Int64 = 0
    private var estimatedBytes: UInt64 = UInt64(0)

    init(entryClip: ?Rect) {
        this.entryClip = entryClip
    }

    func record(command: RenderCommand): Unit {
        commands.add(command)
        estimatedBytes += estimatedRenderCommandBytes(command)
        match (command) {
            case RenderCommand.DrawTexturedStrip(texture, _, _, _) => addResource(texture)
            case RenderCommand.DrawTexture(texture, _, _) => addResource(texture)
            case RenderCommand.DrawTextureRotated(texture, _, _, _) => addResource(texture)
            case _ => ()
        }
    }

    func append(command: RenderCommand): Unit {
        match (command) {
            case RenderCommand.PushClip(rect) => pushClip(rect)
            case RenderCommand.PopClip => popClip()
            case _ => record(command)
        }
    }

    func pushClip(rect: Rect): Unit {
        let effective = match (currentClip()) {
            case Some(parent) => parent.intersection(rect)
            case None => rect
        }
        localClips.add(effective)
        clipCommandCount += 1
        record(RenderCommand.PushClip(rect))
    }

    func popClip(): Unit {
        if (localClips.isEmpty()) {
            throw IllegalStateException("Render command recording cannot pop its caller's clip")
        }
        localClips.remove(at: localClips.size - 1)
        clipCommandCount += 1
        record(RenderCommand.PopClip)
    }

    func currentClip(): ?Rect {
        if (!localClips.isEmpty()) {
            Some(localClips[localClips.size - 1])
        } else {
            entryClip
        }
    }

    func finish(owner: Renderer, ownerEpoch: UInt64): RenderCommandBuffer {
        if (!localClips.isEmpty()) {
            throw IllegalStateException("Render command recording ended with an unbalanced clip stack")
        }
        for (resource in resources) {
            if (!resource.isOwnedBy(owner)) {
                throw IllegalStateException("Render commands cannot capture a Texture from another Renderer")
            }
        }
        let recorded = commands.toArray()
        RenderCommandBuffer(owner, ownerEpoch, recorded, compileRenderCommands(recorded), clipCommandCount,
            resources.toArray(), estimatedBytes, renderCommandBounds(owner, recorded, entryClip))
    }

    private func addResource(resource: Texture): Unit {
        for (existing in resources) {
            if (refEq(existing, resource)) {
                return
            }
        }
        resources.add(resource)
    }
}

private func replayCompiledCommands(renderer: Renderer, commands: Array<ReplayCommand>): ReplayBatchStats {
    var submissions: UInt64 = 0
    var batched: UInt64 = 0
    for (command in commands) {
        match (command) {
            case ReplayCommand.Single(value) => replayRenderCommand(renderer, value)
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
        }
    }
    ReplayBatchStats(submissions: submissions, commands: batched)
}

private func compileRenderCommands(commands: Array<RenderCommand>): Array<ReplayCommand> {
    let compiled = ArrayList<ReplayCommand>()
    var index: Int64 = 0
    while (index < commands.size) {
        let end = batchRunEnd(commands, index)
        let count = end - index
        if (count >= MIN_PRIMITIVE_BATCH) {
            compiled.add(compilePrimitiveBatch(commands, index, end))
            index = end
        } else {
            compiled.add(ReplayCommand.Single(commands[index]))
            index += 1
        }
    }
    compiled.toArray()
}

private func batchRunEnd(commands: Array<RenderCommand>, start: Int64): Int64 {
    match (commands[start]) {
        case RenderCommand.FillRect(_, color) => contiguousFillEnd(commands, start + 1, color)
        case RenderCommand.DrawRect(_, color) => contiguousRectEnd(commands, start + 1, color)
        case RenderCommand.DrawPoint(_, _, color) => contiguousPointEnd(commands, start + 1, color)
        case _ => start + 1
    }
}

private func contiguousFillEnd(commands: Array<RenderCommand>, start: Int64, color: Color): Int64 {
    var end = start
    while (end < commands.size) {
        match (commands[end]) {
            case RenderCommand.FillRect(_, candidate) where sameColor(color, candidate) => end += 1
            case _ => break
        }
    }
    end
}

private func contiguousRectEnd(commands: Array<RenderCommand>, start: Int64, color: Color): Int64 {
    var end = start
    while (end < commands.size) {
        match (commands[end]) {
            case RenderCommand.DrawRect(_, candidate) where sameColor(color, candidate) => end += 1
            case _ => break
        }
    }
    end
}

private func contiguousPointEnd(commands: Array<RenderCommand>, start: Int64, color: Color): Int64 {
    var end = start
    while (end < commands.size) {
        match (commands[end]) {
            case RenderCommand.DrawPoint(_, _, candidate) where sameColor(color, candidate) => end += 1
            case _ => break
        }
    }
    end
}

private func compilePrimitiveBatch(
    commands: Array<RenderCommand>,
    start: Int64,
    end: Int64
): ReplayCommand {
    match (commands[start]) {
        case RenderCommand.FillRect(_, color) =>
            let rects = ArrayList<Rect>(end - start)
            for (index in start..end) {
                appendFillRect(commands[index], rects)
            }
            ReplayCommand.FillRects(rects.toArray(), color)
        case RenderCommand.DrawRect(_, color) =>
            let rects = ArrayList<Rect>(end - start)
            for (index in start..end) {
                appendDrawRect(commands[index], rects)
            }
            ReplayCommand.DrawRects(rects.toArray(), color)
        case RenderCommand.DrawPoint(_, _, color) =>
            let points = ArrayList<Point>(end - start)
            for (index in start..end) {
                appendDrawPoint(commands[index], points)
            }
            ReplayCommand.DrawPoints(points.toArray(), color)
        case _ => ReplayCommand.Single(commands[start])
    }
}

private func compiledBatchCount(commands: Array<ReplayCommand>): Int64 {
    var count: Int64 = 0
    for (command in commands) {
        match (command) {
            case ReplayCommand.Single(_) => ()
            case _ => count += 1
        }
    }
    count
}

private func appendFillRect(command: RenderCommand, rects: ArrayList<Rect>): Unit {
    match (command) {
        case RenderCommand.FillRect(rect, _) => rects.add(rect)
        case _ => ()
    }
}

private func appendDrawRect(command: RenderCommand, rects: ArrayList<Rect>): Unit {
    match (command) {
        case RenderCommand.DrawRect(rect, _) => rects.add(rect)
        case _ => ()
    }
}

private func appendDrawPoint(command: RenderCommand, points: ArrayList<Point>): Unit {
    match (command) {
        case RenderCommand.DrawPoint(x, y, _) => points.add(Point(x, y))
        case _ => ()
    }
}

private func sameColor(left: Color, right: Color): Bool {
    left.r == right.r && left.g == right.g && left.b == right.b && left.a == right.a
}

// Flat value-command dispatch table; each branch performs exactly one Renderer operation.
private func replayRenderCommand(renderer: Renderer, command: RenderCommand): Unit {
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
    }
}

private func estimatedRenderCommandBytes(command: RenderCommand): UInt64 {
    match (command) {
        case RenderCommand.FillConvexPolygon(points, _) => COMMAND_BASE_BYTES + UInt64(points.size) * POINT_BYTES
        case RenderCommand.DrawTexturedStrip(_, points, texPoints, Some(alphas)) => COMMAND_BASE_BYTES +
            UInt64(points.size + texPoints.size) * POINT_BYTES + UInt64(alphas.size) * FLOAT_BYTES
        case RenderCommand.DrawTexturedStrip(_, points, texPoints, None) => COMMAND_BASE_BYTES +
            UInt64(points.size + texPoints.size) * POINT_BYTES
        case RenderCommand.DrawText(text, _, _, _, _, _, font) => COMMAND_BASE_BYTES + stringPayloadBytes(text, font)
        case RenderCommand.DrawTextRotated(text, _, _, _, _, _, _, font) => COMMAND_BASE_BYTES + stringPayloadBytes(
            text, font)
        case _ => COMMAND_BASE_BYTES
    }
}

private func stringPayloadBytes(text: String, font: ?String): UInt64 {
    let fontBytes = match (font) {
        case Some(value) => UInt64(value.size)
        case None => UInt64(0)
    }
    UInt64(text.size) + fontBytes
}

internal func nextRenderCommandEpoch(current: UInt64): UInt64 {
    if (current == UInt64.Max) {
        UInt64(0)
    } else {
        current + UInt64(1)
    }
}
