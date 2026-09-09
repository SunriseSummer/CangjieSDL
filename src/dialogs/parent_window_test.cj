package sdl.dialogs

import sdl.{SdlWindow, WindowSpec}

@Test
func dialogParentRejectsClosedWindowWithoutCallingNativeDialog(): Unit {
    let window = SdlWindow(WindowSpec("Dialog parent guard", 160, 100), hidden: true)
    window.close()
    var rejected = false
    try { let _ = parentWindowPtr(Some(window)) } catch (_: IllegalStateException) { rejected = true }
    @Expect(rejected)
    @Expect(parentWindowPtr(None).isNull())
}
