package sdl

private let AUTO_SUPERSAMPLE_PHYSICAL_SCALE: Float32 = 2.0
// 32 Mi pixels keeps a 2x 4K target (~127 MiB RGBA8) but refuses pathological 5K/8K Auto
// allocations. Explicit positive factors remain exact compatibility requests.
private let AUTO_SUPERSAMPLE_TARGET_PIXEL_BUDGET: Int64 = 32 * 1024 * 1024

/** Why the current renderer is direct or backed by a supersampling target. */
public enum RenderSamplingStatus {
    | Direct
    | Supersampled
    | AutomaticPixelBudget
    | TextureSizeLimit
    | OutputUnavailable
    | TargetAllocationFailure
}

/** Stable, allocation-free diagnostics for the current render-sampling decision. */
public struct RenderSamplingStats {
    public let requestedFactor: Int32
    public let selectedFactor: Int32
    public let targetWidth: Int32
    public let targetHeight: Int32
    public let estimatedTargetBytes: UInt64
    public let maxTextureSize: Int32
    public let status: RenderSamplingStatus

    internal init(
        requestedFactor: Int32,
        selectedFactor: Int32,
        targetWidth: Int32,
        targetHeight: Int32,
        estimatedTargetBytes: UInt64,
        maxTextureSize: Int32,
        status: RenderSamplingStatus
    ) {
        this.requestedFactor = requestedFactor
        this.selectedFactor = selectedFactor
        this.targetWidth = targetWidth
        this.targetHeight = targetHeight
        this.estimatedTargetBytes = estimatedTargetBytes
        this.maxTextureSize = maxTextureSize
        this.status = status
    }
}

internal struct SupersampleTargetPlan {
    let factor: Int32
    let targetWidth: Int32
    let targetHeight: Int32
    let automaticBudgetLimited: Bool
    let textureSizeLimited: Bool
    let outputUnavailable: Bool

    init(
        factor: Int32,
        targetWidth!: Int32 = 0,
        targetHeight!: Int32 = 0,
        automaticBudgetLimited!: Bool = false,
        textureSizeLimited!: Bool = false,
        outputUnavailable!: Bool = false
    ) {
        this.factor = factor
        this.targetWidth = targetWidth
        this.targetHeight = targetHeight
        this.automaticBudgetLimited = automaticBudgetLimited
        this.textureSizeLimited = textureSizeLimited
        this.outputUnavailable = outputUnavailable
    }
}

internal func rendererMaxTextureSize(renderer: CPointer<Unit>): Int32 {
    if (renderer.isNull()) {
        return Int32.Max
    }
    let properties = unsafe { SDL_GetRendererProperties(renderer) }
    if (properties == UInt32(0)) {
        return Int32.Max
    }
    let propertyName = unsafe { LibC.mallocCString("SDL.renderer.max_texture_size") }
    var result = Int32.Max
    try (nameResource = propertyName.asResource()) {
        let reported = unsafe {
            SDL_GetNumberProperty(properties, nameResource.value, Int64(Int32.Max))
        }
        if (reported > Int64(0) && reported <= Int64(Int32.Max)) {
            result = Int32(reported)
        }
    }
    result
}

internal func resolveSupersampleFactor(requested: Int32, physicalScale: Float32): Int32 {
    if (requested == Int32(0)) {
        if (normalizedScale(physicalScale) >= AUTO_SUPERSAMPLE_PHYSICAL_SCALE) {
            Int32(1)
        } else {
            Int32(2)
        }
    } else if (requested < Int32(1)) {
        Int32(1)
    } else {
        requested
    }
}

/*
 * Resolves density, memory and native texture limits before any Int32 multiplication or GPU
 * allocation. Auto is quality-seeking within a bounded resource lattice; explicit factors ignore
 * the framework pixel budget but still cannot exceed arithmetic or hardware dimensions.
 */
internal func planSupersampleTarget(
    requested: Int32,
    physicalScale: Float32,
    outputWidth: Int32,
    outputHeight: Int32,
    maxTextureSize: Int32
): SupersampleTargetPlan {
    let desired = resolveSupersampleFactor(requested, physicalScale)
    if (desired <= Int32(1)) {
        return SupersampleTargetPlan(Int32(1))
    }
    if (outputWidth <= Int32(0) || outputHeight <= Int32(0)) {
        return SupersampleTargetPlan(Int32(1), outputUnavailable: true)
    }
    if (requested == Int32(0)) {
        let outputPixels = Int64(outputWidth) * Int64(outputHeight)
        let samplesPerPixel = Int64(desired) * Int64(desired)
        if (outputPixels > AUTO_SUPERSAMPLE_TARGET_PIXEL_BUDGET / samplesPerPixel) {
            return SupersampleTargetPlan(Int32(1), automaticBudgetLimited: true)
        }
    }
    let dimensionLimit = if (maxTextureSize > Int32(0)) {
        maxTextureSize
    } else {
        Int32.Max
    }
    if (outputWidth > dimensionLimit / desired || outputHeight > dimensionLimit / desired) {
        return SupersampleTargetPlan(Int32(1), textureSizeLimited: true)
    }
    SupersampleTargetPlan(desired, targetWidth: outputWidth * desired, targetHeight: outputHeight * desired)
}
