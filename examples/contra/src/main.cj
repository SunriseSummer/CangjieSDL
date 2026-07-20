package contra
import contra.config.*
import contra.render.*

import sdl.SdlWindow
import sdl.WindowSpec

main(): Int64 {
    try (window = SdlWindow(WindowSpec(Stage.TITLE, Stage.WIDTH, Stage.HEIGHT, resizable: false))) {
        try (assets = GameAssets(window.renderer)) {
            runGame(window, assets)
        }
    }
    return 0
}
