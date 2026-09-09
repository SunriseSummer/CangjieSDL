package sdl.text

import std.collection.{HashMap, HashSet}
import std.sync.Mutex

internal class EngineEntry {
    let layout: EngineLayout
    let geometry: EngineGeometry
    init(layout: EngineLayout) {
        this.layout = layout
        this.geometry = EngineGeometry(layout)
    }
}

private class TextEngineRegistry {
    static let lock = Mutex()
    static let engines = HashMap<UIntNative, CangjieTextEngine>()
    static let owners = HashMap<UIntNative, CangjieTextEngine>()
}

// This is a Cangjie drawing context, not an SDL callback vtable. SDL_ttf explicitly supports
// TTF_CreateText(NULL, ...); its public operations can be read after TTF_UpdateText returns.
// Native calls never re-enter Cangjie to create, rebuild or destroy a text layout.
internal class CangjieTextEngine {
    let renderer: CPointer<Unit>
    let atlas: GlyphAtlas
    let sources = HashMap<UIntNative, GlyphRasterSource>()
    let probes = GlyphProbeReleases()
    let texts = HashMap<UIntNative, EngineEntry>()
    let owned = HashSet<UIntNative>()
    let fallbacks = HashMap<UIntNative, Array<CPointer<Unit>>>()
    init(renderer: CPointer<Unit>) {
        this.renderer = renderer
        this.atlas = GlyphAtlas(renderer, sources)
    }
    func forgetText(key: UIntNative): Unit {
        if (let Some(entry) <- texts.remove(key)) {
            entry.geometry.close()
        }
    }
    func close(): Unit {
        if (!owned.isEmpty()) {
            throw IllegalStateException("Text context still owns live layouts")
        }
        probes.flush()
        atlas.close()
        for ((_, source) in sources) {
            source.close()
        }
        sources.clear()
        fallbacks.clear()
    }
}

internal func createNativeTextEngine(renderer: CPointer<Unit>): CPointer<Unit> {
    let pointer = unsafe { LibC.malloc<UInt8>(count: 1) }
    if (pointer.isNull()) {
        return CPointer<Unit>()
    }
    try {
        let state = CangjieTextEngine(renderer)
        synchronized(TextEngineRegistry.lock) {
            TextEngineRegistry.engines[pointer.toUIntNative()] = state
        }
        CPointer<Unit>(pointer)
    } catch (error: Exception) {
        unsafe { LibC.free(pointer) }
        fontCallbackError(error.message)
        CPointer<Unit>()
    }
}

internal func nativeTextEngine(engine: CPointer<Unit>): CangjieTextEngine {
    synchronized(TextEngineRegistry.lock) {
        match (TextEngineRegistry.engines.get(engine.toUIntNative())) {
            case Some(state) => state
            case None => throw IllegalStateException("Text context is closed")
        }
    }
}

internal func destroyNativeTextEngine(engine: CPointer<Unit>): Unit {
    let state = synchronized(TextEngineRegistry.lock) {
        if (let Some(value) <- TextEngineRegistry.engines.get(engine.toUIntNative())) {
            if (!value.owned.isEmpty()) {
                throw IllegalStateException("Text context still owns live layouts")
            }
        }
        TextEngineRegistry.engines.remove(engine.toUIntNative())
    }
    if (let Some(value) <- state) {
        try {
            value.close()
        } finally {
            unsafe { LibC.free(engine) }
        }
    }
}

internal func createNativeText(engine: CPointer<Unit>, font: CPointer<Unit>, text: CString, length: UIntNative): CPointer<Unit> {
    let state = nativeTextEngine(engine)
    let pointer = unsafe { TTF_CreateText(CPointer<Unit>(), font, text, length) }
    if (pointer.isNull()) {
        return pointer
    }
    try {
        synchronized(TextEngineRegistry.lock) {
            TextEngineRegistry.owners[pointer.toUIntNative()] = state
            state.owned.add(pointer.toUIntNative())
        }
        pointer
    } catch (error: Exception) {
        synchronized(TextEngineRegistry.lock) {
            let _ = TextEngineRegistry.owners.remove(pointer.toUIntNative()) // cjcheck-ignore: ignore-result # rollback of a partially registered native allocation
            let _ = state.owned.remove(pointer.toUIntNative()) // cjcheck-ignore: ignore-result # rollback also handles failure before the ownership set was updated
        }
        unsafe { TTF_DestroyText(pointer) }
        throw error
    }
}

internal func destroyNativeText(text: CPointer<Unit>): Unit {
    if (text.isNull()) {
        return
    }
    let key = text.toUIntNative()
    let owner = synchronized(TextEngineRegistry.lock) {
        let found = TextEngineRegistry.owners.remove(key)
        if (let Some(state) <- found) {
            if (!state.owned.remove(key)) {
                throw IllegalStateException("Text ownership is inconsistent")
            }
        }
        found
    }
    match (owner) {
        case Some(state) => try {
            state.forgetText(key)
        } finally {
            unsafe { TTF_DestroyText(text) }
        }
        case None => throw IllegalStateException("Text layout is already closed or is not owned")
    }
}

private func textOwner(text: CPointer<Unit>): CangjieTextEngine {
    synchronized(TextEngineRegistry.lock) {
        match (TextEngineRegistry.owners.get(text.toUIntNative())) {
            case Some(state) => state
            case None => throw IllegalStateException("Text layout is closed")
        }
    }
}

internal func nativeEngineEntry(text: CPointer<Unit>): EngineEntry {
    let state = textOwner(text)
    let key = text.toUIntNative()
    let changed = unsafe { CPointer<EngineText>(text).read().data.read().needsLayout }
    if (changed) {
        state.forgetText(key)
    }
    if (!unsafe { TTF_UpdateText(text) }) {
        throw NativeTextException("Text layout failed: ${lastNativeError()}")
    }
    if (let Some(entry) <- state.texts.get(key)) {
        return entry
    }
    let base = EngineLayout(CPointer<EngineText>(text), state.sources)
    let entry = EngineEntry(prepareEmojiLayout(CPointer<EngineText>(text), base, state))
    state.texts[key] = entry
    entry
}

internal func drawNativeEngineText(text: CPointer<Unit>, x: Float32, y: Float32, color: NativeTextColor): Unit {
    let engine = textOwner(text)
    try {
        let entry = nativeEngineEntry(text)
        entry.geometry.draw(engine.renderer, engine.atlas, x, y, color)
    } finally {
        engine.probes.flush()
    }
}

internal func forgetNativeEngineFont(engine: CPointer<Unit>, font: CPointer<Unit>): Unit {
    if (engine.isNotNull()) {
        let state = nativeTextEngine(engine)
        let _ = state.fallbacks.remove(font.toUIntNative()) // cjcheck-ignore: ignore-result # non-owning fallback lookup has the primary font's lifetime
        state.atlas.forgetFont(font)
        if (let Some(source) <- state.sources.remove(font.toUIntNative())) {
            source.close()
        }
    }
}

internal func registerNativeEngineFont(engine: CPointer<Unit>, font: CPointer<Unit>, source: NativeFontSource,
    size: Float32, synthesis: Int32): Unit {
    let state = nativeTextEngine(engine)
    state.sources[font.toUIntNative()] = GlyphRasterSource(source, size, synthesis, original: font,
        releases: Some(state.probes))
}
