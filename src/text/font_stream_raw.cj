package sdl.text

foreign {
    func SDL_IOFromConstMem(bytes: CPointer<Unit>, length: UIntNative): CPointer<Unit>

    func SDL_GetIOSize(stream: CPointer<Unit>): Int64

    func SDL_SeekIO(stream: CPointer<Unit>, offset: Int64, whence: Int32): Int64

    func SDL_ReadIO(stream: CPointer<Unit>, target: CPointer<Unit>, count: UIntNative): UIntNative

    func SDL_CloseIO(stream: CPointer<Unit>): Bool

    func SDL_SetPointerProperty(props: UInt32, name: CString, value: CPointer<Unit>): Bool

    func SDL_SetError(format: CString, message: CString): Bool

    func TTF_Version(): Int32
}

internal func fontCallbackError(message: String): Unit {
    try {
        let format = unsafe { LibC.mallocCString("%s") }
        let text = unsafe { LibC.mallocCString(message) }
        try (formatResource = format.asResource(), textResource = text.asResource()) {
            let _ = unsafe { SDL_SetError(formatResource.value, textResource.value) } // cjcheck-ignore: ignore-result # SDL_SetError always returns false; the error string is the intended result
        }
    } catch (_: Exception) { // cjcheck-ignore: swallow-catch # C callback error reporting cannot propagate allocation failures across the ABI
        // Error reporting must never let a Cangjie exception escape a C callback.
    }
}

// Leaf memory copy is limited to the final partial mapping page (less than 64 KiB).
@FastNative
foreign func memcpy(destination: CPointer<UInt8>, source: CPointer<UInt8>, count: UIntNative): CPointer<UInt8>
