package sdl.text

import std.collection.HashMap
import std.sync.Mutex

// System libraries are loaded once. Function lookup is cached; no per-frame dlopen/dlsym work.
internal class FontPlatformLibrary {
    private let handle: CPointer<Unit>
    private let functions = HashMap<String, CPointer<Unit>>()
    private let lock = Mutex()
    init(paths: Array<String>) {
        var loaded = CPointer<Unit>()
        for (path in paths) {
            let value = unsafe { LibC.mallocCString(path) }
            try (resource = value.asResource()) {
                loaded = unsafe { SDL_LoadObject(resource.value) }
            }
            if (loaded.isNotNull()) {
                break
            }
        }
        this.handle = loaded
    }
    func symbol(name: String): CPointer<Unit> {
        synchronized(lock) {
            if (let Some(pointer) <- functions.get(name)) {
                return pointer
            }
            if (handle.isNull()) {
                throw NativeTextException("Font platform service is unavailable")
            }
            let value = unsafe { LibC.mallocCString(name) }
            var pointer = CPointer<Unit>()
            try (resource = value.asResource()) {
                pointer = unsafe { SDL_LoadFunction(handle, resource.value) }
            }
            if (pointer.isNull()) {
                throw NativeTextException("Font platform function is unavailable: ${name}")
            }
            functions[name] = pointer
            pointer
        }
    }
}
