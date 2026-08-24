package sdl

import std.collection.{ArrayList, HashMap}

private struct FontRegistration {
    let primaryPath: String
    let fallbackPaths: Array<String>

    init(primaryPath: String, fallbackPaths: Array<String>) {
        this.primaryPath = primaryPath
        this.fallbackPaths = fallbackPaths
    }
}

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
    private static let registered = HashMap<String, FontRegistration>()
    private static var registryRevision: UInt64 = UInt64(0)

    private init() {}

    /** Maps `name` to a font-file path (`.ttf`, `.ttc`, or `.otf`). Re-registering a name replaces it. */
    public static func register(name: String, path: String): Unit {
        registerFamily(name, path)
    }

    /** Registers an ordered family chain; SDL_ttf uses fallbacks only for missing glyphs. */
    public static func registerFamily(name: String, primaryPath: String, fallbackPaths!: Array<String> = []): Unit {
        registered[name] = FontRegistration(primaryPath, fallbackPaths.clone())
        bumpRevision()
    }

    /** The path registered for `name`, or `None` if the name is unknown. */
    public static func pathFor(name: String): ?String {
        match (registered.get(name)) {
            case Some(registration) => Some(registration.primaryPath)
            case None => None
        }
    }

    /** Ordered fallback paths registered for `name`; returns an independent array. */
    public static func fallbackPathsFor(name: String): Array<String> {
        match (registered.get(name)) {
            case Some(registration) => registration.fallbackPaths.clone()
            case None => []
        }
    }

    /** Whether `name` has a registered path. */
    public static func isRegistered(name: String): Bool {
        registered.contains(name)
    }

    /** Removes `name` from the registry; a no-op if it was never registered. */
    public static func unregister(name: String): Unit {
        let _ = registered.remove(name) // cjcheck-ignore: ignore-result # removal is idempotent here; a miss means nothing to evict
        bumpRevision()
    }

    /** Clears every registration. Chiefly for test isolation. */
    public static func clear(): Unit {
        registered.clear()
        bumpRevision()
    }

    /** Monotonic generation for invalidating text-layout caches after registry changes. */
    public static func revision(): UInt64 {
        registryRevision
    }

    /** The registered names, in no particular order. */
    public static func names(): Array<String> {
        let out = ArrayList<String>()
        for ((name, _) in registered) {
            out.add(name)
        }
        out.toArray()
    }

    private static func bumpRevision(): Unit {
        registryRevision = if (registryRevision == UInt64.Max) {
            UInt64(0)
        } else {
            registryRevision + 1
        }
    }
}
