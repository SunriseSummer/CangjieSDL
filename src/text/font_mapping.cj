package sdl.text

import std.collection.HashMap
import std.fs.FileInfo
import std.sync.Mutex

private let FONT_MAPPING_LIMIT: Int64 = 1024 * 1024 * 1024
private let FONT_CHECKSUM_CACHE_ENTRIES: Int64 = 512

// Metadata revisions own different mappings, so a live old session cannot mask a replaced file.
private class FontMappings {
    static let lock = Mutex()
    static let files = HashMap<UInt64, FontFileMapping>()
    // Metadata identities change on reload. Retain only a checksum across mapping lifetimes,
    // so releasing a large calibration font does not rescan its entire file on the next miss.
    static let checksums = HashMap<UInt64, UInt32>()
}

internal func acquireFontMapping(path: String, identity: UInt64): FontFileMapping {
    synchronized(FontMappings.lock) {
        if (let Some(mapping) <- FontMappings.files.get(identity)) {
            mapping.references += 1
            return mapping
        }
        let size = FileInfo(path).size
        if (size <= 0 || size > FONT_MAPPING_LIMIT) {
            throw NativeTextException("Font file exceeds the 1 GiB mapping limit")
        }
        let mapping = FontFileMapping(path, size, knownChecksum: FontMappings.checksums.get(identity))
        if (FontMappings.checksums.size >= FONT_CHECKSUM_CACHE_ENTRIES) {
            FontMappings.checksums.clear()
        }
        FontMappings.checksums[identity] = mapping.checksum
        FontMappings.files[identity] = mapping
        mapping
    }
}

internal func releaseFontMapping(identity: UInt64): Unit {
    synchronized(FontMappings.lock) {
        if (let Some(mapping) <- FontMappings.files.get(identity)) {
            mapping.references -= 1
            if (mapping.references == 0) {
                let _ = FontMappings.files.remove(identity) // cjcheck-ignore: ignore-result # the mapping was found under this lock and has no remaining owners
                mapping.close()
            }
        }
    }
}
