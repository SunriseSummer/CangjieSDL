package sdl

import std.collection.HashMap
import std.deriving.*

private let TEXT_RASTER_BUDGET: Int64 = 16 * 1024 * 1024
private let TEXT_RASTER_CAPACITY: Int64 = 256

@Derive[Equatable, Hashable]
// Keep compound string keys in immutable objects instead of copying their fields through
// generic bucket storage. Equality and hashing remain structural, independent of identity.
internal class TextRasterKey {
    let family: String
    let style: Int32
    let sizeBits: UInt32
    let text: String
    let rgb: UInt32

    init(family: String, style: Int32, sizeBits: UInt32, text: String, rgb!: UInt32 = 0xFFFFFF) {
        this.family = family
        this.style = style
        this.sizeBits = sizeBits
        this.text = text
        this.rgb = rgb
    }
}

// An oversized raster belongs to its draw call. Cached rasters belong to the renderer.
internal class TextRaster <: Resource {
    let image: TextRasterImage
    private let transient: Bool
    private var closed: Bool = false

    init(image: TextRasterImage, transient!: Bool = false) {
        this.image = image
        this.transient = transient
    }

    /** Releases transient texture ownership; cached textures remain owned by the renderer. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        if (transient) {
            image.close()
        }
    }

    /** Whether this draw lease has ended. */
    public func isClosed(): Bool {
        closed
    }
}

private class TextRasterEntry {
    let image: TextRasterImage
    let bytes: Int64
    var lastUse: UInt64

    init(image: TextRasterImage, bytes: Int64, lastUse: UInt64) {
        this.image = image
        this.bytes = bytes
        this.lastUse = lastUse
    }
}

// A byte- and count-bounded LRU shared by straight italic and rotated text.
internal class TextRasterCache {
    private let entries = HashMap<TextRasterKey, TextRasterEntry>()
    private var byteCount: Int64 = 0
    private var textureCount: Int64 = 0
    private var clock: UInt64 = UInt64(0)
    private var rasterCount: UInt64 = UInt64(0)

    func get(key: TextRasterKey): ?TextRaster {
        clock += 1
        match (entries.get(key)) {
            case Some(entry) =>
                entry.lastUse = clock
                Some(TextRaster(entry.image))
            case None => None
        }
    }

    func put(key: TextRasterKey, image: TextRasterImage): TextRaster {
        rasterCount += 1
        let bytes = image.bytes
        if (bytes > TEXT_RASTER_BUDGET || image.tiles.size > TEXT_RASTER_CAPACITY) {
            return TextRaster(image, transient: true)
        }
        while (byteCount + bytes > TEXT_RASTER_BUDGET || textureCount + image.tiles.size > TEXT_RASTER_CAPACITY) {
            evictOldest()
        }
        clock += 1
        entries[key] = TextRasterEntry(image, bytes, clock)
        byteCount += bytes
        textureCount += image.tiles.size
        TextRaster(image)
    }

    private func evictOldest(): Unit {
        var oldest: UInt64 = UInt64.Max
        var victim = TextRasterKey("", 0, UInt32(0), "")
        for ((key, entry) in entries) {
            if (entry.lastUse < oldest) {
                oldest = entry.lastUse
                victim = key
            }
        }
        match (entries.remove(victim)) {
            case Some(entry) =>
                byteCount -= entry.bytes
                textureCount -= entry.image.tiles.size
                entry.image.close()
            case None => throw IllegalStateException("Text raster cache has no eviction candidate")
        }
    }

    func clear(): Unit {
        for ((_, entry) in entries) {
            entry.image.close()
        }
        entries.clear()
        byteCount = 0
        textureCount = 0
    }

    func bytes(): Int64 {
        byteCount
    }
    func size(): Int64 {
        textureCount
    }
    func rasterizations(): UInt64 {
        rasterCount
    }
}
