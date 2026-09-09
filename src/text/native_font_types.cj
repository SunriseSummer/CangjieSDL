package sdl.text

import std.deriving.*

@Derive[Equatable, Hashable]
internal struct NativeFontKey {
    let family: String
    let sizeBits: UInt32
    let style: Int32
    let emoji: Bool

    init(family: String, sizeBits: UInt32, style: Int32, emoji!: Bool = false) {
        this.family = family
        this.sizeBits = sizeBits
        this.style = style
        this.emoji = emoji
    }
}

/** File/collection source passed across the safe renderer-to-text boundary. */
protected struct NativeFontSource {
    public let path: String
    public let faceIndex: Int64
    public let coordinates: Array<NativeFontCoordinate>

    public init(path: String, faceIndex: Int64, coordinates!: Array<NativeFontCoordinate> = []) {
        this.path = path
        this.faceIndex = faceIndex
        this.coordinates = coordinates
    }

    /** Collision-safe file/collection identity for internal caches. */
    public func key(): String {
        let result = StringBuilder()
        let identity = nativeFontPathKey(path)
        result.append("${identity.size}:${identity}:${faceIndex}")
        for (item in coordinates) {
            result.append("|${item.tag}:${item.value.toBits()}")
        }
        result.toString()
    }
}

@When[os == "Windows"]
private func nativeFontPathKey(path: String): String {
    path.replace("\\", "/").toAsciiLower()
}

@When[os != "Windows"]
private func nativeFontPathKey(path: String): String {
    path
}

/** Resolved primary/fallback definitions supplied by the parent renderer package. */
protected struct NativeFontFamily {
    public let primary: NativeFontSource
    public let fallbacks: Array<NativeFontSource>
    public let bold: ?NativeFontSource
    public let italic: ?NativeFontSource
    public let boldItalic: ?NativeFontSource
    public let synthesize: Bool
    public let cacheKey: String
    public let coordinates: Array<NativeFontCoordinate>
    public let weight: Int64
    public let members: Array<NativeInstalledFont>
    public let additional: Array<NativeInstalledFont>

    public init(primary: NativeFontSource, fallbacks: Array<NativeFontSource>, cacheKey: String,
        bold!: ?NativeFontSource = None, italic!: ?NativeFontSource = None, boldItalic!: ?NativeFontSource = None,
        synthesize!: Bool = true, weight!: Int64 = 0, members!: Array<NativeInstalledFont> = [],
        coordinates!: Array<NativeFontCoordinate> = [], additional!: Array<NativeInstalledFont> = []) {
        this.primary = primary
        this.fallbacks = fallbacks
        this.cacheKey = cacheKey
        this.bold = bold
        this.italic = italic
        this.boldItalic = boldItalic
        this.synthesize = synthesize
        this.weight = weight
        this.members = members
        this.coordinates = coordinates
        this.additional = additional
    }

    public init(primaryPath: String, fallbackPaths: Array<String>, cacheKey: String) {
        this.primary = NativeFontSource(primaryPath, 0)
        this.fallbacks = Array<NativeFontSource>(fallbackPaths.size) {i => NativeFontSource(fallbackPaths[i], 0)}
        this.cacheKey = cacheKey
        this.bold = None
        this.italic = None
        this.boldItalic = None
        this.synthesize = true
        this.weight = 0
        this.members = []
        this.coordinates = []
        this.additional = []
    }

    /** Includes numeric weight and canonical coordinates in every downstream cache identity. */
    public func withRequest(value: Int64, requested: Array<NativeFontCoordinate>, key: String): NativeFontFamily {
        NativeFontFamily(primary, fallbacks, "${cacheKey}|w${value}|${key}", bold: bold, italic: italic,
            boldItalic: boldItalic, synthesize: synthesize, weight: value, members: members, coordinates: requested,
            additional: additional)
    }

    /** Primary file path; an empty path selects the platform UI font. */
    public prop primaryPath: String {
        get() {
            primary.path
        }
    }
}

/** Vertical font metrics in native pixels; descent is positive below the baseline. */
protected struct NativeLineMetrics {
    public let ascent: Float32
    public let descent: Float32
    public let height: Float32
    public let lineSkip: Float32

    public init(ascent: Float32, descent: Float32, height: Float32, lineSkip: Float32) {
        this.ascent = ascent
        this.descent = descent
        this.height = height
        this.lineSkip = lineSkip
    }
}

/** Actual opened face and its synthesized style, for optional resolution diagnostics. */
protected struct NativeFontInfo {
    public let source: NativeFontSource
    public let familyName: String
    public let styleName: String
    public let weight: Int64
    public let synthesizedFlags: Int32

    public init(source: NativeFontSource, familyName: String, styleName: String, synthesizedFlags: Int32,
        weight!: Int64 = 400) {
        this.source = source
        this.familyName = familyName
        this.styleName = styleName
        this.synthesizedFlags = synthesizedFlags
        this.weight = weight
    }
}

/** Complete face graph and failed source warnings for one resolved request. */
protected struct NativeFontResolution {
    public let faces: Array<NativeFontInfo>
    public let warnings: Array<String>

    public init(faces: Array<NativeFontInfo>, warnings: Array<String>) {
        this.faces = faces
        this.warnings = warnings
    }
}

/** Normalizes native sizes to the shared 1/256-pixel cache grid; rejects non-finite/unsupported magnitudes. */
protected func normalizeFontPointSize(pointSize: Float32): Float32 {
    if (pointSize.isNaN() || pointSize.isInf() || pointSize > 65536.0) {
        throw IllegalArgumentException("Font point size must be finite and at most 65536 pixels")
    }
    if (!(pointSize > 0.0)) {
        return 15.0
    }
    max(Float32(1.0 / 256.0), Float32(Int64(pointSize * 256.0)) / 256.0)
}
