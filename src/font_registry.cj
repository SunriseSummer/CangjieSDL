package sdl

import std.collection.{ArrayList, HashMap}
import sdl.text.{clearNativeFontMetadata, refreshNativePlatformFonts}

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
    private static let registered = HashMap<String, FontFamily>()
    private static var registryRevision: UInt64 = UInt64(0)
    private static var defaultName: ?String = None
    private static var systemCatalog: ?SystemFontCatalog = None
    private static let roleFamilies = HashMap<String, ?FontFamily>()
    private static var extraDirectories: Array<String> = []
    private static var metadataCacheFile: ?String = None
    private static var discardMetadataCache = false
    private static var fallbackSources: Array<FontSource> = []

    private init() {}

    internal static func hasSystemCatalog(): Bool {
        systemCatalog.isSome()
    }

    /** Enables an optional application-owned metadata cache file; None disables persistent caching. */
    public static func setMetadataCache(path: ?String): Unit {
        metadataCacheFile = path
        refreshSystemFonts()
    }

    /** Current metadata cache file; its parent directory must already exist. */
    public static func metadataCache(): ?String {
        metadataCacheFile
    }

    /** Maps `name` to a font-file path (`.ttf`, `.ttc`, or `.otf`). Re-registering a name replaces it. */
    public static func register(name: String, path: String): Unit {
        registerFamily(name, path)
    }

    /** Registers an ordered family chain; SDL_ttf uses fallbacks only for missing glyphs. */
    public static func registerFamily(name: String, primaryPath: String, fallbackPaths!: Array<String> = []): Unit {
        let sources = Array<FontSource>(fallbackPaths.size) {i => FontSource(fallbackPaths[i])}
        registerFamily(name, FontFamily(FontSource(primaryPath), fallbacks: sources))
    }

    /** Registers explicit real style faces, collection indices, fallbacks and synthesis policy. */
    public static func registerFamily(name: String, family: FontFamily): Unit {
        clearNativeFontMetadata()
        registered[name] = family
        bumpRevision()
    }

    /** Registered immutable family definition; `None` means no explicit application registration. */
    public static func familyFor(name: String): ?FontFamily {
        registered.get(name)
    }

    /** Replaces application font search roots and schedules a metadata refresh. */
    public static func setSearchDirectories(directories: Array<String>): Unit {
        extraDirectories = directories.clone()
        refreshSystemFonts()
    }

    /** Independent copy of application font discovery roots. */
    public static func searchDirectories(): Array<String> {
        extraDirectories.clone()
    }

    /** Names discoverable in standard system/user font directories; scans lazily and caches metadata. */
    public static func systemFamilyNames(): Array<String> {
        installedCatalog().names()
    }

    /** All discovered file/collection faces; useful for font pickers and explicit face registration. */
    public static func systemFonts(): Array<InstalledFontFace> {
        installedCatalog().faces()
    }

    /** Unreadable font files/directories or discovery limits from the last catalog scan. */
    public static func systemFontWarnings(): Array<String> {
        installedCatalog().warnings()
    }

    /** Registers an alias for an installed family; returns false without changing the registry on a miss. */
    public static func registerSystem(name: String, familyName: String): Bool {
        match (resolveFamily(familyName)) {
            case Some(family) =>
                registerFamily(name, family)
                true
            case None => false
        }
    }

    /** Rescans lazily after fonts are installed/removed, and invalidates renderer font caches. */
    public static func refreshSystemFonts(force!: Bool = false): Unit {
        clearNativeFontMetadata()
        refreshNativePlatformFonts()
        systemCatalog = None
        roleFamilies.clear()
        discardMetadataCache = discardMetadataCache || force
        bumpRevision()
    }

    internal static func resolveFamily(name: String): ?FontFamily {
        match (registered.get(name)) {
            case Some(value) => Some(value)
            case None =>
                let key = name.toAsciiLower()
                if (let Some(value) <- roleFamilies.get(key)) {
                    return value
                }
                if (let Some(catalog) <- systemCatalog) {
                    if (let Some(value) <- catalog.find(name)) {
                        return Some(value)
                    }
                }
                var resolved = resolvePlatformFontRole(key)
                if (resolved.isNone()) {
                    resolved = resolvePlatformFontName(name)
                }
                if (roleFamilies.size >= 512) {
                    roleFamilies.clear()
                }
                roleFamilies[key] = resolved
                resolved
        }
    }

    private static func installedCatalog(): SystemFontCatalog {
        match (systemCatalog) {
            case Some(value) => value
            case None =>
                let value = SystemFontCatalog(refreshMetadata: discardMetadataCache)
                discardMetadataCache = false
                systemCatalog = Some(value)
                value
        }
    }

    /** The path registered for `name`, or `None` if the name is unknown. */
    public static func pathFor(name: String): ?String {
        match (registered.get(name)) {
            case Some(registration) => Some(registration.regular.path)
            case None => None
        }
    }

    /** Ordered fallback paths registered for `name`; returns an independent array. */
    public static func fallbackPathsFor(name: String): Array<String> {
        match (registered.get(name)) {
            case Some(registration) =>
                let sources = registration.fallbacks()
                Array<String>(sources.size) {i => sources[i].path}
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
        clearNativeFontMetadata()
        registered.clear()
        defaultName = None
        fallbackSources = []
        extraDirectories = []
        metadataCacheFile = None
        systemCatalog = None
        roleFamilies.clear()
        bumpRevision()
    }

    /** Configures application fallback files, also usable to bootstrap a renderer without system fonts. */
    public static func setFallbacks(sources: Array<FontSource>): Unit {
        fallbackSources = sources.clone()
        bumpRevision()
    }

    /** Independent copy of the configured application fallback sources. */
    public static func fallbacks(): Array<FontSource> {
        fallbackSources.clone()
    }

    internal static func configuredBootstrapSources(): Array<FontSource> {
        let sources = ArrayList<FontSource>()
        if (let Some(name) <- defaultName) {
            if (let Some(family) <- resolveFamily(name)) {
                sources.add(family.regular)
                for (source in family.fallbacks()) {
                    sources.add(source)
                }
            }
        }
        sources.toArray()
    }

    /** Sets the application default family; `None` restores the platform UI font. */
    public static func setDefault(name: ?String): Unit {
        defaultName = name
        bumpRevision()
    }

    /** Application default selector, used when no renderer scope or explicit font overrides it. */
    public static func defaultFamily(): ?String {
        defaultName
    }

    /** Retries failed loads and reopens registered files on next use; existing sessions remain stable. */
    public static func reload(): Unit {
        refreshSystemFonts(force: true)
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
