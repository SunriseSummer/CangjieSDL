package sdl.text

// Public SDL_textengine.h ABI (SDL_ttf 3.2+). All fields are read-only to this backend.
@C
internal struct EngineColor {
    var r: Float32 = 1.0
    var g: Float32 = 1.0
    var b: Float32 = 1.0
    var a: Float32 = 1.0
}

@C
internal struct EngineCopy {
    var command: Int32 = 0
    var textOffset: Int32 = 0
    var font = CPointer<Unit>()
    var glyph: UInt32 = 0
    var source = TtfSubstringRect()
    var destination = TtfSubstringRect()
    var reserved = CPointer<Unit>()
}

@C
internal struct EngineFill {
    var command: Int32 = 0
    var rectangle = TtfSubstringRect()
}

@C
internal struct EngineTextData {
    var font = CPointer<Unit>()
    var color = EngineColor()
    var needsLayout: Bool = false
    var layout = CPointer<Unit>()
    var x: Int32 = 0
    var y: Int32 = 0
    var width: Int32 = 0
    var height: Int32 = 0
    var operationCount: Int32 = 0
    var operations = CPointer<EngineCopy>()
    var clusterCount: Int32 = 0
    var clusters = CPointer<TtfSubstring>()
    var properties: UInt32 = 0
    var needsEngine: Bool = false
    var engine = CPointer<Unit>()
    var engineText = CPointer<Unit>()
}

@C
internal struct EngineText {
    var text = CString(CPointer<UInt8>())
    var lines: Int32 = 0
    var references: Int32 = 0
    var data = CPointer<EngineTextData>()
}

@C
internal struct EngineSurface {
    var flags: UInt32 = 0
    var format: UInt32 = 0
    var width: Int32 = 0
    var height: Int32 = 0
    var pitch: Int32 = 0
    var pixels = CPointer<Unit>()
}

foreign {
    func TTF_UpdateText(text: CPointer<Unit>): Bool

    func TTF_GetTextDirection(text: CPointer<Unit>): Int32

    func TTF_GetGlyphImageForIndex(font: CPointer<Unit>, glyph: UInt32, kind: CPointer<Int32>): CPointer<Unit>

    func TTF_GetGlyphMetrics(font: CPointer<Unit>, codepoint: UInt32, minX: CPointer<Int32>, maxX: CPointer<Int32>,
        minY: CPointer<Int32>, maxY: CPointer<Int32>, advance: CPointer<Int32>): Bool

    func SDL_CreateSurface(width: Int32, height: Int32, format: UInt32): CPointer<Unit>

    func SDL_DestroySurface(surface: CPointer<Unit>): Unit

    func SDL_FillSurfaceRect(surface: CPointer<Unit>, rect: CPointer<TtfSubstringRect>, color: UInt32): Bool

    func SDL_BlitSurface(source: CPointer<Unit>, sourceRect: CPointer<TtfSubstringRect>, destination: CPointer<Unit>,
        destinationRect: CPointer<TtfSubstringRect>): Bool

    func SDL_CreateTexture(renderer: CPointer<Unit>, format: UInt32, access: Int32, width: Int32, height: Int32): CPointer<Unit>

    func SDL_DestroyTexture(texture: CPointer<Unit>): Unit

    func SDL_UpdateTexture(texture: CPointer<Unit>, rect: CPointer<TtfSubstringRect>, pixels: CPointer<Unit>,
        pitch: Int32): Bool

    func SDL_SetTextureBlendMode(texture: CPointer<Unit>, mode: UInt32): Bool

    func SDL_SetTextureScaleMode(texture: CPointer<Unit>, mode: Int32): Bool

    func SDL_RenderGeometryRaw(renderer: CPointer<Unit>, texture: CPointer<Unit>, xy: CPointer<Float32>,
        xyStride: Int32, color: CPointer<EngineColor>, colorStride: Int32, uv: CPointer<Float32>, uvStride: Int32,
        vertexCount: Int32, indices: CPointer<Int32>, indexCount: Int32, indexSize: Int32): Bool
}
