package sdl

// SDL subsystem init is ref-counted; window teardown must quit its own reference only.
// A full SDL_Quit() on the first close used to destroy every remaining window and renderer.
@Test
func closingOneWindowKeepsAnotherAlive(): Unit {
    let first = SdlWindow(WindowSpec("Lifecycle first", 160, 120))
    let second = SdlWindow(WindowSpec("Lifecycle second", 160, 120))
    try {
        first.close()
        // The surviving window's renderer must still drive a full frame.
        second.renderer.beginScene(160.0, 120.0, Color.rgb(30, 30, 30))
        second.renderer.endScene()
        second.renderer.present()
        @Expect(true) // reached here without a native failure after the sibling closed
    } finally {
        first.close()
        second.close()
    }
}
