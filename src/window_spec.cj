package sdl

/**
 * Construction-time window options: title, logical size, DPI/scale behaviour, vsync, and the
 * renderer's supersample factor. A plain value read once by `SdlWindow` (or `DesktopApp`);
 * changing a spec after creation has no effect on the window.
 */
public struct WindowSpec {
    public let title: String
    public let width: Int32
    public let height: Int32
    public let resizable: Bool
    public let highDpi: Bool
    public let scale: Float32
    // Whether the renderer waits for the vertical blank on present. On (the default) prevents
    // tearing and is the right choice for real applications. Off lets the frame loop run
    // uncapped, which is how a benchmark measures true per-frame work: with vsync on, every
    // frame period snaps to a refresh multiple (16.7/33.3/50 ms at 60 Hz), so any improvement
    // smaller than a whole refresh interval is invisible.
    public let vsync: Bool
    // Supersample factor per axis. 0 (default) selects 2x below 2 physical pixels per logical unit
    // when its target fits the Auto pixel/hardware budget, otherwise 1x. Positive values are exact
    // compatibility overrides and ignore the framework pixel budget.
    public let supersample: Int32

    public init(
        title: String,
        width: Int32,
        height: Int32,
        resizable!: Bool = true,
        highDpi!: Bool = true,
        scale!: Float32 = 1.0,
        vsync!: Bool = true,
        supersample!: Int32 = 0
    ) {
        if (width <= 0 || height <= 0) {
            throw IllegalArgumentException("WindowSpec width and height must be positive")
        }
        this.title = title
        this.width = width
        this.height = height
        this.resizable = resizable
        this.highDpi = highDpi
        this.scale = normalizedScale(scale)
        this.vsync = vsync
        this.supersample = supersample
    }
}

/** Dynamic DPI values for one window, separating UI size from backing-store pixel density. */
public struct WindowDisplayMetrics {
    /** Window-coordinate units per CUI logical unit, including the application's requested zoom. */
    public let contentScale: Float32
    /** Backing pixels per native window-coordinate unit. */
    public let pixelDensity: Float32
    /** Total logical-to-backing-pixel scale used by the Renderer. */
    public let renderScale: Float32
    /** SDL's combined display scale before application zoom is applied. */
    public let displayScale: Float32

    public init(contentScale: Float32, pixelDensity: Float32, renderScale: Float32, displayScale: Float32) {
        this.contentScale = contentScale
        this.pixelDensity = pixelDensity
        this.renderScale = renderScale
        this.displayScale = displayScale
    }
}
