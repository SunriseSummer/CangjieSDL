package game

import sdl.SdlWindow
import sdl.WindowSpec

main(): Int64 {
    try (window = SdlWindow(WindowSpec(Stage.TITLE, Stage.WIDTH, Stage.HEIGHT, resizable: false))) {
        runGame(window)
    }
    return 0
}
