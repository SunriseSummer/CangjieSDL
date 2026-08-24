package sdl

import std.collection.ArrayList

internal func renderCommandBounds(renderer: Renderer, commands: Array<RenderCommand>, entryClip: ?Rect): ?Rect {
    let clips = ArrayList<Rect>()
    var bounds: ?Rect = None
    for (command in commands) {
        match (command) {
            case RenderCommand.PushClip(rect) =>
                clips.add(match (activeBoundsClip(clips, entryClip)) {
                    case Some(parent) => parent.intersection(rect)
                    case None => rect
                })
                continue
            case RenderCommand.PopClip =>
                if (!clips.isEmpty()) {
                    clips.remove(at: clips.size - 1)
                }
                continue
            case _ => ()
        }
        bounds = mergeVisibleCommandBounds(bounds,
            clippedCommandBounds(renderer, command, activeBoundsClip(clips, entryClip)))
    }
    bounds
}

private func activeBoundsClip(clips: ArrayList<Rect>, entryClip: ?Rect): ?Rect {
    if (clips.isEmpty()) {
        entryClip
    } else {
        Some(clips[clips.size - 1])
    }
}

private func clippedCommandBounds(renderer: Renderer, command: RenderCommand, clip: ?Rect): ?Rect {
    match (singleRenderCommandBounds(renderer, command)) {
        case Some(raw) => Some(match (clip) {
            case Some(value) => raw.intersection(value)
            case None => raw
        })
        case None => None
    }
}

private func mergeVisibleCommandBounds(current: ?Rect, candidate: ?Rect): ?Rect {
    match (candidate) {
        case Some(rect) where rect.w > 0.0 && rect.h > 0.0 => Some(match (current) {
            case Some(existing) => unionCommandBounds(existing, rect)
            case None => rect
        })
        case _ => current
    }
}

private func singleRenderCommandBounds(renderer: Renderer, command: RenderCommand): ?Rect {
    match (command) {
        case RenderCommand.DrawPoint(x, y, _) => Some(Rect(x, y, 1.0, 1.0))
        case RenderCommand.DrawLine(x1, y1, x2, y2, _) => Some(lineCommandBounds(x1, y1, x2, y2, 1.0))
        case RenderCommand.DrawRect(rect, _) => Some(expandCommandBounds(rect, 0.5))
        case RenderCommand.FillRect(rect, _) => Some(rect)
        case RenderCommand.StrokeLine(x1, y1, x2, y2, pen) => Some(lineCommandBounds(x1, y1, x2, y2, max(1.0, pen.width)))
        case RenderCommand.StrokeRoundedRect(rect, _, pen) => Some(expandCommandBounds(rect, pen.width / 2.0 + 1.0))
        case RenderCommand.StrokeRoundedRectDashed(rect, _, pen, _, _) => Some(
            expandCommandBounds(rect, pen.width / 2.0 + 1.0))
        case RenderCommand.FillRoundedRect(rect, _, _) => Some(rect)
        case RenderCommand.FillRoundedRectGradient(rect, _, _, _, _) => Some(rect)
        case RenderCommand.FillPerCornerRoundedRect(rect, _, _, _, _, _) => Some(rect)
        case RenderCommand.FillRoundedRectSoft(rect, _, _, feather) => Some(expandCommandBounds(rect, feather))
        case RenderCommand.StrokeCircle(cx, cy, radius, pen, _) => Some(
            circleCommandBounds(cx, cy, radius + pen.width / 2.0 + 1.0))
        case RenderCommand.FillCircle(cx, cy, radius, _) => Some(circleCommandBounds(cx, cy, radius))
        case RenderCommand.FillConvexPolygon(points, _) => pointListCommandBounds(points)
        case RenderCommand.DrawTexturedStrip(_, points, _, _) => pointListCommandBounds(points)
        case RenderCommand.DrawText(text, x, y, _, pointSize, style, font) => Some(
            Rect(x, y, renderer.textWidth(text, pointSize: pointSize, style: style, font: font),
                renderer.textHeight(pointSize: pointSize, style: style, font: font)))
        case RenderCommand.DrawTextRotated(text, centerX, centerY, _, _, pointSize, style, font) =>
            let width = renderer.textWidth(text, pointSize: pointSize, style: style, font: font)
            let height = renderer.textHeight(pointSize: pointSize, style: style, font: font)
            let half = (width + height) / 2.0
            Some(Rect(centerX - half, centerY - half, half * 2.0, half * 2.0))
        case RenderCommand.DrawTexture(_, destination, _) => Some(destination)
        case RenderCommand.DrawTextureRotated(_, destination, _, _) =>
            let half = (destination.w + destination.h) / 2.0
            Some(Rect(destination.centerX() - half, destination.centerY() - half, half * 2.0, half * 2.0))
        case _ => None
    }
}

private func lineCommandBounds(x1: Float32, y1: Float32, x2: Float32, y2: Float32, width: Float32): Rect {
    let half = width / 2.0 + 1.0
    let left = min(x1, x2) - half
    let top = min(y1, y2) - half
    Rect(left, top, max(x1, x2) - min(x1, x2) + half * 2.0, max(y1, y2) - min(y1, y2) + half * 2.0)
}

private func circleCommandBounds(cx: Float32, cy: Float32, radius: Float32): Rect {
    Rect(cx - radius, cy - radius, radius * 2.0, radius * 2.0)
}

private func expandCommandBounds(rect: Rect, amount: Float32): Rect {
    Rect(rect.x - amount, rect.y - amount, rect.w + amount * 2.0, rect.h + amount * 2.0)
}

private func pointListCommandBounds(points: ArrayList<Point>): ?Rect {
    if (points.isEmpty()) {
        return None
    }
    var left = points[0].x
    var top = points[0].y
    var right = left
    var bottom = top
    for (index in 1..points.size) {
        left = min(left, points[index].x)
        top = min(top, points[index].y)
        right = max(right, points[index].x)
        bottom = max(bottom, points[index].y)
    }
    Some(Rect(left, top, max(1.0, right - left), max(1.0, bottom - top)))
}

private func unionCommandBounds(left: Rect, right: Rect): Rect {
    let x = min(left.x, right.x)
    let y = min(left.y, right.y)
    let farX = max(left.right(), right.right())
    let farY = max(left.bottom(), right.bottom())
    Rect(x, y, farX - x, farY - y)
}
