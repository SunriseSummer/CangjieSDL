package sdl

import std.deriving.*

// How many distinct shape meshes to retain before the older generation is dropped. A UI reuses a
// small set of shapes (a few panel/card/chip sizes, each with a fill, a border and two shadow
// layers), so this is ample; a churning shape (an animated size) simply misses and re-tessellates
// as before, bounded by the two-generation eviction.
internal let MESH_CACHE_CAP: Int64 = 256

// Keep the existing complexity bounds; exact keys do not remove the tessellation budget.
internal func withinKeyBudget(w: Float32, h: Float32, radius: Float32, extra: Float32): Bool {
    w >= 0.0 && w < 8192.0 && h >= 0.0 && h < 8192.0 && radius >= 0.0 && radius < 512.0 && extra >= 0.0 && extra < 64.0
}

// A cached mesh contains the original float geometry. Its key must preserve those same
// dimensions, otherwise the first size drawn in a quarter-pixel bucket changes later output.
@Derive[Equatable, Hashable]
internal struct MeshKey {
    let kind: Int64
    let width: UInt32
    let height: UInt32
    let radius: UInt32
    let extra: UInt32

    init(kind: Int64, w: Float32, h: Float32, radius: Float32, extra: Float32) {
        this.kind = kind
        this.width = w.toBits()
        this.height = h.toBits()
        this.radius = radius.toBits()
        this.extra = extra.toBits()
    }
}

internal func meshKey(kind: Int64, w: Float32, h: Float32, radius: Float32, extra: Float32): MeshKey {
    MeshKey(kind, w, h, radius, extra)
}

// A tessellated shape in local coordinates, held in native buffers so per-frame emit is a tight
// unsafe loop: relative positions live in each vertex's px/py and the feather coverage in its colA
// (the draw colour is folded in at emit); the index buffer is invariant and handed straight to SDL.
internal class CachedMesh {
    let relVerts: CPointer<SdlVertex>
    let indices: CPointer<Int32>
    let vertCount: Int64
    let idxCount: Int64

    init(relVerts: CPointer<SdlVertex>, indices: CPointer<Int32>, vertCount: Int64, idxCount: Int64) {
        this.relVerts = relVerts
        this.indices = indices
        this.vertCount = vertCount
        this.idxCount = idxCount
    }

    // Frees the native buffers. Called when the mesh is evicted from the cache or the batch disposes.
    func free(): Unit {
        if (relVerts.isNotNull()) {
            unsafe { LibC.free(relVerts) }
        }
        if (indices.isNotNull()) {
            unsafe { LibC.free(indices) }
        }
    }
}
