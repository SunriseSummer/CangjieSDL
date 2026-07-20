package sdl

import std.collection.HashMap

// How many distinct shape meshes to retain before the older generation is dropped. A UI reuses a
// small set of shapes (a few panel/card/chip sizes, each with a fill, a border and two shadow
// layers), so this is ample; a churning shape (an animated size) simply misses and re-tessellates
// as before, bounded by the two-generation eviction.
internal let MESH_CACHE_CAP: Int64 = 256

// Quantizes a length to quarter-pixel units for mesh keying, TRUNCATING rather than rounding. The
// truncation is deliberate: withinKeyBudget bounds each field with an exclusive upper limit at a
// power of two, and floor keeps the largest in-budget value at exactly 2^bits - 1, so a boundary
// value can never carry a bit into the adjacent packed field (rounding with +0.5 would turn, say,
// radius 511.9 into 2048 and overflow the 11-bit radius field into `extra`). Sub-quarter-pixel size
// differences share a mesh — an imperceptible size rounding, while the draw position stays exact.
internal func quantizeLength(value: Float32): Int64 {
    Int64(value * 4.0)
}

// True when a shape's dimensions fit the packed key's bit budget. An out-of-range shape bypasses the
// cache and tessellates directly, so an extreme size can never alias onto another shape's mesh.
internal func withinKeyBudget(w: Float32, h: Float32, radius: Float32, extra: Float32): Bool {
    w >= 0.0 && w < 8192.0 && h >= 0.0 && h < 8192.0 && radius >= 0.0 && radius < 512.0 && extra >= 0.0 && extra < 64.0
}

// Packs (kind, width, height, radius, extra) into one Int64 cache key. Field widths: kind 2 bits,
// width/height 15 bits each (quarter-pixel, < 8192px), radius 11 bits (< 512px), extra 8 bits
// (< 64px) — 51 bits total. withinKeyBudget bounds each length and quantizeLength truncates, so every
// field stays at or below 2^width - 1 and distinct shapes never collide onto one key.
internal func meshKey(kind: Int64, w: Float32, h: Float32, radius: Float32, extra: Float32): Int64 {
    let qw = quantizeLength(w)
    let qh = quantizeLength(h)
    let qr = quantizeLength(radius)
    let qe = quantizeLength(extra)
    kind | (qw << 2) | (qh << 17) | (qr << 32) | (qe << 43)
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

// A bounded, two-generation cache of shape meshes. When the active generation fills, the older
// (retired) generation is dropped whole — running `destroy` on each mesh — and the current one
// becomes retired; a hit in the retired generation is promoted back so a hot shape survives a
// rotation. Because the meshes own native buffers, the promote path removes the mesh from the retired
// generation BEFORE re-inserting it, so the rotation that insert may trigger cannot destroy the mesh
// being returned — the same native-lifetime safeguard as the shaped-text cache. `destroy` is injected
// (production frees the native buffers) so the eviction bookkeeping is unit-testable without a GPU.
internal class MeshCache {
    private let capacity: Int64
    private let destroy: (CachedMesh) -> Unit
    private var active = HashMap<Int64, CachedMesh>()
    private var retired = HashMap<Int64, CachedMesh>()

    init(capacity: Int64, destroy: (CachedMesh) -> Unit) {
        this.capacity = max(1, capacity)
        this.destroy = destroy
    }

    func get(key: Int64): ?CachedMesh {
        match (active.get(key)) {
            case Some(mesh) => return Some(mesh)
            case None => ()
        }
        match (retired.get(key)) {
            case Some(mesh) =>
                let _ = retired.remove(key)
                insert(key, mesh)
                Some(mesh)
            case None => None
        }
    }

    func put(key: Int64, mesh: CachedMesh): Unit {
        insert(key, mesh)
    }

    // Destroys every cached mesh across both generations. Called when the owning batch is disposed.
    func freeAll(): Unit {
        destroyGeneration(active)
        active.clear()
        destroyGeneration(retired)
        retired.clear()
    }

    // Live entries across both generations — for tests and diagnostics.
    func size(): Int64 {
        active.size + retired.size
    }

    private func insert(key: Int64, mesh: CachedMesh): Unit {
        if (active.size >= capacity) {
            destroyGeneration(retired)
            retired.clear()
            let recycled = retired
            retired = active
            active = recycled
        }
        active[key] = mesh
    }

    private func destroyGeneration(generation: HashMap<Int64, CachedMesh>): Unit {
        for ((_, mesh) in generation) {
            destroy(mesh)
        }
    }
}
