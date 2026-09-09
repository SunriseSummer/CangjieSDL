package sdl.text

/*
 * One owned UTF-8 buffer plus one resolved font. Paragraph layout creates this once and measures
 * many ranges without allocating a CString for every line/probe. The caller validates UTF-8
 * boundaries; SDL_ttf receives explicit byte lengths and never scans past the selected range.
 */
protected class NativeTextMeasureSession <: Resource {
    private static let INITIAL_FIT_WINDOW_BYTES: Int64 = 256
    private static let FIT_WINDOW_GROWTH: Int64 = 4
    private static let UTF8_CONTINUATION_MIN: UInt8 = UInt8(0x80)
    private static let UTF8_CONTINUATION_LIMIT: UInt8 = UInt8(0xC0)
    private static let UTF8_TWO_BYTE_LIMIT: UInt8 = UInt8(0xE0)
    private static let UTF8_THREE_BYTE_LIMIT: UInt8 = UInt8(0xF0)
    private static let UTF8_ONE_BYTE_LENGTH: Int64 = 1
    private static let UTF8_TWO_BYTE_LENGTH: Int64 = 2
    private static let UTF8_THREE_BYTE_LENGTH: Int64 = 3
    private static let UTF8_FOUR_BYTE_LENGTH: Int64 = 4
    private let font: CPointer<Unit>
    private let engine: CPointer<Unit>
    private let text: CString
    private let source: String
    private let releaseFont: () -> Unit
    private let byteLength: Int64
    private var closed: Bool = false
    private var layout: CPointer<Unit> = CPointer<Unit>()
    private let emojiBoundaries: Array<Int64>
    private var rangeStart: Int64 = -1
    private var rangeLength: Int64 = -1
    private var rangeLayout: ?EngineLayout = None

    public init(engine: CPointer<Unit>, font: CPointer<Unit>, value: String, releaseFont: () -> Unit) {
        this.engine = engine
        this.font = font
        this.releaseFont = releaseFont
        this.text = unsafe { LibC.mallocCString(value) }
        this.source = value
        this.byteLength = value.size
        this.emojiBoundaries = if (hasEmojiCandidates(value)) {
            graphemeByteBoundaries(value)
        } else {
            []
        }
    }

    /*
     * Measures the longest UTF-8 prefix beginning at `startByte` that fits `maxWidth`.
     */
    public func fit(startByte: Int64, maxWidth: Int32): NativeTextFit {
        ensureOpen()
        let remaining = byteLength - startByte
        if (remaining <= 0 || maxWidth <= 0) {
            return NativeTextFit(0.0, 0)
        }
        let start = unsafe { text.getChars() + startByte }
        var probeLength = utf8BoundedProbe(startByte, min(remaining, INITIAL_FIT_WINDOW_BYTES))
        var result = NativeTextFit(0.0, 0)
        var settled = false
        while (!settled) {
            var measuredWidth: Int32 = 0
            var measuredLength: UIntNative = UIntNative(0)
            if (!emojiBoundaries.isEmpty()) {
                let fitted = fitEmojiRange(startByte, probeLength, maxWidth)
                measuredWidth = Int32(fitted.width)
                measuredLength = UIntNative(fitted.byteLength)
            } else {
                ensureSessionNative(unsafe {
                    TTF_MeasureString(
                        font,
                        CString(start),
                        UIntNative(probeLength),
                        maxWidth,
                        inout measuredWidth,
                        inout measuredLength
                    )
                }, "TTF_MeasureString")
            }
            if (measuredLength > UIntNative(probeLength)) {
                throw NativeTextException("TTF_MeasureString returned a byte count beyond the supplied buffer")
            }
            let accepted = Int64(measuredLength)
            if (accepted < probeLength || probeLength >= remaining) {
                result = NativeTextFit(Float32(measuredWidth), accepted)
                settled = true
            } else {
                let expanded = if (probeLength > remaining / FIT_WINDOW_GROWTH) {
                    remaining
                } else {
                    probeLength * FIT_WINDOW_GROWTH
                }
                probeLength = utf8BoundedProbe(startByte, min(remaining, expanded))
            }
        }
        result
    }

    /*
     * Measures one validated UTF-8 byte range without constructing a temporary CString.
     */
    public func measure(startByte: Int64, length: Int64): Float32 {
        ensureOpen()
        if (length <= 0) {
            return 0.0
        }
        if (!emojiBoundaries.isEmpty()) {
            return preparedRange(startByte, length).metrics.width
        }
        var width: Int32 = 0
        var height: Int32 = 0
        let start = unsafe { text.getChars() + startByte }
        ensureSessionNative(unsafe {
            TTF_GetStringSize(
                font,
                CString(start),
                UIntNative(length),
                inout width,
                inout height
            )
        }, "TTF_GetStringSize")
        Float32(width)
    }

    /** Returns the shaped cluster/caret boundary closest to a text-local point. */
    public func hitTest(x: Int32, y: Int32): NativeTextHit {
        ensureOpen()
        ensureLayout()
        let substring = nativeEngineEntry(layout).layout.substringAt(x, y)
        let direction = substring.flags & UInt32(0xFF)
        let afterVisualMidpoint = x >= substring.rect.x + substring.rect.w / 2
        let offset = if (direction == UInt32(5)) {
            if (afterVisualMidpoint) {
                substring.offset
            } else {
                substring.offset + substring.length
            }
        } else if (afterVisualMidpoint) {
            substring.offset + substring.length
        } else {
            substring.offset
        }
        NativeTextHit(Int64(offset), Int64(substring.length), Float32(substring.rect.x), Float32(substring.rect.y),
            Float32(substring.rect.w), Float32(substring.rect.h))
    }

    /*
     * Releases the owned UTF-8 buffer; repeated calls are safe.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        if (layout.isNotNull()) {
            destroyNativeText(layout)
            layout = CPointer<Unit>()
        }
        unsafe { LibC.free(text) }
        releaseFont()
        rangeLayout = None
    }

    /*
     * Reports whether the owned UTF-8 buffer has already been released.
     */
    public func isClosed(): Bool {
        closed
    }

    private func ensureOpen(): Unit {
        if (closed) {
            throw IllegalStateException("Text measurement session is closed")
        }
    }

    private func ensureLayout(): Unit {
        if (layout.isNotNull()) {
            return
        }
        layout = createNativeText(engine, font, text, UIntNative(byteLength))
        if (layout.isNull()) {
            throw NativeTextException("TTF_CreateText failed: ${lastNativeError()}")
        }
    }

    private func utf8BoundedProbe(startByte: Int64, wanted: Int64): Int64 {
        if (!emojiBoundaries.isEmpty()) {
            var low: Int64 = 0;
            var high = emojiBoundaries.size - 1
            let end = startByte + wanted
            while (low < high) {
                let mid = low + (high - low) / 2
                if (emojiBoundaries[mid] < end) {
                    low = mid + 1
                } else {
                    high = mid
                }
            }
            return emojiBoundaries[low] - startByte
        }
        var end = startByte + wanted
        while (end < byteLength && source[end] >= UTF8_CONTINUATION_MIN && source[end] < UTF8_CONTINUATION_LIMIT) {
            end -= 1
        }
        if (end == startByte) {
            let lead = source[startByte]
            end += if (lead < UTF8_CONTINUATION_MIN) {
                UTF8_ONE_BYTE_LENGTH
            } else if (lead < UTF8_TWO_BYTE_LIMIT) {
                UTF8_TWO_BYTE_LENGTH
            } else if (lead < UTF8_THREE_BYTE_LIMIT) {
                UTF8_THREE_BYTE_LENGTH
            } else {
                UTF8_FOUR_BYTE_LENGTH
            }
        }
        end - startByte
    }

    private func preparedRange(start: Int64, length: Int64): EngineLayout {
        if (rangeStart == start && rangeLength == length) {
            if (let Some(value) <- rangeLayout) {
                return value
            }
        }
        let pointer = createNativeText(engine, font, CString(unsafe { text.getChars() + start }), UIntNative(length))
        if (pointer.isNull()) {
            throw NativeTextException("Cannot prepare text range: ${lastNativeError()}")
        }
        let result = try {
            nativeEngineEntry(pointer).layout
        } finally {
            destroyNativeText(pointer)
        }
        rangeStart = start
        rangeLength = length
        rangeLayout = Some(result)
        result
    }

    private func fitEmojiRange(start: Int64, length: Int64, width: Int32): NativeTextFit {
        let prepared = preparedRange(start, length)
        var accepted: Int64 = 0
        var measured: Int32 = 0
        if (prepared.runs.isEmpty()) {
            var count: UIntNative = 0
            ensureSessionNative(
                unsafe { TTF_MeasureString(font, CString(text.getChars() + start), UIntNative(length), width,
                    inout measured, inout count) }, "TTF_MeasureString")
            accepted = Int64(count)
        } else {
            for (run in prepared.runs) {
                if (run.line != 0) {
                    break
                }
                if (measured + run.width <= width) {
                    measured += run.width
                    accepted = run.start + run.length
                } else {
                    if (measured >= width) {
                        break
                    }
                    var count: UIntNative = 0;
                    var partWidth: Int32 = 0
                    ensureSessionNative(
                        unsafe { TTF_MeasureString(run.font, CString(text.getChars() + start + run.start),
                            UIntNative(run.length), max(0, width - measured), inout partWidth, inout count) },
                        "TTF_MeasureString")
                    accepted = run.start + Int64(count)
                    measured += partWidth
                    break
                }
            }
        }
        finishEmojiFit(start, accepted, measured)
    }

    private func finishEmojiFit(start: Int64, amount: Int64, width: Int32): NativeTextFit {
        var accepted = amount
        var measured = width
        var low: Int64 = 0;
        var high = emojiBoundaries.size
        while (low < high) {
            let mid = low + (high - low) / 2
            if (emojiBoundaries[mid] <= start + accepted) {
                low = mid + 1
            } else {
                high = mid
            }
        }
        let whole = max(0, emojiBoundaries[max(0, low - 1)] - start)
        if (whole != accepted) {
            accepted = whole
            measured = if (whole == 0) {
                0
            } else {
                Int32(preparedRange(start, whole).metrics.width)
            }
        }
        NativeTextFit(Float32(measured), accepted)
    }
}

private func ensureSessionNative(ok: Bool, api: String): Unit {
    if (!ok) {
        throw NativeTextException("${api} failed: ${lastNativeError()}")
    }
}
