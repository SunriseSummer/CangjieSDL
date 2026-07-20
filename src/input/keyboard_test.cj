package sdl.input

@Test
func keyModifiersMapSdlMasks(): Unit {
    let modifiers = KeyModifiers(SDL_KMOD_LCTRL | SDL_KMOD_RSHIFT | SDL_KMOD_LALT | SDL_KMOD_CAPS)

    @Expect(modifiers.ctrl)
    @Expect(modifiers.shift)
    @Expect(modifiers.alt)
    @Expect(!modifiers.gui)
    @Expect(modifiers.command)
    @Expect(modifiers.capsLock)
    @Expect(!modifiers.scrollLock)
}

@Test
func keyModifiersTreatGuiAsCommand(): Unit {
    let modifiers = KeyModifiers(SDL_KMOD_RGUI)

    @Expect(modifiers.gui)
    @Expect(modifiers.command)
    @Expect(!modifiers.ctrl)
}
