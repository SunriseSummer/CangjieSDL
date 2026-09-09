package contra

import contra.config.*
import contra.render.*
import sdl.SdlWindow
import sdl.WindowSpec

main(): Int64 {
    try (window = createWindow()) {
        try (assets = GameAssets(window.renderer)) {
            runGame(window, assets)
        }
    }
    return 0
}

// Shared by the real entry point and its native startup regression.
func createWindow(sampling!: Int32 = 0): SdlWindow {
    SdlWindow(WindowSpec(Stage.TITLE, Stage.WIDTH, Stage.HEIGHT, resizable: false, supersample: sampling), hidden: true)
}
