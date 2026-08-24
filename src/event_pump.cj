package sdl

import std.collection.ArrayList

/**
 * Process-level SDL event pump for applications with more than one window.
 *
 * SDL owns one event queue per process, not one queue per window. Register each live `SdlWindow`
 * here and consume the queue from this single owner; the pump uses `UiEventMetadata.windowId` to
 * apply the target window's coordinate scale and renderer-reset handling. Per-window polling stays
 * available for compact single-window programs.
 */
public class SdlEventPump {
    private let windows = ArrayList<SdlWindow>()

    public init(windows!: Array<SdlWindow> = []) {
        for (window in windows) {
            register(window)
        }
    }

    /** Registers a live window once. Duplicate registrations are ignored. */
    public func register(window: SdlWindow): Unit {
        for (existing in windows) {
            if (existing.id == window.id) {
                return
            }
        }
        windows.add(window)
    }

    /** Removes a window from target-specific event adaptation; safe to call more than once. */
    public func unregister(window: SdlWindow): Unit {
        var index: Int64 = 0
        while (index < windows.size) {
            if (windows[index].id == window.id) {
                windows.remove(at: index)
                return
            }
            index++
        }
    }

    /** Non-blocking dequeue from SDL's process event queue. */
    public func poll(): ?UiEventRecord {
        var raw = SdlEvent()
        if (!unsafe { SDL_PollEvent(inout raw) }) {
            return None
        }
        Some(adapt(decodePumpEventRecord(raw)))
    }

    /** Waits for one process event, returning `None` on timeout. */
    public func waitTimeout(timeoutMs: Int32): ?UiEventRecord {
        var raw = SdlEvent()
        if (!unsafe { SDL_WaitEventTimeout(inout raw, timeoutMs) }) {
            return None
        }
        Some(adapt(decodePumpEventRecord(raw)))
    }

    private func adapt(record: UiEventRecord): UiEventRecord {
        if (record.metadata.windowId == UInt32(0)) {
            return record
        }
        for (window in windows) {
            if (window.id == record.metadata.windowId && !window.isClosed()) {
                return window.adaptEventRecord(record)
            }
        }
        record
    }
}

private func decodePumpEventRecord(raw: SdlEvent): UiEventRecord {
    let rawPtr = unsafe { LibC.malloc<SdlEvent>() }
    var decoded = UiEventRecord(UiEvent.Unknown(UInt32(0)))
    try (rawResource = rawPtr.asResource()) {
        unsafe { rawResource.value.write(raw) }
        let common = unsafe { CPointer<SdlCommonEvent>(rawResource.value).read() }
        if (common.eventType == WindowWakeEventRegistry.eventType()) {
            let user = unsafe { CPointer<SdlUserEvent>(rawResource.value).read() }
            decoded = UiEventRecord(UiEvent.Wake, UiEventMetadata(timestampNs: user.timestamp, windowId: user.windowID))
        } else {
            decoded = decodeEventRecord(raw)
        }
    }
    decoded
}
