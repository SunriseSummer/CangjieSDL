package sdl

private func windowAccessProbes(window: SdlWindow): Array<() -> Unit> {
    [{=> window.setTitle("test")}, {=> let _ = window.title()}, {=> window.setSize(160, 100)},
     {=> window.show()}, {=> window.hide()}, {=> let _ = window.position()},
     {=> let _ = window.windowFlags()}, {=> let _ = window.pollEvent()},
     {=> let _ = window.waitEventTimeout(0)}, {=> window.setMinimumSize(80, 60)}]
}

@Test
func closedWindowRejectsNativeAccessAndCannotWakeANewerWindow(): Unit {
    let closed = SdlWindow(WindowSpec("Closed", 160, 100), hidden: true)
    closed.close()
    closed.close()
    for (probe in windowAccessProbes(closed)) {
        var rejected = false
        try { probe() } catch (_: IllegalStateException) { rejected = true }
        @Expect(rejected)
    }
    try (next = SdlWindow(WindowSpec("New window", 160, 100), hidden: true)) {
        @Expect(!closed.wake())
        @Expect(next.wake())
    }
}

@Test
func windowRejectsWorkerNativeCallsBeforeEnteringSdl(): Unit {
    try (window = SdlWindow(WindowSpec("Window affinity", 160, 100), hidden: true)) {
        let worker = spawn {=>
            var rejected = 0
            for (probe in windowAccessProbes(window)) {
                try { probe() } catch (_: IllegalStateException) { rejected += 1 }
            }
            rejected == 10
        }
        var result = worker.tryGet()
        let deadline = window.ticks() + UInt64(1000)
        while (result.isNone() && window.ticks() < deadline) {
            let _ = window.waitEventTimeout(10)
            result = worker.tryGet()
        }
        @Expect(result.getOrDefault({=> false}))
    }
}
