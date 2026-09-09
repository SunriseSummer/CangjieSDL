package calculator

import sdl.SdlWindow
import sdl.WindowSpec

main(): Int64 {
    try (window = createWindow()) {
        runCalculator(window)
    }
    return 0
}

// Shared by the real entry point and its native startup regression.
func createWindow(sampling!: Int32 = 0): SdlWindow {
    SdlWindow(WindowSpec(View.TITLE, View.WIDTH, View.HEIGHT, resizable: false, supersample: sampling), hidden: true)
}
