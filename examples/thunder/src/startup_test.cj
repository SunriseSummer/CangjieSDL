package game

import sdl.SdlWindow

@Test
func firstFrameIsPreparedBeforeTheExampleWindowIsVisible(): Unit {
    for (sampling in [Int32(1), Int32(2)]) {
        try (window = createWindow(sampling: sampling)) {
            @Expect(window.windowFlags().hidden)
            let state = GameState()
            prepareFirstFrame(window, state)
            @Expect(window.windowFlags().hidden)
            window.show()
            @Expect(!window.windowFlags().hidden)
            draw(window.renderer, state)
            
        }
    }
}
