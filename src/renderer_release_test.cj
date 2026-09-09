package sdl

@Test
func rendererResourceReleaseIsIdempotent(): Unit {
    let renderer = Renderer.headless()
    renderer.releaseResources()
    renderer.releaseResources()
    @Expect(!renderer.renderDevice().isActive())
}

@Test
func windowClosesAfterItsRendererResourcesWereReleased(): Unit {
    let window = SdlWindow(WindowSpec("Released renderer teardown", 160, 100), hidden: true)
    window.renderer.releaseResources()
    window.close()
    @Expect(window.isClosed())
    @Expect(!window.wake())
}

@Test
func windowCloseDuringRecordingRejectsBeforeDestroyingItsResources(): Unit {
    let window = SdlWindow(WindowSpec("Recording close guard", 160, 100), hidden: true)
    try {
        var rejected = false
        try { let _ = window.renderer.recordCommands { window.close() } }
        catch (_: IllegalStateException) { rejected = true }
        @Expect(rejected)
        @Expect(!window.isClosed())
        window.setTitle("Recording failure recovered")
    } finally { window.close() }
}
