package sdl

@Test
func hiddenWindowStaysHiddenUntilExplicitShow(): Unit {
    for (sampling in [Int32(1), Int32(2)]) {
        try (window = SdlWindow(WindowSpec("Hidden first frame", 160, 100, vsync: false, supersample: sampling),
            hidden: true)) {
            @Expect(window.windowFlags().hidden)
            window.renderer.beginScene(160.0, 100.0, Color.rgb(35, 60, 85))
            window.renderer.text("Ready 仓颉", 10.0, 10.0, Color.rgb(255, 255, 255))
            window.renderer.endScene()
            window.renderer.present()
            @Expect(window.windowFlags().hidden)
            window.show()
            @Expect(!window.windowFlags().hidden)
            window.hide()
            window.renderer.beginScene(160.0, 100.0, Color.rgb(35, 60, 85))
            window.renderer.endScene()
            window.renderer.present()
            @Expect(window.windowFlags().hidden)
        }
    }
}

@Test
func windowDefaultVisibilityRemainsCompatible(): Unit {
    try (window = SdlWindow(WindowSpec("Default visible", 160, 100, vsync: false))) {
        @Expect(!window.windowFlags().hidden)
    }
}
