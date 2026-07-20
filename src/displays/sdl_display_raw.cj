package sdl.displays

import sdl.{SdlDisplayMode, SdlPoint, SdlRect}

internal let SDL_ORIENTATION_UNKNOWN: Int32 = 0
internal let SDL_ORIENTATION_LANDSCAPE: Int32 = 1
internal let SDL_ORIENTATION_LANDSCAPE_FLIPPED: Int32 = 2
internal let SDL_ORIENTATION_PORTRAIT: Int32 = 3
internal let SDL_ORIENTATION_PORTRAIT_FLIPPED: Int32 = 4

foreign {
    func SDL_free(mem: CPointer<UInt8>): Unit

    func SDL_Init(flags: UInt32): Bool

    func SDL_GetDisplays(count: CPointer<Int32>): CPointer<UInt32>

    func SDL_GetPrimaryDisplay(): UInt32

    func SDL_GetDisplayName(displayId: UInt32): CString

    func SDL_GetDisplayBounds(displayId: UInt32, rect: CPointer<SdlRect>): Bool

    func SDL_GetDisplayUsableBounds(displayId: UInt32, rect: CPointer<SdlRect>): Bool

    func SDL_GetNaturalDisplayOrientation(displayId: UInt32): Int32

    func SDL_GetCurrentDisplayOrientation(displayId: UInt32): Int32

    func SDL_GetDisplayContentScale(displayId: UInt32): Float32

    func SDL_GetFullscreenDisplayModes(displayId: UInt32, count: CPointer<Int32>): CPointer<CPointer<SdlDisplayMode>>

    func SDL_GetClosestFullscreenDisplayMode(
        displayId: UInt32,
        w: Int32,
        h: Int32,
        refreshRate: Float32,
        includeHighDensityModes: Bool,
        closest: CPointer<SdlDisplayMode>
    ): Bool

    func SDL_GetDesktopDisplayMode(displayId: UInt32): CPointer<SdlDisplayMode>

    func SDL_GetCurrentDisplayMode(displayId: UInt32): CPointer<SdlDisplayMode>

    func SDL_GetDisplayForPoint(point: CPointer<SdlPoint>): UInt32

    func SDL_GetDisplayForRect(rect: CPointer<SdlRect>): UInt32
}
