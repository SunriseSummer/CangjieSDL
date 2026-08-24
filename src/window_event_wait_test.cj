package sdl

@Test
func windowWakeInterruptsTimedEventWait(): Unit {
    let window = SdlWindow(WindowSpec("Event wait test", 160, 120, vsync: false, supersample: 1))
    try {
        // Queue from a worker and join it before waiting: no timing sleep, and the Future's
        // completion establishes that SDL_PushEvent finished before the assertion loop.
        let worker = spawn {=> window.wake()}
        @Expect(worker.get())

        var woke = false
        let deadline = window.ticks() + UInt64(1000)
        while (!woke && window.ticks() < deadline) {
            match (window.waitEventTimeout(20)) {
                case Some(UiEvent.Wake) => woke = true
                case _ => () // creation/exposure events may precede the explicit wake
            }
        }
        @Expect(woke)
    } finally {
        window.close()
    }
}

@Test
func windowsShareOneNonZeroWakeEventRegistration(): Unit {
    let first = SdlWindow(WindowSpec("Wake registration first", 120, 80, vsync: false, supersample: 1))
    let second = SdlWindow(WindowSpec("Wake registration second", 120, 80, vsync: false, supersample: 1))
    try {
        @Expect(first.diagnosticWakeEventType() != UInt32(0))
        @Expect(first.diagnosticWakeEventType(), second.diagnosticWakeEventType())
    } finally {
        first.close()
        second.close()
    }
}

@Test
func processEventPumpRoutesWakeToItsWindowId(): Unit {
    let first = SdlWindow(WindowSpec("Event pump first", 120, 80, vsync: false, supersample: 1))
    let second = SdlWindow(WindowSpec("Event pump second", 120, 80, vsync: false, supersample: 1))
    let pump = SdlEventPump(windows: [first, second])
    try {
        @Expect(second.wake())
        var routed = false
        let deadline = first.ticks() + UInt64(1000)
        while (!routed && first.ticks() < deadline) {
            match (pump.waitTimeout(20)) {
                case Some(record) =>
                    match (record.event) {
                        case UiEvent.Wake =>
                            if (record.metadata.windowId == second.id) {
                                routed = true
                            }
                        case _ => ()
                    }
                case None => ()
            }
        }
        @Expect(routed)
    } finally {
        pump.unregister(first)
        pump.unregister(second)
        first.close()
        second.close()
    }
}
