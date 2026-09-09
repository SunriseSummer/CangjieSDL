package sdl

@Test
func runtimeBindingKeepsFutureWaitsOnOneNativeThread(): Unit {
    let bound = unsafe { CJ_BindOSThread() } // cjcheck-ignore: cj-prefix # local is named bound; its initializer calls the exact runtime ABI symbol
    @Expect(bound, Int32(0))
    if (bound != 0) { return }
    try {
        let owner = unsafe { SDL_GetCurrentThreadID() }
        for (_ in 0..1000) {
            let future = spawn {=> true}
            @Expect(future.get())
            @Expect(unsafe { SDL_GetCurrentThreadID() }, owner)
        }
    } finally {
        @Expect(unsafe { CJ_UnbindOSThread() }, Int32(0))
    }
}

@Test
func windowsShareBindingUntilTheLastWindowCloses(): Unit {
    let first = SdlWindow(WindowSpec("Binding first", 160, 100), hidden: true)
    let second = SdlWindow(WindowSpec("Binding second", 160, 100), hidden: true)
    let owner = unsafe { SDL_GetCurrentThreadID() }
    first.close()
    first.close()
    try {
        for (_ in 0..100) {
            let future = spawn {=> true}
            @Expect(future.get())
            @Expect(unsafe { SDL_GetCurrentThreadID() }, owner)
        }
        second.setTitle("Still owned")
    } finally { second.close() }
    let rebound = unsafe { CJ_BindOSThread() } // cjcheck-ignore: cj-prefix # local is named rebound; the runtime ABI symbol cannot be renamed
    @Expect(rebound, Int32(0))
    if (rebound == 0) { @Expect(unsafe { CJ_UnbindOSThread() }, Int32(0)) }
}

@Test
func failedWindowCreationReleasesItsBindingReference(): Unit {
    var failed = false
    try { let _ = SdlWindow(WindowSpec("Invalid scaled size", 2147483647, 100, scale: 2.0), hidden: true) }
    catch (_: IllegalArgumentException) { failed = true }
    @Expect(failed)
    let rebound = unsafe { CJ_BindOSThread() } // cjcheck-ignore: cj-prefix # local is named rebound; the runtime ABI symbol cannot be renamed
    @Expect(rebound, Int32(0))
    if (rebound == 0) { @Expect(unsafe { CJ_UnbindOSThread() }, Int32(0)) }
}

@Test
func failedSecondWindowCreationKeepsTheFirstWindowBound(): Unit {
    let window = SdlWindow(WindowSpec("Surviving window", 160, 100), hidden: true)
    let owner = unsafe { SDL_GetCurrentThreadID() }
    try {
        var failed = false
        try { let _ = SdlWindow(WindowSpec("Overflow", 2147483647, 100, scale: 2.0), hidden: true) }
        catch (_: IllegalArgumentException) { failed = true }
        @Expect(failed)
        for (_ in 0..100) {
            let future = spawn {=> true}
            @Expect(future.get())
            @Expect(unsafe { SDL_GetCurrentThreadID() }, owner)
        }
        window.setTitle("Usable after failed sibling")
    } finally { window.close() }
}
