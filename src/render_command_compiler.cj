package sdl

import std.collection.ArrayList

private let COMMAND_BASE_BYTES: UInt64 = UInt64(64)
private let POINT_BYTES: UInt64 = UInt64(8)
private let FLOAT_BYTES: UInt64 = UInt64(4)
private let MIN_PRIMITIVE_BATCH: Int64 = 4

/* Mutable recording transaction that freezes into an immutable, precompiled command buffer. */
internal class RenderCommandRecorder {
    private let commands = ArrayList<RenderCommand>()
    private let localClips = ArrayList<Rect>()
    private let resources = ArrayList<Texture>()
    private let slots = ArrayList<RenderCommandSlot>()
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
            case RenderCommand.ReplaySlot(slot) => addSlot(slot)
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
            resources.toArray(), slots.toArray(), estimatedBytes, renderCommandBounds(owner, recorded, entryClip),
            entryClip, !slots.isEmpty())
    }

    private func addResource(resource: Texture): Unit {
        for (existing in resources) {
            if (refEq(existing, resource)) {
                return
            }
        }
        resources.add(resource)
    }

    private func addSlot(slot: RenderCommandSlot): Unit {
        for (existing in slots) {
            if (sameRenderCommandSlot(existing, slot)) {
                return
            }
        }
        slots.add(slot)
    }
}

internal func compileRenderCommands(commands: Array<RenderCommand>): Array<ReplayCommand> {
    let compiled = ArrayList<ReplayCommand>()
    var index: Int64 = 0
    while (index < commands.size) {
        match (commands[index]) {
            case RenderCommand.ReplaySlot(_) =>
                let end = slotRunEnd(commands, index + 1)
                if (end - index >= 2) {
                    compiled.add(ReplayCommand.SlotRun(compileSlotRun(commands, index, end)))
                    index = end
                    continue
                }
            case _ => ()
        }
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

internal func compiledBatchCount(commands: Array<ReplayCommand>): Int64 {
    var count: Int64 = 0
    for (command in commands) {
        match (command) {
            case ReplayCommand.Single(_) => ()
            case ReplayCommand.FillRects(_, _) => count += 1
            case ReplayCommand.DrawRects(_, _) => count += 1
            case ReplayCommand.DrawPoints(_, _) => count += 1
            case ReplayCommand.SlotRun(_) => ()
        }
    }
    count
}

internal func sameRenderCommandSlot(left: RenderCommandSlot, right: RenderCommandSlot): Bool {
    refEq(left, right)
}

private func slotRunEnd(commands: Array<RenderCommand>, start: Int64): Int64 {
    var end = start
    while (end < commands.size) {
        match (commands[end]) {
            case RenderCommand.ReplaySlot(_) => end += 1
            case _ => break
        }
    }
    end
}

private func compileSlotRun(commands: Array<RenderCommand>, start: Int64, end: Int64): RenderCommandSlotRun {
    RenderCommandSlotRun(Array<RenderCommandSlot>(end - start, {index => commandSlot(commands[start + index])}))
}

private func commandSlot(command: RenderCommand): RenderCommandSlot {
    match (command) {
        case RenderCommand.ReplaySlot(slot) => slot
        case _ => throw IllegalStateException("Slot-run compilation received a non-slot command")
    }
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
