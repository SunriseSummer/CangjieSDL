package sdl.text

import std.collection.{ArrayList, HashMap, HashSet}
import std.sync.{Mutex, AtomicUInt64}

private let SFNT_FACE_MASK: Int64 = 65535
private let FVAR_HEADER_BYTES: Int64 = 16
private let SFNT_TYPOGRAPHIC_FAMILY_ID: Int64 = 16
private let SFNT_INSTANCE_SHIFT: Int64 = 16
private let FVAR_VERSION_ONE: UInt32 = 0x00010000
private let SFNT_WORD_BYTES: Int64 = 4
private let FVAR_AXIS_COUNT_FIELD: Int64 = 8
private let FVAR_AXIS_SIZE_FIELD: Int64 = 10
private let FVAR_INSTANCE_COUNT_FIELD: Int64 = 12
private let FVAR_INSTANCE_SIZE_FIELD: Int64 = 14
private let FVAR_AXIS_RECORD_BYTES: Int64 = 20
private let FVAR_MAX_AXES: Int64 = 64
private let FVAR_MAX_INSTANCES: Int64 = 4096
private let SFNT_MAX_WEIGHT: Int64 = 1000
private let SFNT_BOLD_THRESHOLD: Int64 = 600
private let SFNT_METADATA_BUDGET: Int64 = FVAR_AXIS_COUNT_FIELD * 1024 * 1024
private let SFNT_METADATA_ENTRIES: Int64 = 512
private let SFNT_INSTANCE_COORDINATE_LIMIT: Int64 = 16384

private struct SfntIdentity {
    let family: String
    let style: String
    let weight: Int64
    let width: Int64
    let italic: Bool
    init(family: String, style: String, weight: Int64, width: Int64, italic: Bool) {
        this.family = family
        this.style = style
        this.weight = weight
        this.width = width
        this.italic = italic
    }
}

internal class SfntFace {
    let version: UInt32
    let tables: Array<SfntTable>
    let names: Array<UInt8>
    let variations: Array<UInt8>
    let head: Array<UInt8>
    let members: Array<NativeInstalledFont>
    let aliases: Array<String>
    let glyphCount: Int64

    init(reader: SfntReader, path: String, index: Int64, offset: Int64) {
        let (version, tables) = reader.tables(offset)
        this.version = version
        this.tables = tables
        this.names = reader.table(tables, "name")
        this.variations = reader.table(tables, "fvar")
        this.head = reader.table(tables, "head")
        this.glyphCount = sfntU16(reader.table(tables, "maxp"), SFNT_WORD_BYTES)
        let names = SfntNames(this.names)
        this.aliases = names.aliases.toArray()
        let os2 = reader.table(tables, "OS/2")
        let weight = if (os2.size >= FVAR_AXIS_COUNT_FIELD) {
            max(1, min(SFNT_MAX_WEIGHT, sfntU16(os2, SFNT_WORD_BYTES)))
        } else {
            Int64(400)
        }
        let width = if (os2.size >= FVAR_AXIS_COUNT_FIELD) {
            max(1, min(9, sfntU16(os2, 6)))
        } else {
            Int64(5)
        }
        let selection = if (os2.size >= FVAR_MAX_AXES) {
            sfntU16(os2, 62)
        } else {
            Int64(0)
        }
        let macStyle = if (head.size >= 46) {
            sfntU16(head, 44)
        } else {
            Int64(0)
        }
        let italic = (selection & 0x201) != 0 || (macStyle & 2) != 0
        let family = names.get(SFNT_TYPOGRAPHIC_FAMILY_ID, fallback: names.get(1))
        let style = names.get(17, fallback: names.get(2, fallback: "Regular"))
        this.members = sfntMembers(path, index, SfntIdentity(family, style, weight, width, italic), names, variations)
    }
}

private class SfntFileIdentities {
    static let next = AtomicUInt64(1)
}

internal class SfntFile {
    let identity: UInt64
    let faces: Array<SfntFace>
    let byteCost: Int64
    init(path: String) {
        let reader = SfntReader(path)
        let parsed = ArrayList<SfntFace>()
        var cost: Int64 = 256 + path.size
        try {
            let offsets = reader.offsets()
            for (i in 0..offsets.size) {
                let face = SfntFace(reader, path, i, offsets[i])
                cost += face.names.size + face.variations.size + face.head.size + face.tables.size * FVAR_MAX_AXES
                for (member in face.members) {
                    cost += 256 + member.familyName.size + member.styleName.size + member.coordinates.size * 48
                }
                for (alias in face.aliases) {
                    cost += alias.size + 32
                }
                if (cost > SFNT_METADATA_BUDGET) {
                    throw NativeTextException("Font metadata exceeds the 8 MiB file budget")
                }
                parsed.add(face)
            }
        } finally {
            reader.file.close()
        }
        this.faces = parsed.toArray()
        this.byteCost = cost
        this.identity = SfntFileIdentities.next.fetchAdd(1)
    }
}

// UI registries explicitly invalidate this bounded cache on reload/refresh. Negative file probes
// are cached too: an absent BoldItalic companion must not cause filesystem I/O every frame.
private class SfntCache {
    static let lock = Mutex()
    static let entries = HashMap<String, SfntFile>()
    static let failures = HashMap<String, String>()
    static var bytes: Int64 = 0
}

protected func clearNativeFontMetadata(): Unit {
    synchronized(SfntCache.lock) {
        SfntCache.entries.clear();
        SfntCache.failures.clear();
        SfntCache.bytes = 0
    }
}

internal func forgetNativeFontMetadata(path: String): Unit {
    synchronized(SfntCache.lock) {
        if (let Some(value) <- SfntCache.entries.remove(path)) {
            SfntCache.bytes -= value.byteCost
        }
        let _ = SfntCache.failures.remove(path) // cjcheck-ignore: ignore-result # invalidation is idempotent; an absent failure needs no action
    }
}

internal func sfntFile(path: String): SfntFile {
    synchronized(SfntCache.lock) {
        if (let Some(value) <- SfntCache.entries.get(path)) {
            return value
        }
        if (let Some(message) <- SfntCache.failures.get(path)) {
            throw NativeTextException(message)
        }
        var parsed: ?SfntFile = None
        try {
            parsed = Some(SfntFile(path))
        } catch (error: Exception) {
            if (SfntCache.failures.size >= SFNT_METADATA_ENTRIES) {
                SfntCache.failures.clear()
            }
            SfntCache.failures[path] = error.message
            throw NativeTextException(error.message)
        }
        // Invariant: parse either assigned Some above or rethrew its failure.
        let value = parsed.getOrThrow()
        let budget = SFNT_METADATA_BUDGET
        if (value.byteCost <= budget) {
            if (SfntCache.bytes + value.byteCost > budget || SfntCache.entries.size >= SFNT_METADATA_ENTRIES) {
                SfntCache.entries.clear();
                SfntCache.bytes = 0
            }
            SfntCache.entries[path] = value
            SfntCache.bytes += value.byteCost
        }
        value
    }
}

internal func inspectNativeFontFile(path: String): Array<NativeInstalledFont> {
    let output = ArrayList<NativeInstalledFont>()
    for (face in sfntFile(path).faces) {
        for (member in face.members) {
            output.add(member)
        }
    }
    output.toArray()
}

protected func nativeFontFileAliases(path: String, index: Int64): Array<String> {
    let faces = sfntFile(path).faces
    if (index < 0 || index >= faces.size) {
        return []
    }
    faces[index].aliases.clone()
}

internal func sfntSourceInfo(source: NativeFontSource): NativeInstalledFont {
    let faces = sfntFile(source.path).faces
    let index = source.faceIndex & SFNT_FACE_MASK
    let instance = source.faceIndex >> SFNT_INSTANCE_SHIFT
    if (index < 0 || index >= faces.size || instance < 0 || instance >= faces[index].members.size) {
        throw NativeTextException("Font face or named instance is out of bounds")
    }
    let member = faces[index].members[instance]
    let coordinates = member.coordinates.clone()
    let seen = HashSet<String>()
    for (request in source.coordinates) {
        var found = false
        for (i in 0..member.axes.size) {
            let axis = member.axes[i]
            if (axis.tagCode != request.tagCode) {
                continue
            }
            if (request.value.isNaN() || request.value.isInf() || request.value < axis.minimum || request.value > axis
                .maximum || seen.contains(request.tag)) {
                throw IllegalArgumentException("Invalid or duplicate font axis: ${request.tag}")
            }
            seen.add(request.tag);
            found = true
            coordinates[i] = request
        }
        if (!found) {
            throw IllegalArgumentException("Unknown font axis: ${request.tag}")
        }
    }
    sfntMember(source,
        SfntIdentity(member.familyName, member.styleName, member.weight, member.width, (member.styleFlags & 2) != 0),
        member.axes, coordinates)
}

private func sfntMembers(path: String, index: Int64, identity: SfntIdentity, names: SfntNames, fvar: Array<UInt8>): Array<NativeInstalledFont> {
    if (fvar.isEmpty()) {
        return [sfntMember(NativeFontSource(path, index), identity, [], [])]
    }
    if (sfntU32(fvar, 0) != FVAR_VERSION_ONE) {
        throw NativeTextException("Unsupported fvar version")
    }
    let offset = sfntU16(fvar, SFNT_WORD_BYTES)
    let count = sfntU16(fvar, FVAR_AXIS_COUNT_FIELD)
    let size = sfntU16(fvar, FVAR_AXIS_SIZE_FIELD)
    let instances = sfntU16(fvar, FVAR_INSTANCE_COUNT_FIELD)
    let instanceSize = sfntU16(fvar, FVAR_INSTANCE_SIZE_FIELD)
    if (offset < FVAR_HEADER_BYTES || count < 1 || count > FVAR_MAX_AXES || size < FVAR_AXIS_RECORD_BYTES || instances >
        FVAR_MAX_INSTANCES || count * instances > SFNT_INSTANCE_COORDINATE_LIMIT || (instanceSize != SFNT_WORD_BYTES +
        count * SFNT_WORD_BYTES && instanceSize != 6 + count * SFNT_WORD_BYTES)) {
        throw NativeTextException("Invalid fvar axes or instance layout")
    }
    sfntRange(fvar.size, offset, count * size + instances * instanceSize)
    let axes = sfntAxes(fvar, offset, count, size)
    let defaults = Array<NativeFontCoordinate>(count) {i => NativeFontCoordinate(axes[i].tag, axes[i].defaultValue)}
    let output = ArrayList<NativeInstalledFont>([sfntMember(NativeFontSource(path, index), identity, axes, defaults)])
    for (instance in 0..instances) {
        let instanceStart = offset + count * size + instance * instanceSize
        let coordinates = Array<NativeFontCoordinate>(count) {
            axisIndex =>
                let value = sfntFixed(fvar, instanceStart + SFNT_WORD_BYTES + axisIndex * SFNT_WORD_BYTES)
                if (value < axes[axisIndex].minimum || value > axes[axisIndex].maximum) {
                    throw NativeTextException("Invalid fvar instance coordinate")
                }
                NativeFontCoordinate(axes[axisIndex].tag, value)
        }
        let member = SfntIdentity(identity.family, names.get(sfntU16(fvar, instanceStart), fallback: identity.style),
            identity.weight, identity.width, identity.italic)
        output.add(
            sfntMember(NativeFontSource(path, index | ((instance + 1) << SFNT_INSTANCE_SHIFT)), member, axes,
                coordinates))
    }
    output.toArray()
}

private func sfntMember(source: NativeFontSource, identity: SfntIdentity, axes: Array<NativeFontAxis>,
    coordinates: Array<NativeFontCoordinate>): NativeInstalledFont {
    var actualWeight = identity.weight
    var slanted = identity.italic
    for (coordinate in coordinates) {
        if (coordinate.tagCode == AXIS_WEIGHT) {
            actualWeight = max(1, min(SFNT_MAX_WEIGHT, Int64(coordinate.value + 0.5)))
        }
        if (coordinate.tagCode == AXIS_ITALIC || coordinate.tagCode == AXIS_SLANT) {
            slanted = slanted || coordinate.value != 0.0
        }
    }
    let flags = (if (actualWeight >= SFNT_BOLD_THRESHOLD) {
        Int32(1)
    } else {
        Int32(0)
    }) | (if (slanted) {
        Int32(2)
    } else {
        Int32(0)
    })
    NativeInstalledFont(source, identity.family, identity.style, flags, weight: actualWeight, width: identity.width,
        axes: axes, coordinates: coordinates)
}

private func sfntAxes(fvar: Array<UInt8>, offset: Int64, count: Int64, size: Int64): Array<NativeFontAxis> {
    let seen = HashSet<String>()
    Array<NativeFontAxis>(count) {
        i =>
            let start = offset + i * size
            let tag = sfntTag(fvar, start)
            let minimum = sfntFixed(fvar, start + SFNT_WORD_BYTES)
            let normal = sfntFixed(fvar, start + FVAR_AXIS_COUNT_FIELD)
            let maximum = sfntFixed(fvar, start + FVAR_INSTANCE_COUNT_FIELD)
            if (minimum > normal || normal > maximum || seen.contains(tag)) {
                throw NativeTextException("Invalid or duplicate fvar axis")
            }
            seen.add(tag)
            NativeFontAxis(tag, minimum, normal, maximum)
    }
}
