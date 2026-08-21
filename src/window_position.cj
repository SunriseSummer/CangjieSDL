package sdl

/** A window's top-left corner position in screen coordinates. */
public struct WindowPosition {
    public let x: Int32
    public let y: Int32

    public init(x: Int32, y: Int32) {
        this.x = x
        this.y = y
    }
}
