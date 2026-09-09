package sdl.text

import std.collection.{ArrayList, HashMap}
import std.convert.*
import std.fs.{File, FileInfo, exists}

private let FONT_METADATA_CACHE_LIMIT: Int64 = 16 * 1024 * 1024
private let CACHE_BASE_FIELDS: Int64 = 9
private let CACHE_AXIS_FIELDS: Int64 = 5
private let CACHE_FLAGS_COLUMN: Int64 = 5
private let CACHE_WEIGHT_COLUMN: Int64 = 6
private let CACHE_WIDTH_COLUMN: Int64 = 7
private let CACHE_AXIS_COUNT_COLUMN: Int64 = 8
private let CACHE_STYLE_FLAGS_MASK: Int32 = 0x0F

// Optional application-owned cache. Source files are still discovered and statted on each refresh;
// only SFNT metadata parsing is skipped. Corruption affects performance, never rendering.
internal class NativeFontMetadataCache {
    private let path: ?String
    private let warnings: ArrayList<String>
    private let saved = HashMap<String, ArrayList<NativeInstalledFont>>()
    private let fingerprints = HashMap<String, String>()
    private let observed = HashMap<String, String>()

    init(path: ?String, warnings: ArrayList<String>, refresh!: Bool = false) {
        this.path = path
        this.warnings = warnings
        if (refresh) {
            return
        }
        if (let Some(file) <- path) {
            try {
                if (exists(file) && FileInfo(file).size <= FONT_METADATA_CACHE_LIMIT) {
                    readCache(String.fromUtf8(File.readFrom(file)))
                }
            } catch (error: Exception) {
                saved.clear();
                fingerprints.clear()
                warnings.add("Font metadata cache ignored: ${error.message}")
            }
        }
    }

    func find(file: String): ?Array<NativeInstalledFont> {
        if (path.isNone()) {
            return None
        }
        try {
            let stamp = fingerprint(file)
            observed[file] = stamp
            if (fingerprints.get(file) == Some(stamp)) {
                if (let Some(faces) <- saved.get(file)) {
                    return faces.toArray()
                }
            }
        } catch (error: Exception) {
            warnings.add("Font metadata fingerprint failed: ${error.message}")
        }
        None
    }

    func save(faces: Array<NativeInstalledFont>): Unit {
        if (let Some(file) <- path) {
            try {
                let text = StringBuilder()
                text.append(cacheHeader() + "\n")
                for (face in faces) {
                    let stamp = fingerprint(face.source.path)
                    if (observed.get(face.source.path) != Some(stamp)) {
                        continue
                    }
                    text.append(encodeFace(face, stamp) + "\n")
                }
                text.append("END\n")
                let data = text.toString().toArray()
                if (data.size <= FONT_METADATA_CACHE_LIMIT) {
                    File.writeTo(file, data)
                }
            } catch (error: Exception) {
                warnings.add("Font metadata cache write failed: ${error.message}")
            }
        }
    }

    private func readCache(text: String): Unit {
        let lines = text.split("\n")
        if (lines.size < 3 || lines[0] != cacheHeader() || lines[lines.size - 2] != "END") {
            return
        }
        for (i in 1..lines.size - 2) {
            let fields = lines[i].split("\t")
            let face = decodeFace(fields)
            fingerprints[face.source.path] = unescapeField(fields[1])
            match (saved.get(face.source.path)) {
                case Some(group) => group.add(face)
                case None => saved[face.source.path] = ArrayList<NativeInstalledFont>([face])
            }
        }
    }
}

private func fingerprint(file: String): String {
    let info = FileInfo(file)
    "${info.size}:${info.lastModificationTime}"
}

private func cacheHeader(): String {
    "CangjieSDL-font-catalog-2"
}

private func escapeField(value: String): String {
    value.replace("%", "%25").replace("\t", "%09").replace("\r", "%0D").replace("\n", "%0A")
}

private func unescapeField(value: String): String {
    value.replace("%09", "\t").replace("%0D", "\r").replace("%0A", "\n").replace("%25", "%")
}

private func encodeFace(face: NativeInstalledFont, stamp: String): String {
    let result = StringBuilder()
    result.append("${escapeField(face.source.path)}\t${escapeField(stamp)}\t${face.source.faceIndex}\t")
    result.append(
        "${escapeField(face.familyName)}\t${escapeField(face.styleName)}\t${face.styleFlags}\t${face.weight}\t${face.width}\t${face.axes.size}")
    for (i in 0..face.axes.size) {
        let axis = face.axes[i]
        let coordinate = face.coordinates[i].value
        result.append(
            "\t${escapeField(axis.tag)}\t${axis.minimum.toBits()}\t${axis.defaultValue.toBits()}\t${axis.maximum.toBits()}\t${coordinate.toBits()}")
    }
    result.toString()
}

private func decodeFace(fields: Array<String>): NativeInstalledFont {
    if (fields.size < CACHE_BASE_FIELDS) {
        throw IllegalArgumentException("Truncated font cache row")
    }
    let index = Int64.parse(fields[2])
    let flags = Int32.parse(fields[CACHE_FLAGS_COLUMN])
    let weight = Int64.parse(fields[CACHE_WEIGHT_COLUMN])
    let width = Int64.parse(fields[CACHE_WIDTH_COLUMN])
    let count = Int64.parse(fields[CACHE_AXIS_COUNT_COLUMN])
    if (index < 0 || index > Int64(Int32.Max) || weight < 1 || weight > 1000 || width < 1 || width > 9 || flags < 0 ||
        flags > CACHE_STYLE_FLAGS_MASK || count < 0 || count > 64 || fields.size != CACHE_BASE_FIELDS + count *
        CACHE_AXIS_FIELDS) {
        throw IllegalArgumentException("Invalid font cache metadata")
    }
    let axes = ArrayList<NativeFontAxis>()
    let coordinates = ArrayList<NativeFontCoordinate>()
    for (i in 0..count) {
        let offset = CACHE_BASE_FIELDS + i * CACHE_AXIS_FIELDS
        let tag = unescapeField(fields[offset])
        let minimum = Float32.fromBits(UInt32.parse(fields[offset + 1]))
        let normal = Float32.fromBits(UInt32.parse(fields[offset + 2]))
        let maximum = Float32.fromBits(UInt32.parse(fields[offset + 3]))
        let value = Float32.fromBits(UInt32.parse(fields[offset + 4]))
        if (tag.size != 4 || !validCoordinate(minimum) || !validCoordinate(normal) || !validCoordinate(maximum) ||
            !validCoordinate(value) || minimum > normal || normal > maximum || value < minimum || value > maximum) {
            throw IllegalArgumentException("Invalid font cache coordinates")
        }
        axes.add(NativeFontAxis(tag, minimum, normal, maximum))
        coordinates.add(NativeFontCoordinate(tag, value))
    }
    NativeInstalledFont(NativeFontSource(unescapeField(fields[0]), index), unescapeField(fields[3]),
        unescapeField(fields[4]), flags, weight: weight, width: width, axes: axes.toArray(),
        coordinates: coordinates.toArray())
}

private func validCoordinate(value: Float32): Bool {
    !value.isNaN() && !value.isInf()
}
