package contra

import sdl.SdlWindow
import contra.render.*
import contra.model.*

@Test
func firstFrameIsPreparedBeforeTheExampleWindowIsVisible(): Unit {
    for (sampling in [Int32(1), Int32(2)]) {
        try (window = createWindow(sampling: sampling)) {
            @Expect(window.windowFlags().hidden)
            let state = GameState()
            try (assets = GameAssets(window.renderer)) {
prepareFirstFrame(window, state, assets)
            @Expect(window.windowFlags().hidden)
            window.show()
            @Expect(!window.windowFlags().hidden)
            draw(window.renderer, state, assets)
            }

        }
    }
}
