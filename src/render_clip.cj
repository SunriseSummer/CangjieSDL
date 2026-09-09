package sdl

import std.math.{ceil, floor}

// SDL accepts integer logical clip rectangles. Round the EDGES outwards, rather than
// truncating origin and extent independently (which can erase almost two logical pixels).
// Preserve empty intersections explicitly: rounding must never make them drawable again.
internal func enclosingSdlClipRect(rect: Rect): SdlRect {
    if (rect.x.isNaN() || rect.x.isInf() || rect.y.isNaN() || rect.y.isInf() || rect.w.isNaN() || rect.w.isInf() ||
        rect.h.isNaN() || rect.h.isInf()) {
        throw IllegalArgumentException("Renderer clip coordinates must be finite")
    }
    let left = floor(Float64(rect.x))
    let top = floor(Float64(rect.y))
    let width = if (rect.w <= 0.0) {
        0.0
    } else {
        ceil(Float64(rect.x) + Float64(rect.w)) - left
    }
    let height = if (rect.h <= 0.0) {
        0.0
    } else {
        ceil(Float64(rect.y) + Float64(rect.h)) - top
    }
    if (left < -2147483648.0 || left > 2147483647.0 || top < -2147483648.0 || top > 2147483647.0 || width > 2147483647.0 ||
        height > 2147483647.0 || left + width > 2147483647.0 || top + height > 2147483647.0) {
        throw IllegalArgumentException("Renderer clip exceeds SDL integer coordinates")
    }
    var raw = SdlRect()
    raw.x = Int32(left)
    raw.y = Int32(top)
    raw.w = Int32(width)
    raw.h = Int32(height)
    raw
}

// Match SDL's UpdatePixelClipRect before switching the text pass to scale 1.
// Scaling the original fractional rectangle directly gives a different scissor from primitives.
internal func scaledSdlClipRect(rect: Rect, scaleX: Float32, scaleY: Float32): SdlRect {
    if (scaleX <= 0.0 || scaleY <= 0.0 || scaleX.isNaN() || scaleY.isNaN() || scaleX.isInf() || scaleY.isInf()) {
        throw IllegalArgumentException("Renderer clip scale must be finite and positive")
    }
    let logical = enclosingSdlClipRect(rect)
    enclosingSdlClipRect(
        Rect(floor(Float32(logical.x) * scaleX), floor(Float32(logical.y) * scaleY), ceil(Float32(logical.w) * scaleX),
            ceil(Float32(logical.h) * scaleY)))
}

// A fractional pixel at a damage boundary can be excluded by the parent scissor but included
// after a nested clip moves its origin (SDL floors origin and ceils extent independently).
// Find nearby integer logical AND physical edges; unusual scales safely require a full frame.
internal func alignedDamageClip(rect: Rect, scaleX: Float32, scaleY: Float32): ?Rect {
    let raw = enclosingSdlClipRect(rect)
    let left = alignedDamageEdge(Float32(raw.x), scaleX, -1.0)
    let top = alignedDamageEdge(Float32(raw.y), scaleY, -1.0)
    let right = alignedDamageEdge(Float32(raw.x) + Float32(raw.w), scaleX, 1.0)
    let bottom = alignedDamageEdge(Float32(raw.y) + Float32(raw.h), scaleY, 1.0)
    match ((left, top, right, bottom)) {
        case (Some(x), Some(y), Some(r), Some(b)) => Some(Rect(x, y, r - x, b - y))
        case _ => None
    }
}

private func alignedDamageEdge(origin: Float32, scale: Float32, direction: Float32): ?Float32 {
    let maximumExpansion: Int64 = 16
    for (step in 0..maximumExpansion) {
        let edge = origin + Float32(step) * direction
        let pixel = edge * scale
        if (!pixel.isNaN() && !pixel.isInf() && pixel == floor(pixel)) {
            return Some(edge)
        }
    }
    None
}
