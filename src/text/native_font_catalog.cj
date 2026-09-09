package sdl.text

import std.collection.{ArrayList, HashSet}
import std.fs.{Directory, FileInfo, FSException, exists, canonicalize}
import std.sort.sort

/** One face discovered through bounded SFNT metadata, rather than its filename. */
protected struct NativeInstalledFont {
    public let source: NativeFontSource
    public let familyName: String
    public let styleName: String
    public let styleFlags: Int32
    public let weight: Int64
    public let width: Int64
    public let axes: Array<NativeFontAxis>
    public let coordinates: Array<NativeFontCoordinate>

    public init(source: NativeFontSource, familyName: String, styleName: String, styleFlags: Int32,
        weight!: Int64 = 400, width!: Int64 = 5, axes!: Array<NativeFontAxis> = [],
        coordinates!: Array<NativeFontCoordinate> = []) {
        this.source = source
        this.familyName = familyName
        this.styleName = styleName
        this.styleFlags = styleFlags
        this.weight = weight
        this.width = width
        this.axes = axes
        this.coordinates = coordinates
    }
}

/** Best-effort metadata catalog and any unreadable files/directories. */
protected struct NativeFontCatalog {
    public let faces: Array<NativeInstalledFont>
    public let warnings: Array<String>
    public let cacheHits: Int64

    public init(faces: Array<NativeInstalledFont>, warnings: Array<String>, cacheHits!: Int64 = 0) {
        this.faces = faces
        this.warnings = warnings
        this.cacheHits = cacheHits
    }
}

private let FONT_SCAN_FILE_LIMIT: Int64 = 4096
private let FONT_SCAN_DEPTH_LIMIT: Int64 = 16

/** Scans supplied roots once; callers cache the result and explicitly refresh after installation. */
protected func discoverNativeFonts(roots: Array<String>, cachePath!: ?String = None, refresh!: Bool = false): NativeFontCatalog {
    let files = ArrayList<String>()
    let seen = HashSet<String>()
    let warnings = ArrayList<String>()
    for (root in roots) {
        collectFontFiles(root, 0, files, seen, warnings)
    }
    let faces = ArrayList<NativeInstalledFont>()
    let cache = NativeFontMetadataCache(cachePath, warnings, refresh: refresh)
    var cacheHits: Int64 = 0
    for (path in files) {
        try {
            if (let Some(cached) <- cache.find(path)) {
                appendFontFaces(faces, cached)
                cacheHits += 1
                continue
            }
            forgetNativeFontMetadata(path)
            for (face in inspectNativeFontFile(path)) {
                faces.add(face)
            }
        } catch (error: NativeTextException) {
            warnings.add("${path}: ${error.message}")
        }
    }
    let result = faces.toArray()
    cache.save(result)
    NativeFontCatalog(result, warnings.toArray(), cacheHits: cacheHits)
}

private func appendFontFaces(target: ArrayList<NativeInstalledFont>, values: Array<NativeInstalledFont>): Unit {
    for (face in values) {
        target.add(face)
    }
}

private func collectFontFiles(path: String, depth: Int64, files: ArrayList<String>, seen: HashSet<String>,
    warnings: ArrayList<String>): Unit {
    if (depth > FONT_SCAN_DEPTH_LIMIT || files.size >= FONT_SCAN_FILE_LIMIT) {
        warnings.add("Font scan limit reached at ${path}")
        return
    }
    try {
        if (!exists(path)) {
            return
        }
        let identity = canonicalFontPath(path)
        if (seen.contains(identity)) {
            return
        }
        seen.add(identity)
        if (!FileInfo(path).isDirectory()) {
            files.add(path);
            return
        }
        let entries = Directory.readFrom(path)
        sort<FileInfo, String>(entries, key: {entry => entry.path.toString()})
        for (entry in entries) {
            if (files.size >= FONT_SCAN_FILE_LIMIT) {
                break
            }
            let child = entry.path.toString()
            if (entry.isDirectory()) {
                collectFontFiles(child, depth + 1, files, seen, warnings)
            } else {
                let lower = child.toAsciiLower()
                if (lower.endsWith(".ttf") || lower.endsWith(".ttc") || lower.endsWith(".otf") || lower.endsWith(".otc")) {
                    collectFontFiles(child, depth + 1, files, seen, warnings)
                }
            }
        }
    } catch (error: FSException) {
        warnings.add("${path}: ${error.message}")
    }
}

@When[os == "Windows"]
private func canonicalFontPath(path: String): String {
    canonicalize(path).toString().toAsciiLower()
}

@When[os != "Windows"]
private func canonicalFontPath(path: String): String {
    canonicalize(path).toString()
}
