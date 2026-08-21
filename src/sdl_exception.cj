package sdl

/** Signals a failed SDL call or invalid argument, carrying the SDL error message. */
public class SdlException <: Exception {
    public init(message: String) {
        super(message)
    }
}
