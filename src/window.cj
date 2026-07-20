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
    // Supersample factor per axis (1 = off, 2 = default 4x-samples anti-aliasing). Higher is
    // smoother but pays for that many times the pixels every frame; lower trades edge smoothness
    // for fill cost. 2 suits a hardware renderer; a software renderer may want 1.
    public let supersample: Int32

    public init(
        title: String,
        width: Int32,
        height: Int32,
        resizable!: Bool = true,
        highDpi!: Bool = true,
        scale!: Float32 = 1.0,
        vsync!: Bool = true,
        supersample!: Int32 = 2
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

/*
 * An SDL window paired with its `Renderer`, created together and closed together. `width`/`height`
 * and every event and drawing coordinate are logical pixels; `scale` maps them to window pixels.
 * The constructor initializes the video subsystem and starts text input, throwing `CuiException` on
 * failure. `close()` is idempotent and releases the renderer, the window, and one video-subsystem
 * reference — SDL3 ref-counts subsystem init, so closing one window never tears the subsystem down
 * under another still-open window.
 */
public class SdlWindow <: Resource {
    internal let windowPtr: CPointer<Unit>
    private let rendererPtr: CPointer<Unit>
    private var closed = false

    public var width: Int32
    public var height: Int32
    public let scale: Float32
    public let renderer: Renderer

    /**
     * Throws `CuiException` when SDL cannot create or initialize the window, renderer, or text input.
     */
    public init(spec: WindowSpec) {
        this.width = spec.width
        this.height = spec.height
        this.scale = spec.scale

        if (!unsafe { SDL_Init(SDL_INIT_VIDEO) }) {
            throw CuiException("SDL_Init failed: ${lastSdlError()}")
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
                throw CuiException("SDL_CreateWindowAndRenderer failed: ${lastSdlError()}")
            }
            configureRenderer(window, createdRenderer, spec.scale, spec.vsync)
            if (!unsafe { SDL_StartTextInput(window) }) {
                destroyCreatedResources(window, createdRenderer)
                throw CuiException("SDL_StartTextInput failed: ${lastSdlError()}")
            }
        }

        this.windowPtr = window
        this.rendererPtr = createdRenderer
        this.renderer = Renderer(createdRenderer, contentScale: spec.scale, supersample: spec.supersample)
    }

    public func setTitle(title: String): Unit {
        let cTitle = unsafe { LibC.mallocCString(title) }
        try (titleResource = cTitle.asResource()) {
            ensureSdl(unsafe { SDL_SetWindowTitle(windowPtr, titleResource.value) }, "SDL_SetWindowTitle")
        }
    }

    public func setSize(width: Int32, height: Int32): Unit {
        let pixelWidth = scaledDimension(width, scale)
        let pixelHeight = scaledDimension(height, scale)
        ensureSdl(unsafe { SDL_SetWindowSize(windowPtr, pixelWidth, pixelHeight) }, "SDL_SetWindowSize")
        this.width = width
        this.height = height
    }

    public func refreshSize(): Size {
        var w: Int32 = 0
        var h: Int32 = 0
        ensureSdl(unsafe { SDL_GetWindowSize(windowPtr, inout w, inout h) }, "SDL_GetWindowSize")
        width = Int32(Float32(w) / scale)
        height = Int32(Float32(h) / scale)
        Size(Float32(width), Float32(height))
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

    public func pollEvent(): ?UiEvent {
        var raw = SdlEvent()
        if (!unsafe { SDL_PollEvent(inout raw) }) {
            return None
        }
        return Some(scaleEventCoordinates(decodeEvent(raw), scale))
    }

    public func ticks(): UInt64 {
        unsafe { SDL_GetTicks() }
    }

    public func delay(ms: UInt32): Unit {
        unsafe { SDL_Delay(ms) }
    }

    public func isClosed(): Bool {
        closed
    }

    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        renderer.releaseResources()
        unsafe {
            if (windowPtr.isNotNull()) {
                let _ = SDL_StopTextInput(windowPtr)
            }
            if (rendererPtr.isNotNull()) {
                SDL_DestroyRenderer(rendererPtr)
            }
            if (windowPtr.isNotNull()) {
                SDL_DestroyWindow(windowPtr)
            }
            // Balances this window's SDL_Init. Subsystem init is ref-counted in SDL3, so with
            // two live windows closing one must not tear down the video subsystem under the
            // other — SDL_Quit() here would destroy every remaining window and renderer.
            SDL_QuitSubSystem(SDL_INIT_VIDEO)
        }
    }
}
