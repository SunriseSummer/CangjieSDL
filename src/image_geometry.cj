package sdl

import sdl.text.GenerationCache

// Lazily created by Renderer only for styled images. Reuses native vertex buffers and bounded,
// size-keyed meshes; changing tint, position, source crop or opacity never rebuilds a mesh.
internal class ImageGeometry {
    private let meshes = GenerationCache<MeshKey, CachedMesh>(128) {mesh => mesh.free()}
    private var vertices = CPointer<SdlVertex>()
    private var capacity: Int64 = 0

    func draw(renderer: CPointer<Unit>, texture: Texture, destination: Rect, source: Rect, style: TextureStyle): Unit {
        let radius = min(style.radius, min(destination.w, destination.h) / 2.0)
        let key = meshKey(0, destination.w, destination.h, radius, 0.0)
        let mesh = match (meshes.get(key)) {
            case Some(value) => value
            case None =>
                let value = buildImageMesh(destination.w, destination.h, radius)
                meshes.put(key, value)
                value
        }
        reserve(mesh.vertCount)
        let textureSize = texture.size()
        for (i in 0..mesh.vertCount) {
            let vertex = unsafe { mesh.relVerts.read(i) }
            unsafe { vertices.write(i, imagePaintVertex(vertex, destination, source, textureSize, style)) }
        }
        drawStyledImageGeometry(renderer, texture.ptr, vertices, mesh, textureScaleCode(style.sampling))
    }

    func close(): Unit {
        meshes.clear()
        if (vertices.isNotNull()) {
            unsafe { LibC.free(vertices) }
        }
        vertices = CPointer<SdlVertex>()
        capacity = 0
    }

    private func reserve(count: Int64): Unit {
        if (count <= capacity) {
            return
        }
        let replacement = unsafe { LibC.malloc<SdlVertex>(count: count) }
        if (replacement.isNull()) {
            throw SdlException("Cannot allocate image geometry")
        }
        if (vertices.isNotNull()) {
            unsafe { LibC.free(vertices) }
        }
        vertices = replacement
        capacity = count
    }
}

// Own all state that affects style compositing and restore it even if drawing fails. Query both
// values before applying either change, so an unsuccessful query cannot leave a partial mutation.
private func drawStyledImageGeometry(renderer: CPointer<Unit>, texture: CPointer<Unit>, vertices: CPointer<SdlVertex>,
    mesh: CachedMesh, sampling: Int32): Unit {
    var previousSampling: Int32 = 0
    var previousBlend: UInt32 = 0
    ensureSdl(unsafe { SDL_GetTextureScaleMode(texture, inout previousSampling) }, "SDL_GetTextureScaleMode")
    ensureSdl(unsafe { SDL_GetTextureBlendMode(texture, inout previousBlend) }, "SDL_GetTextureBlendMode")
    try {
        if (sampling != previousSampling) {
            ensureSdl(unsafe { SDL_SetTextureScaleMode(texture, sampling) }, "SDL_SetTextureScaleMode")
        }
        if (previousBlend != SDL_BLENDMODE_BLEND) {
            ensureSdl(unsafe { SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND) }, "SDL_SetTextureBlendMode")
        }
        ensureSdl(unsafe {
            SDL_RenderGeometry(renderer, texture, vertices, Int32(mesh.vertCount), mesh.indices, Int32(mesh.idxCount))
        }, "SDL_RenderGeometry(image)")
    } finally {
        try {
            if (previousBlend != SDL_BLENDMODE_BLEND) {
                ensureSdl(unsafe { SDL_SetTextureBlendMode(texture, previousBlend) }, "restore image blending")
            }
        } finally {
            if (sampling != previousSampling) {
                ensureSdl(unsafe { SDL_SetTextureScaleMode(texture, previousSampling) }, "restore image sampling")
            }
        }
    }
}

private func imagePaintVertex(vertex: SdlVertex, destination: Rect, source: Rect, size: Size, style: TextureStyle): SdlVertex {
    var result = vertex
    var u = min(1.0, max(0.0, vertex.px / destination.w))
    var v = min(1.0, max(0.0, vertex.py / destination.h))
    match (style.flip) {
        case TextureFlip.Horizontal => u = 1.0 - u
        case TextureFlip.Vertical => v = 1.0 - v
        case TextureFlip.Both =>
            u = 1.0 - u
            v = 1.0 - v
        case TextureFlip.None => ()
    }
    result.px += destination.x
    result.py += destination.y
    result.tu = (source.x + u * source.w) / size.w
    result.tv = (source.y + v * source.h) / size.h
    result.colR = Float32(style.tint.r) / 255.0
    result.colG = Float32(style.tint.g) / 255.0
    result.colB = Float32(style.tint.b) / 255.0
    result.colA *= Float32(style.tint.a) / 255.0 * style.opacity
    result
}

/** Throws `IllegalArgumentException` for non-finite coordinates or overflowing rectangle edges. */
internal func validateImageRect(rect: Rect): Unit {
    if (!finiteImageCoordinate(rect.x) || !finiteImageCoordinate(rect.y) || !finiteImageCoordinate(rect.w) ||
        !finiteImageCoordinate(rect.h) || !finiteImageCoordinate(rect.right()) || !finiteImageCoordinate(rect.bottom())) {
        throw IllegalArgumentException("Image rectangles must have finite coordinates and edges")
    }
}

private func finiteImageCoordinate(value: Float32): Bool {
    !value.isNaN() && !value.isInf()
}
