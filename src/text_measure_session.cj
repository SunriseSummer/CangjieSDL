package sdl

private let UTF8_CONTINUATION_LOW: UInt8 = UInt8(128)
private let UTF8_CONTINUATION_HIGH: UInt8 = UInt8(192)

/** The widest UTF-8 prefix accepted by a text-measurement session. */
public struct TextFitResult {
    /** Exact measured width of the returned prefix in logical pixels. */
    public let width: Float32
    /** UTF-8 byte length of the returned prefix, always ending at a code-point boundary. */
    public let byteLength: Int64

    public init(width: Float32, byteLength: Int64) {
        this.width = width
        this.byteLength = byteLength
    }
}

/** Shaped cluster and nearest UTF-8 caret boundary returned by `TextMeasureSession.hitTest`. */
public struct TextHitResult {
    public let byteOffset: Int64
    public let clusterByteLength: Int64
    public let bounds: Rect

    public init(byteOffset: Int64, clusterByteLength: Int64, bounds: Rect) {
        this.byteOffset = byteOffset
        this.clusterByteLength = clusterByteLength
        this.bounds = bounds
    }
}

/**
 * Reuses one UTF-8 buffer and resolved font while fitting many ranges of the same string.
 *
 * Create it with `Renderer.textMeasureSession` and close it after the paragraph has been laid out.
 * Range offsets and lengths are UTF-8 bytes, matching `String.size`; a range that splits a code
 * point throws `IllegalArgumentException`. A closed session rejects further measurement.
 */
public class TextMeasureSession <: Resource {
    private let text: String
    private let owner: RenderDeviceToken
    private let fitImpl: (Int64, Float32) -> TextFitResult
    private let measureImpl: (Int64, Int64) -> Float32
    private let hitTestImpl: (Float32, Float32) -> TextHitResult
    private let closeImpl: () -> Unit
    private var closed: Bool = false

    internal init(
        text: String,
        owner: RenderDeviceToken,
        fitImpl: (Int64, Float32) -> TextFitResult,
        measureImpl: (Int64, Int64) -> Float32,
        hitTestImpl: (Float32, Float32) -> TextHitResult,
        closeImpl: () -> Unit
    ) {
        this.text = text
        this.owner = owner
        this.fitImpl = fitImpl
        this.measureImpl = measureImpl
        this.hitTestImpl = hitTestImpl
        this.closeImpl = closeImpl
    }

    /** UTF-8 byte length of the string owned by this session. */
    public prop byteLength: Int64 {
        get() {
            text.size
        }
    }

    /**
     * Returns the widest prefix at `startByte` no wider than `maxWidth`. The returned length is
     * relative to `startByte`, not the beginning of the string.
     */
    public func fit(startByte: Int64, maxWidth: Float32): TextFitResult {
        ensureOpen()
        requireBoundary(startByte, "startByte")
        if (maxWidth <= 0.0 || startByte == text.size) {
            return TextFitResult(0.0, 0)
        }
        let result = fitImpl(startByte, maxWidth)
        // SDL_ttf promises a UTF-8 prefix. Keep the public boundary strict even if a different
        // backend is supplied later: a malformed backend fails here rather than leaking an invalid
        // slice into user code.
        requireBoundary(startByte + result.byteLength, "fitted end")
        result
    }

    /** Measures an exact UTF-8 byte range. */
    public func measure(startByte: Int64, length: Int64): Float32 {
        ensureOpen()
        if (length < 0 || startByte > text.size - length) {
            throw IllegalArgumentException("Text measurement range is outside the session string")
        }
        requireBoundary(startByte, "startByte")
        requireBoundary(startByte + length, "range end")
        measureImpl(startByte, length)
    }

    /** Finds the nearest shaped-cluster caret boundary for a point in text-local logical pixels. */
    public func hitTest(x: Float32, y!: Float32 = 0.0): TextHitResult {
        ensureOpen()
        let result = hitTestImpl(x, y)
        requireBoundary(result.byteOffset, "hit-test offset")
        result
    }

    /** Releases the owned native UTF-8 buffer; safe to call more than once. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        closeImpl()
    }

    /** Whether `close` has released this session. */
    public func isClosed(): Bool {
        closed || !owner.isActive()
    }

    private func ensureOpen(): Unit {
        if (closed || !owner.isActive()) {
            throw IllegalStateException("Text measurement session is closed")
        }
        owner.ensureAccess("measure text")
    }

    private func requireBoundary(index: Int64, label: String): Unit {
        if (index < 0 || index > text.size || (index < text.size && text[index] >= UTF8_CONTINUATION_LOW &&
            text[index] < UTF8_CONTINUATION_HIGH)) {
            throw IllegalArgumentException("${label} must be a valid UTF-8 byte boundary")
        }
    }
}
