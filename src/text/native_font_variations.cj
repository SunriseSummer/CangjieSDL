package sdl.text

import std.collection.ArrayList

internal let AXIS_WEIGHT: UInt32 = 0x77676874
internal let AXIS_ITALIC: UInt32 = 0x6974616C
internal let AXIS_SLANT: UInt32 = 0x736C6E74

protected struct NativeFontCoordinate {
    public let tag: String
    let tagCode: UInt32
    public let value: Float32
    public init(tag: String, value: Float32) {
        this.tag = tag
        this.tagCode = fontAxisTagCode(tag)
        this.value = value
    }
}

protected struct NativeFontAxis {
    public let tag: String
    let tagCode: UInt32
    public let minimum: Float32
    public let defaultValue: Float32
    public let maximum: Float32
    public init(tag: String, minimum: Float32, defaultValue: Float32, maximum: Float32) {
        this.tag = tag
        this.tagCode = fontAxisTagCode(tag)
        this.minimum = minimum
        this.defaultValue = defaultValue
        this.maximum = maximum
    }
}

internal func requestedVariableSource(selected: NativeInstalledFont, family: NativeFontFamily, italic: Bool): NativeFontSource {
    let coordinates = ArrayList<NativeFontCoordinate>(selected.source.coordinates)
    var pinnedWeight = family.primary.faceIndex >= 65536
    for (coordinate in selected.source.coordinates) {
        if (coordinate.tagCode == AXIS_WEIGHT) {
            pinnedWeight = true
        }
    }
    for (axis in selected.axes) {
        if (axis.tagCode == AXIS_WEIGHT && !pinnedWeight) {
            coordinates.add(NativeFontCoordinate("wght", max(axis.minimum, min(axis.maximum, Float32(family.weight)))))
        }
        if (axis.tagCode == AXIS_ITALIC) {
            coordinates.add(NativeFontCoordinate("ital", max(axis.minimum, min(axis.maximum, if (italic) {
                Float32(1.0)
            } else {
                Float32(0.0)
            }))))
        }
    }
    for (coordinate in family.coordinates) {
        coordinates.add(coordinate)
    }
    // Last assignment wins: source defaults < fontWeight < explicit style coordinates.
    let merged = ArrayList<NativeFontCoordinate>()
    for (i in 0..coordinates.size) {
        var replaced = false
        for (j in i + 1..coordinates.size) {
            if (coordinates[i].tagCode == coordinates[j].tagCode) {
                replaced = true
            }
        }
        if (!replaced) {
            merged.add(coordinates[i])
        }
    }
    NativeFontSource(selected.source.path, selected.source.faceIndex, coordinates: merged.toArray())
}

// Compare the four ASCII bytes without allocating strings or retaining an array-element String
// receiver across collection. This also avoids Cangjie 1.0.5's optimized interior-receiver path.
internal func fontAxisTagCode(tag: String): UInt32 {
    if (tag.size != 4) {
        throw NativeTextException("Font axis tag must contain four ASCII bytes")
    }
    let bytes = tag.toArray()
    var code: UInt32 = 0
    for (value in bytes) {
        if (value < 32 || value > 126) {
            throw NativeTextException("Invalid font axis tag")
        }
        code = (code << 8) | UInt32(value)
    }
    code
}
