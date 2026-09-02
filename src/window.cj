package sdl

import std.sync.Mutex

internal class WindowWakeEventRegistry {
    private static let lock = Mutex()
    private static var registeredType: UInt32 = UInt32(0)

    static func eventType(): UInt32 {
        var result: UInt32 = UInt32(0)
        synchronized(lock) {
            if (registeredType == UInt32(0)) {
                // SDL3 returns zero when the finite user-event range cannot satisfy a request.
                registeredType = unsafe { SDL_RegisterEvents(1) }
            }
            result = registeredType
        }
        result
    }
}

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

/*
 * An SDL window paired with its `Renderer`, created together and closed together. `width`/`height`
 * and every event and drawing coordinate are logical pixels; `scale` maps them to window pixels.
 * The constructor initializes the video subsystem and starts text input, throwing `SdlException` on
 * failure. `close()` is idempotent and releases the renderer, the window, and one video-subsystem
 * reference — SDL3 ref-counts subsystem init, so closing one window never tears the subsystem down
 * under another still-open window.
 */
public class SdlWindow <: Resource {
    internal let windowPtr: CPointer<Unit>
    private let rendererPtr: CPointer<Unit>
    private var wakeEventType: UInt32 = UInt32(0)
    private var closed = false

    private var idValue: UInt32 = UInt32(0)

    /** Stable SDL identifier carried by window, keyboard, pointer, drop, and renderer events. */
    public prop id: UInt32 {
        get() {
            idValue
        }
    }

    private var widthValue: Int32
    private var heightValue: Int32
    private let userScale: Float32
    private var scaleValue: Float32
    private var pixelDensityValue: Float32 = 1.0
    private var displayScaleValue: Float32 = 1.0

    /** Dynamic native-window-coordinate scale for one logical UI unit. */
    public prop scale: Float32 {
        get() {
            scaleValue
        }
    }

    /** Dynamic backing-pixel density relative to native window coordinates. */
    public prop currentPixelDensity: Float32 {
        get() {
            pixelDensityValue
        }
    }

    /** SDL's current combined display scale for this window. */
    public prop currentDisplayScale: Float32 {
        get() {
            displayScaleValue
        }
    }

    /** Current window width in logical pixels; updated by `setSize`/`refreshSize`. */
    public prop width: Int32 {
        get() {
            widthValue
        }
    }

    /** Current window height in logical pixels; updated by `setSize`/`refreshSize`. */
    public prop height: Int32 {
        get() {
            heightValue
        }
    }
    public let renderer: Renderer

    /**
     * Throws `SdlException` when SDL cannot create or initialize the window, renderer, or text input.
     */
    public init(spec: WindowSpec) {
        this.widthValue = spec.width
        this.heightValue = spec.height
        this.userScale = spec.scale
        this.scaleValue = spec.scale

        if (!unsafe { SDL_Init(SDL_INIT_VIDEO) }) {
            throw SdlException("SDL_Init failed: ${lastSdlError()}")
        }

        var flags = UInt64(0)
        if (spec.resizable) {
            flags = flags | SDL_WINDOW_RESIZABLE
        }
        if (spec.highDpi) {
            flags = flags | SDL_WINDOW_HIGH_PIXEL_DENSITY
        }

        var window = CPointer<Unit>()
        var createdRenderer = CPointer<Unit>()
        let titleText = unsafe { LibC.mallocCString(spec.title) }
        try (titleResource = titleText.asResource()) {
            let pixelWidth = scaledDimension(spec.width, spec.scale)
            let pixelHeight = scaledDimension(spec.height, spec.scale)
            let ok = unsafe {
                SDL_CreateWindowAndRenderer(titleResource.value, pixelWidth, pixelHeight, flags, inout window,
                    inout createdRenderer)
            }
            if (!ok || window.isNull() || createdRenderer.isNull()) {
                destroyCreatedResources(window, createdRenderer)
                throw SdlException("SDL_CreateWindowAndRenderer failed: ${lastSdlError()}")
            }
            let createdWindowId = unsafe { SDL_GetWindowID(window) }
            if (createdWindowId == UInt32(0)) {
                destroyCreatedResources(window, createdRenderer)
                throw SdlException("SDL_GetWindowID failed: ${lastSdlError()}")
            }
            this.idValue = createdWindowId
            let displayMetrics = queryWindowDisplayMetrics(window, userScale)
            this.scaleValue = displayMetrics.contentScale
            this.pixelDensityValue = displayMetrics.pixelDensity
            this.displayScaleValue = displayMetrics.displayScale
            if (floatDifference(scaleValue, spec.scale) > Float32(0.001)) {
                ensureSdl(unsafe {
                    SDL_SetWindowSize(window, scaledDimension(spec.width, scaleValue),
                        scaledDimension(spec.height, scaleValue))
                }, "SDL_SetWindowSize")
            }
            configureRenderer(window, createdRenderer, displayMetrics.renderScale, spec.vsync)
            let registeredWake = WindowWakeEventRegistry.eventType()
            if (registeredWake == UInt32(0)) {
                destroyCreatedResources(window, createdRenderer)
                throw SdlException("SDL_RegisterEvents failed: ${lastSdlError()}")
            }
            this.wakeEventType = registeredWake
            if (!unsafe { SDL_StartTextInput(window) }) {
                destroyCreatedResources(window, createdRenderer)
                throw SdlException("SDL_StartTextInput failed: ${lastSdlError()}")
            }
        }

        this.windowPtr = window
        this.rendererPtr = createdRenderer
        this.renderer = Renderer(createdRenderer, contentScale: scaleValue * pixelDensityValue,
            supersample: spec.supersample)
    }

    /** Sets the window title. Throws `SdlException` when SDL cannot apply it. */
    public func setTitle(title: String): Unit {
        let cTitle = unsafe { LibC.mallocCString(title) }
        try (titleResource = cTitle.asResource()) {
            ensureSdl(unsafe { SDL_SetWindowTitle(windowPtr, titleResource.value) }, "SDL_SetWindowTitle")
        }
    }

    /*
     * Resizes the window to the given logical size, converting to window pixels via `scale`, and
     * updates the cached `width`/`height`. Throws `SdlException` when SDL rejects the resize.
     */
    public func setSize(width: Int32, height: Int32): Unit {
        let pixelWidth = scaledDimension(width, scale)
        let pixelHeight = scaledDimension(height, scale)
        ensureSdl(unsafe { SDL_SetWindowSize(windowPtr, pixelWidth, pixelHeight) }, "SDL_SetWindowSize")
        this.widthValue = width
        this.heightValue = height
    }

    /*
     * Re-reads the current window size from SDL (e.g. after a user resize), refreshes the cached
     * `width`/`height` in logical pixels, and returns the logical size. Throws `SdlException`
     * when SDL cannot report the size.
     */
    public func refreshSize(): Size {
        renderer.ensureRenderAccess("refresh SdlWindow size")
        var w: Int32 = 0
        var h: Int32 = 0
        ensureSdl(unsafe { SDL_GetWindowSize(windowPtr, inout w, inout h) }, "SDL_GetWindowSize")
        widthValue = Int32(Float32(w) / scale)
        heightValue = Int32(Float32(h) / scale)
        renderer.refreshOutputSampling()
        Size(Float32(widthValue), Float32(heightValue))
    }

    /** Refreshes dynamic DPI values and updates the Renderer scale/epoch when they change. */
    public func refreshDisplayMetrics(): WindowDisplayMetrics {
        renderer.ensureRenderAccess("refresh window display metrics")
        let metrics = queryWindowDisplayMetrics(windowPtr, userScale)
        let changed = floatDifference(scaleValue, metrics.contentScale) > Float32(0.001) ||
            floatDifference(pixelDensityValue, metrics.pixelDensity) > Float32(0.001) ||
            floatDifference(displayScaleValue, metrics.displayScale) > Float32(0.001)
        scaleValue = metrics.contentScale
        pixelDensityValue = metrics.pixelDensity
        displayScaleValue = metrics.displayScale
        if (changed) {
            renderer.updateContentScale(metrics.renderScale)
            refreshAndValidateSize()
        }
        metrics
    }

    /**
     * Tells the OS where the text caret is, in the window's logical pixels (the same space
     * as events and drawing), so IME composition UI — the candidate window — appears at the
     * caret instead of a screen corner. The conversion to window pixels happens here.
     */
    public func setTextInputArea(rect: Rect): Unit {
        var raw = Rect(rect.x * scale, rect.y * scale, rect.w * scale, rect.h * scale).toSdlRect()
        ensureSdl(unsafe { SDL_SetTextInputArea(windowPtr, inout raw, 0) }, "SDL_SetTextInputArea")
    }

    /*
     * Dequeues the next pending event, with coordinates already converted to logical pixels;
     * returns `None` when the queue is empty. Non-blocking.
     */
    public func pollEvent(): ?UiEvent {
        match (pollEventRecord()) {
            case Some(record) => Some(record.event)
            case None => None
        }
    }

    /** Dequeues one event with its event-time window, timestamp, keycode, and modifier snapshot. */
    public func pollEventRecord(): ?UiEventRecord {
        var raw = SdlEvent()
        if (!unsafe { SDL_PollEvent(inout raw) }) {
            return None
        }
        return Some(decodeWindowEvent(raw))
    }

    /**
     * Waits for an event for at most `timeoutMs` milliseconds. A negative timeout waits
     * indefinitely; zero only checks the queue. Returns `None` on timeout.
     */
    public func waitEventTimeout(timeoutMs: Int32): ?UiEvent {
        match (waitEventRecordTimeout(timeoutMs)) {
            case Some(record) => Some(record.event)
            case None => None
        }
    }

    /** Waits like `waitEventTimeout` and preserves the native event metadata. */
    public func waitEventRecordTimeout(timeoutMs: Int32): ?UiEventRecord {
        var raw = SdlEvent()
        if (!unsafe { SDL_WaitEventTimeout(inout raw, timeoutMs) }) {
            return None
        }
        Some(decodeWindowEvent(raw))
    }

    /**
     * Wakes a thread blocked in `waitEventTimeout`. SDL copies the event before this method
     * returns, so it is safe to call from a worker thread.
     */
    public func wake(): Bool {
        let rawPtr = unsafe { LibC.malloc<SdlEvent>() }
        var pushed = false
        try (rawResource = rawPtr.asResource()) {
            unsafe { rawResource.value.write(SdlEvent()) }
            let userPtr = CPointer<SdlUserEvent>(rawResource.value)
            var user = SdlUserEvent()
            user.eventType = wakeEventType
            // SDL fills a zero timestamp with SDL_GetTicksNS when the event enters the queue.
            user.timestamp = UInt64(0)
            user.windowID = id
            unsafe { userPtr.write(user) }
            pushed = unsafe { SDL_PushEvent(rawResource.value) }
        }
        pushed
    }

    internal func diagnosticWakeEventType(): UInt32 {
        wakeEventType
    }

    /** Milliseconds elapsed since SDL library initialization. */
    public func ticks(): UInt64 {
        unsafe { SDL_GetTicks() }
    }

    /** Blocks the calling thread for at least `ms` milliseconds. */
    public func delay(ms: UInt32): Unit {
        unsafe { SDL_Delay(ms) }
    }

    private func decodeWindowEvent(raw: SdlEvent): UiEventRecord {
        adaptEventRecord(decodeNativeEventRecord(raw))
    }

    internal func adaptEventRecord(record: UiEventRecord): UiEventRecord {
        let decoded = scaleEventRecord(record, scale)
        processWindowEvent(decoded.event)
        decoded
    }

    private func processWindowEvent(event: UiEvent): Unit {
        match (event) {
            case UiEvent.WindowResized(_, _) => refreshAndValidateSize()
            case UiEvent.WindowDisplayScaleChanged => let _ = refreshDisplayMetrics()
            case UiEvent.WindowPixelSizeChanged(_, _) => let _ = refreshDisplayMetrics()
            case UiEvent.RenderTargetsReset => renderer.noteRenderReset()
            case UiEvent.RenderDeviceReset => renderer.noteRenderReset()
            case UiEvent.RenderDeviceLost => renderer.noteRenderReset()
            case _ => ()
        }
    }

    private func refreshAndValidateSize(): Unit {
        let refreshed = refreshSize()
        if (refreshed.w < 0.0 || refreshed.h < 0.0) {
            throw SdlException("SDL reported a negative logical window size")
        }
    }

    private func decodeNativeEventRecord(raw: SdlEvent): UiEventRecord {
        let rawPtr = unsafe { LibC.malloc<SdlEvent>() }
        var decoded = UiEventRecord(UiEvent.Unknown(UInt32(0)))
        try (rawResource = rawPtr.asResource()) {
            unsafe { rawResource.value.write(raw) }
            let common = unsafe { CPointer<SdlCommonEvent>(rawResource.value).read() }
            decoded = if (common.eventType == wakeEventType) {
                let user = unsafe { CPointer<SdlUserEvent>(rawResource.value).read() }
                UiEventRecord(UiEvent.Wake, UiEventMetadata(timestampNs: user.timestamp, windowId: user.windowID))
            } else {
                decodeEventRecord(raw)
            }
        }
        decoded
    }

    /** Whether `close()` has already been called on this window. */
    public func isClosed(): Bool {
        closed
    }

    /*
     * Releases the window's resources; idempotent — a second call returns immediately. Order:
     * renderer resources, text input, the SDL renderer, the SDL window, then one video-subsystem
     * reference (leaving other open windows' subsystem state intact).
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        renderer.ensureRenderAccess("close SdlWindow")
        closed = true
        renderer.releaseResources()
        if (windowPtr.isNotNull()) {
            let _ = unsafe { SDL_StopTextInput(windowPtr) } // cjcheck-ignore: ignore-result # shutdown path is best-effort: the resource is being destroyed regardless
        }
        if (rendererPtr.isNotNull()) {
            unsafe { SDL_DestroyRenderer(rendererPtr) }
        }
        if (windowPtr.isNotNull()) {
            unsafe { SDL_DestroyWindow(windowPtr) }
        }
        // Balances this window's SDL_Init. Subsystem init is ref-counted in SDL3, so with
        // two live windows closing one must not tear down the video subsystem under the
        // other — SDL_Quit() here would destroy every remaining window and renderer.
        unsafe { SDL_QuitSubSystem(SDL_INIT_VIDEO) }
    }
}

private func queryWindowDisplayMetrics(window: CPointer<Unit>, userScale: Float32): WindowDisplayMetrics {
    let densityValue = unsafe { SDL_GetWindowPixelDensity(window) }
    let displayValue = unsafe { SDL_GetWindowDisplayScale(window) }
    let density = if (densityValue > Float32(0.0)) {
        densityValue
    } else {
        Float32(1.0)
    }
    let display = if (displayValue > Float32(0.0)) {
        displayValue
    } else {
        density
    }
    displayMetricsFromScales(userScale, density, display)
}

internal func displayMetricsFromScales(
    userScale: Float32,
    pixelDensity: Float32,
    displayScale: Float32
): WindowDisplayMetrics {
    let density = normalizedScale(pixelDensity)
    let display = normalizedScale(displayScale)
    let systemContentScale = normalizedScale(display / density)
    let contentScale = normalizedScale(userScale * systemContentScale)
    WindowDisplayMetrics(contentScale, density, contentScale * density, display)
}

private func floatDifference(left: Float32, right: Float32): Float32 {
    let difference = left - right
    if (difference < Float32(0.0)) {
        -difference
    } else {
        difference
    }
}
