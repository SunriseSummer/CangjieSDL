package sdl

import std.collection.ArrayList
import sdl.text.GenerationCache

// A mesh with null native buffers: the two-generation eviction bookkeeping — including the
// promote-safety hazard where a hit in the retired generation must not be freed by the rotation its
// own re-insert triggers — is what is under test, not the buffers themselves.
private func fakeMesh(): CachedMesh {
    CachedMesh(CPointer<SdlVertex>(), CPointer<Int32>(), 0, 0)
}

// Distinct dimensions remain distinct at old packing boundaries and within a quarter pixel.
@Test
func meshKeyFieldsStayWithinBudgetAtBoundaries(): Unit {
    @Expect(withinKeyBudget(8191.9, 8191.9, 511.9, 63.9))
    @Expect(!withinKeyBudget(8192.0, 8191.9, 511.9, 63.9))
    let roundedBig = meshKey(MESH_KIND_FILL, 1024.0, 1024.0, 511.9, 4.0)
    let sharpCorner = meshKey(MESH_KIND_FILL, 1024.0, 1024.0, 0.1, 4.25)
    @Expect(roundedBig != sharpCorner)
    @Expect(meshKey(0, 10.01, 20.0, 2.0, 0.7) != meshKey(0, 10.24, 20.0, 2.0, 0.7))
    @Expect(meshKey(0, 10.0, 20.0, 2.0, 0.7) != meshKey(1, 10.0, 20.0, 2.0, 0.7))
}

@Test
func meshCachePromotesHotKeyPastRotation(): Unit {
    let destroyed = ArrayList<CachedMesh>()
    let cache = GenerationCache<Int64, CachedMesh>(2) {mesh => destroyed.add(mesh)}
    let a = fakeMesh()
    let b = fakeMesh()
    let c = fakeMesh()
    let d = fakeMesh()
    cache.put(1, a)
    cache.put(2, b)
    cache.put(3, c) // rotate: {1,2} -> retired, active {3}; nothing destroyed yet
    @Expect(destroyed.size, 0)

    // Promote key 1 out of the retired generation.
    match (cache.get(1)) {
        case Some(mesh) => @Expect(refEq(mesh, a), true)
        case None => @Expect(false, true)
    }
    cache.put(4, d) // rotate: frees the still-cold retired {2} only; the promoted 1 survived in active
    @Expect(destroyed.size, 1)
    @Expect(refEq(destroyed[0], b), true)

    var aFreed = false
    for (mesh in destroyed) {
        if (refEq(mesh, a)) {
            aFreed = true
        }
    }
    @Expect(aFreed, false)
}

@Test
func meshCacheDestroysEveryMeshExactlyOnce(): Unit {
    let destroyed = ArrayList<CachedMesh>()
    let cache = GenerationCache<Int64, CachedMesh>(2) {mesh => destroyed.add(mesh)}
    let meshes = ArrayList<CachedMesh>()
    var i = 1
    while (i <= 7) {
        let mesh = fakeMesh()
        meshes.add(mesh)
        cache.put(Int64(i), mesh)
        i += 1
    }
    cache.clear()
    // All seven created, each destroyed exactly once — no leak (a missing mesh) and no double free.
    @Expect(destroyed.size, 7)
    for (mesh in meshes) {
        var count = 0
        for (freed in destroyed) {
            if (refEq(freed, mesh)) {
                count += 1
            }
        }
        @Expect(count, 1)
    }
    @Expect(cache.size(), 0)
}
