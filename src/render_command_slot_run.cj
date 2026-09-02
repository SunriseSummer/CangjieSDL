package sdl

/* Persistent ordered BVH for one contiguous run of hierarchical command slots. */
internal class RenderCommandSlotRun {
    private let slots: Array<RenderCommandSlot>
    private let root: ?RenderCommandSlotRunNode

    init(slots: Array<RenderCommandSlot>) {
        this.slots = slots
        if (hasStableReplayBounds(slots)) {
            let index = RenderCommandSlotRunNode(slots, 0, slots.size)
            index.build()
            this.root = Some(index)
        } else {
            this.root = None
        }
    }

    func replay(renderer: Renderer, cull: ?Rect): Unit {
        match (cull) {
            case Some(damage) => match (root) {
                case Some(index) => index.replayIntersecting(renderer, damage, cull)
                case None => replayLinear(renderer, damage, cull)
            }
            case None => for (slot in slots) {
                slot.replayValidatedInline(renderer, cull)
            }
        }
    }

    func isReplayableIntersecting(renderer: Renderer, damage: Rect): Bool {
        match (root) {
            case Some(index) => index.isReplayableIntersecting(renderer, damage)
            case None => linearSlotsAreReplayableIntersecting(renderer, damage)
        }
    }

    private func replayLinear(renderer: Renderer, damage: Rect, cull: ?Rect): Unit {
        for (slot in slots) {
            if (slot.intersectsCull(Some(damage))) {
                slot.replayValidatedInline(renderer, cull)
            }
        }
    }

    private func linearSlotsAreReplayableIntersecting(renderer: Renderer, damage: Rect): Bool {
        for (slot in slots) {
            if (slot.intersectsCull(Some(damage)) && !slot.isReplayableIntersectingValidated(renderer, damage)) {
                return false
            }
        }
        true
    }
}

private class RenderCommandSlotRunNode {
    private let slots: Array<RenderCommandSlot>
    private let start: Int64
    private let end: Int64
    private var bounds = Rect.zero()
    private var left: ?RenderCommandSlotRunNode = None
    private var right: ?RenderCommandSlotRunNode = None

    init(slots: Array<RenderCommandSlot>, start: Int64, end: Int64) {
        this.slots = slots
        this.start = start
        this.end = end
    }

    func build(): Unit {
        if (end - start <= 1) {
            bounds = match (slots[start].stableReplayBounds()) {
                case Some(value) => value
                case None => throw IllegalStateException("A slot-run BVH leaf requires stable replay bounds")
            }
        } else {
            let middle = start + (end - start) / 2
            let leftNode = RenderCommandSlotRunNode(slots, start, middle)
            let rightNode = RenderCommandSlotRunNode(slots, middle, end)
            leftNode.build()
            rightNode.build()
            bounds = unionRenderBounds(leftNode.bounds, rightNode.bounds)
            left = Some(leftNode)
            right = Some(rightNode)
        }
    }

    func replayIntersecting(renderer: Renderer, damage: Rect, cull: ?Rect): Unit {
        if (!slotRunIntersects(bounds, damage)) {
            return
        }
        if (end - start <= 1) {
            let slot = slots[start]
            if (slot.intersectsCull(Some(damage))) {
                slot.replayValidatedInline(renderer, cull)
            }
            return
        }
        match (left) {
            case Some(node) => node.replayIntersecting(renderer, damage, cull)
            case None => ()
        }
        match (right) {
            case Some(node) => node.replayIntersecting(renderer, damage, cull)
            case None => ()
        }
    }

    func isReplayableIntersecting(renderer: Renderer, damage: Rect): Bool {
        if (!slotRunIntersects(bounds, damage)) {
            return true
        }
        if (end - start <= 1) {
            let slot = slots[start]
            return !slot.intersectsCull(Some(damage)) || slot.isReplayableIntersectingValidated(renderer, damage)
        }
        let leftReplayable = match (left) {
            case Some(node) => node.isReplayableIntersecting(renderer, damage)
            case None => true
        }
        if (!leftReplayable) {
            return false
        }
        match (right) {
            case Some(node) => node.isReplayableIntersecting(renderer, damage)
            case None => true
        }
    }
}

private func hasStableReplayBounds(slots: Array<RenderCommandSlot>): Bool {
    if (slots.isEmpty()) {
        return false
    }
    for (slot in slots) {
        if (slot.stableReplayBounds().isNone()) {
            return false
        }
    }
    true
}

private func slotRunIntersects(bounds: Rect, damage: Rect): Bool {
    let overlap = bounds.intersection(damage)
    overlap.w > 0.0 && overlap.h > 0.0
}
