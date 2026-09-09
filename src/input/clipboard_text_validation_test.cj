package sdl.input

@Test
func clipboardRejectsEmbeddedNulBeforeNativeCalls(): Unit {
    var rejected = false
    try {
        Clipboard.setText("before\u{0000}after")
    } catch (_: IllegalArgumentException) {
        rejected = true
    }
    @Expect(rejected)
}

@Test
func primarySelectionRejectsEmbeddedNulBeforeNativeCalls(): Unit {
    var rejected = false
    try { Clipboard.setPrimarySelectionText("before\u{0000}after") }
    catch (_: IllegalArgumentException) { rejected = true }
    @Expect(rejected)
}
