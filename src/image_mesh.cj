package sdl

import std.math.{cos, sin}

private let MAX_IMAGE_ARC_STEPS: Int64 = 64
private let IMAGE_EDGE_FEATHER: Float32 = 0.7
private let IMAGE_QUARTER_TURN: Float64 = 1.5707963267948966

// The AA fringe stays inside the rectangle, so retained damage bounds remain exact.
internal func buildImageMesh(width: Float32, height: Float32, radius: Float32): CachedMesh {
    let steps = if (radius == 0.0) {
        Int64(0)
    } else {
        max(Int64(2), Int64(min(Float32(MAX_IMAGE_ARC_STEPS - 1), radius / 2.0)) + 1)
    }
    let count = 4 * (steps + 1)
    let rounded = radius > 0.0
    let vertexCount = if (rounded) {
        count * 2
    } else {
        count
    }
    let indexCount = (count - 2) * 3 + if (rounded) {
        count * 6
    } else {
        0
    }
    let vertices = unsafe { LibC.malloc<SdlVertex>(count: vertexCount) }
    let indices = unsafe { LibC.malloc<Int32>(count: indexCount) }
    if (vertices.isNull() || indices.isNull()) {
        if (vertices.isNotNull()) {
            unsafe { LibC.free(vertices) }
        }
        if (indices.isNotNull()) {
            unsafe { LibC.free(indices) }
        }
        throw SdlException("Cannot allocate rounded image mesh")
    }
    writeImageVertices(vertices, Size(width, height), radius, steps)
    writeImageIndices(indices, count, rounded)
    CachedMesh(vertices, indices, vertexCount, indexCount)
}

private func writeImageVertices(vertices: CPointer<SdlVertex>, size: Size, radius: Float32, steps: Int64): Unit {
    let width = size.w
    let height = size.h
    let count = 4 * (steps + 1)
    let rounded = radius > 0.0
    let feather = min(IMAGE_EDGE_FEATHER, min(width, height) / 2.0)
    for (i in 0..count) {
        let outer = imageCornerPoint(width, height, radius, steps, i)
        var vertex = SdlVertex()
        if (rounded) {
            let inner = imageCornerPoint(width - 2.0 * feather, height - 2.0 * feather, max(0.0, radius - feather),
                steps, i)
            vertex.px = inner.x + feather
            vertex.py = inner.y + feather
            vertex.colA = 1.0
            unsafe { vertices.write(i, vertex) }
            vertex.px = outer.x
            vertex.py = outer.y
            vertex.colA = 0.0
            unsafe { vertices.write(count + i, vertex) }
        } else {
            vertex.px = outer.x
            vertex.py = outer.y
            vertex.colA = 1.0
            unsafe { vertices.write(i, vertex) }
        }
    }
}

private func writeImageIndices(indices: CPointer<Int32>, count: Int64, rounded: Bool): Unit {
    var cursor: Int64 = 0
    for (i in 1..count - 1) {
        for (index in [Int64(0), i, i + 1]) {
            unsafe { indices.write(cursor, Int32(index)) }
            cursor += 1
        }
    }
    if (rounded) {
        for (i in 0..count) {
            let next = (i + 1) % count
            for (index in [i, count + i, next, next, count + i, count + next]) {
                unsafe { indices.write(cursor, Int32(index)) }
                cursor += 1
            }
        }
    }
}

private func imageCornerPoint(width: Float32, height: Float32, radius: Float32, steps: Int64, index: Int64): Point {
    let corner = index / (steps + 1)
    let right = corner == 1 || corner == 2
    let bottom = corner >= 2
    let x = if (right) {
        width - radius
    } else {
        radius
    }
    let y = if (bottom) {
        height - radius
    } else {
        radius
    }
    if (steps == 0) {
        return Point(x, y)
    }
    let angle = (Float64(corner) + 2.0 + Float64(index % (steps + 1)) / Float64(steps)) * IMAGE_QUARTER_TURN
    Point(x + radius * Float32(cos(angle)), y + radius * Float32(sin(angle)))
}
