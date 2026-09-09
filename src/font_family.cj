package sdl

import std.collection.ArrayList
import sdl.text.{NativeFontFamily, NativeFontSource, NativeInstalledFont, refreshDiscoveredFontFaces}

/** A font file and its zero-based face index; collections (`.ttc`) may contain multiple faces. */
public struct FontSource {
    public let path: String
    public let faceIndex: Int64
    public let variations: FontVariations

    public init(path: String, faceIndex!: Int64 = 0, instanceIndex!: Int64 = 0,
        variations!: FontVariations = FontVariations()) {
        if (faceIndex < 0 || faceIndex > Int64(Int32.Max)) {
            throw IllegalArgumentException("Font faceIndex must fit a non-negative 32-bit value")
        }
        if (instanceIndex < 0 || instanceIndex > 32767 || (instanceIndex != 0 && faceIndex > 65535)) {
            throw IllegalArgumentException("Font instanceIndex must be 0..32767 with a collection face in 0..65535")
        }
        this.variations = variations
        this.path = path
        this.faceIndex = faceIndex | (instanceIndex << 16)
    }

    /** Collection face number, excluding the FreeType named-instance bits. */
    public prop collectionIndex: Int64 {
        get() {
            faceIndex & 65535
        }
    }
    /** Named instance number; zero selects the font's default coordinates. */
    public prop instanceIndex: Int64 {
        get() {
            faceIndex >> 16
        }
    }

    internal func native(): NativeFontSource {
        NativeFontSource(path, faceIndex, coordinates: variations.native())
    }
}

/**
 * An immutable family definition with explicit real style faces and an ordered missing-glyph chain.
 * Missing styles probe conventional companion filenames, then synthesize when `synthesize` is true.
 * Supplied arrays are copied; registration and later caller mutations cannot alter a live family.
 */
public class FontFamily {
    public let regular: FontSource
    public let bold: ?FontSource
    public let italic: ?FontSource
    public let boldItalic: ?FontSource
    public let synthesize: Bool
    internal var installedMembers: Array<NativeInstalledFont> = []
    private var discoveredSources: Array<NativeFontSource> = []
    private var discoveryRevision: UInt64 = UInt64.Max
    private let additionalFaces: Array<FontFaceDefinition>
    private let fallbackSources: Array<FontSource>

    public init(regular: FontSource, bold!: ?FontSource = None, italic!: ?FontSource = None,
        boldItalic!: ?FontSource = None, fallbacks!: Array<FontSource> = [], synthesize!: Bool = true,
        faces!: Array<FontFaceDefinition> = []) {
        this.regular = regular
        this.bold = bold
        this.italic = italic
        this.boldItalic = boldItalic
        this.synthesize = synthesize
        this.fallbackSources = fallbacks.clone()
        this.additionalFaces = faces.clone()
    }

    /** Additional static weight/width/slant faces, copied independently of this immutable family. */
    public func faces(): Array<FontFaceDefinition> {
        additionalFaces.clone()
    }

    /** Independent copy of the explicit fallback sources; the platform UI font is appended at resolution. */
    public func fallbacks(): Array<FontSource> {
        fallbackSources.clone()
    }

    internal func native(key: String): NativeFontFamily {
        if (discoveryRevision == UInt64.Max && !installedMembers.isEmpty()) {
            discoveredSources = Array<NativeFontSource>(installedMembers.size) {i => installedMembers[i].source}
        }
        if (!discoveredSources.isEmpty() && discoveryRevision != Fonts.revision()) {
            installedMembers = refreshDiscoveredFontFaces(discoveredSources)
            discoveryRevision = Fonts.revision()
        }
        let sources = ArrayList<NativeFontSource>()
        for (source in fallbackSources) {
            sources.add(source.native())
        }
        for (source in Fonts.fallbacks()) {
            sources.add(source.native())
        }
        let explicitMembers = Array<NativeInstalledFont>(additionalFaces.size) {i => additionalFaces[i].native()}
        NativeFontFamily(regular.native(), sources.toArray(), key, bold: nativeSource(bold),
            italic: nativeSource(italic), boldItalic: nativeSource(boldItalic), synthesize: synthesize,
            members: installedMembers, additional: explicitMembers)
    }
}

private func nativeSource(source: ?FontSource): ?NativeFontSource {
    match (source) {
        case Some(value) => Some(value.native())
        case None => None
    }
}

/** Native face actually selected by the renderer; synthesized flags exclude styles present in its outlines. */
public struct ResolvedFontFace {
    public let source: FontSource
    public let familyName: String
    public let styleName: String
    public let weight: FontWeight
    public let synthesizedStyle: FontStyle

    public init(source: FontSource, familyName: String, styleName: String, synthesizedStyle: FontStyle,
        weight!: FontWeight = FontWeight.normal) {
        this.source = source
        this.familyName = familyName
        this.styleName = styleName
        this.synthesizedStyle = synthesizedStyle
        this.weight = weight
    }
}

/** Resolution snapshot, including the actual primary/fallback faces and failed source diagnostics. */
public struct FontResolution {
    public let requestedWeight: FontWeight
    public let requestedFamily: ?String
    public let faces: Array<ResolvedFontFace>
    public let warnings: Array<String>

    public init(requestedFamily: ?String, faces: Array<ResolvedFontFace>, warnings: Array<String>,
        requestedWeight!: FontWeight = FontWeight.normal) {
        this.requestedWeight = requestedWeight
        this.requestedFamily = requestedFamily
        this.faces = faces.clone()
        this.warnings = warnings.clone()
    }
}

/** Primary-face vertical metrics in logical pixels; descent is positive below the baseline. */
public struct FontMetrics {
    public let ascent: Float32
    public let descent: Float32
    public let lineHeight: Float32
    public let lineSkip: Float32

    public init(ascent: Float32, descent: Float32, lineHeight: Float32, lineSkip: Float32) {
        this.ascent = ascent
        this.descent = descent
        this.lineHeight = lineHeight
        this.lineSkip = lineSkip
    }
}

internal func publicFontSource(source: NativeFontSource): FontSource {
    let values = Array<FontVariation>(source.coordinates.size) {
        i => FontVariation(source.coordinates[i].tag, source.coordinates[i].value)
    }
    FontSource(source.path, faceIndex: source.faceIndex, variations: FontVariations(values))
}
