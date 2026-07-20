package sdl

import std.collection.{ArrayList, HashMap}

/**
 * A process-wide registry mapping application font names to font-file paths, in the spirit of a CSS
 * `@font-face` table. Register a name once at startup, then refer to it by name from `Label` (via
 * `fontFamily`) or `Renderer.text`; the renderer opens the file lazily on first use and caches it.
 *
 * Resolution is forgiving: an unregistered name, or a registered path that cannot be opened as a
 * font, falls back to the platform UI font rather than failing. Registration only records the
 * mapping — it does not touch the filesystem — so it is safe to call before any window exists.
 *
 * The registry is global and unsynchronised, matching CUI's single-threaded UI model; register fonts
 * from the main thread before rendering.
 */
public class Fonts {
    private static let registered = HashMap<String, String>()

    private init() {}

    /** Maps `name` to a font-file path (`.ttf`, `.ttc`, or `.otf`). Re-registering a name replaces it. */
    public static func register(name: String, path: String): Unit {
        registered[name] = path
    }

    /** The path registered for `name`, or `None` if the name is unknown. */
    public static func pathFor(name: String): ?String {
        registered.get(name)
    }

    /** Whether `name` has a registered path. */
    public static func isRegistered(name: String): Bool {
        registered.contains(name)
    }

    /** Removes `name` from the registry; a no-op if it was never registered. */
    public static func unregister(name: String): Unit {
        let _ = registered.remove(name)
    }

    /** Clears every registration. Chiefly for test isolation. */
    public static func clear(): Unit {
        registered.clear()
    }

    /** The registered names, in no particular order. */
    public static func names(): Array<String> {
        let out = ArrayList<String>()
        for ((name, _) in registered) {
            out.add(name)
        }
        out.toArray()
    }
}
