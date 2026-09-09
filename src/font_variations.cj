package sdl

import std.collection.ArrayList
import std.sort.sort
import sdl.text.{NativeFontAxis, NativeFontCoordinate, nativeFontVariationsAvailable}

/** One OpenType design coordinate. Tags contain exactly four printable ASCII characters. */
public struct FontVariation {
    public let tag: String
    public let value: Float32

    public init(tag: String, value: Float32) {
        if (tag.size != 4 || value.isNaN() || value.isInf() || value < -32768.0 || value >= 32768.0) {
            throw IllegalArgumentException("Font axis requires a four-byte tag and a finite 16.16 coordinate")
        }
        for (byte in tag.toArray()) {
            if (byte < 32 || byte > 126) {
                throw IllegalArgumentException("Font axis tags must be printable ASCII")
            }
        }
        this.tag = tag
        this.value = Float32(Int64(Float64(value) * 65536.0)) / 65536.0
    }
}

/** Immutable, sorted coordinates; duplicate tags are rejected and arrays are copied. */
public class FontVariations <: Equatable<FontVariations> {
    private let coordinates: Array<FontVariation>

    public init() {
        this.coordinates = []
    }

    public init(values: Array<FontVariation>) {
        if (values.size > 64) {
            throw IllegalArgumentException("At most 64 font axes may be specified")
        }
        this.coordinates = values.clone()
        sort<FontVariation, String>(coordinates, key: {item => item.tag})
        for (i in 1..coordinates.size) {
            if (coordinates[i - 1].tag == coordinates[i].tag) {
                throw IllegalArgumentException("Duplicate font axis tag")
            }
        }
    }

    /** Independent copy of the normalized coordinates. */
    public func values(): Array<FontVariation> {
        coordinates.clone()
    }

    /** Canonical coordinate identity, useful for application layout caches. */
    public func key(): String {
        let result = StringBuilder()
        for (item in coordinates) {
            result.append("${item.tag}:${item.value.toBits()};")
        }
        result.toString()
    }

    internal func withoutWeight(): FontVariations {
        let result = ArrayList<FontVariation>()
        for (item in coordinates) {
            if (item.tag != "wght") {
                result.add(item)
            }
        }
        FontVariations(result.toArray())
    }

    internal func requestedWeight(base: FontWeight): FontWeight {
        for (item in coordinates) {
            if (item.tag == "wght") {
                return FontWeight(Int64(Float64(item.value) + 0.5))
            }
        }
        base
    }

    internal func native(): Array<NativeFontCoordinate> {
        Array<NativeFontCoordinate>(coordinates.size) {
            i => NativeFontCoordinate(coordinates[i].tag, coordinates[i].value)
        }
    }

    public operator func ==(other: FontVariations): Bool {
        key() == other.key()
    }
    public operator func !=(other: FontVariations): Bool {
        !(this == other)
    }
}

/** Supported variation axis and its font-defined bounds/default. */
public struct FontAxis {
    public let tag: String
    public let minimum: Float32
    public let defaultValue: Float32
    public let maximum: Float32

    public init(tag: String, minimum: Float32, defaultValue: Float32, maximum: Float32) {
        this.tag = tag
        this.minimum = minimum
        this.defaultValue = defaultValue
        this.maximum = maximum
    }
}

internal func publicFontAxes(axes: Array<NativeFontAxis>): Array<FontAxis> {
    Array<FontAxis>(axes.size) {i => FontAxis(axes[i].tag, axes[i].minimum, axes[i].defaultValue, axes[i].maximum)}
}

internal func publicFontVariations(values: Array<NativeFontCoordinate>): FontVariations {
    FontVariations(Array<FontVariation>(values.size) {i => FontVariation(values[i].tag, values[i].value)})
}

extend Fonts {
    /** Whether the loaded official SDL_ttf supports the named-instance variation backend. */
    public static func supportsVariations(): Bool {
        nativeFontVariationsAvailable()
    }
}
