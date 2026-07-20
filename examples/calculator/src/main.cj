package calculator

import sdl.SdlWindow
import sdl.WindowSpec

main(): Int64 {
    try (window = SdlWindow(WindowSpec(View.TITLE, View.WIDTH, View.HEIGHT, resizable: false))) {
        runCalculator(window)
    }
    return 0
}
