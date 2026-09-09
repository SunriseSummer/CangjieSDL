package sdl

import std.collection.{ArrayList, HashMap}
import std.env.getVariable
import std.sort.sort
import sdl.text.{NativeFontCatalog, NativeInstalledFont, discoverNativeFonts, nativePlatformFonts, selectNativeFont, 
    inspectFontCandidates}

/** Metadata for an installed file/collection face. Family names come from the font's SFNT name table. */
public struct InstalledFontFace {
    public let source: FontSource
    public let familyName: String
    public let styleName: String
    public let style: FontStyle
    public let widthClass: Int64
    public let variations: FontVariations
    private let variationAxes: Array<FontAxis>
    /** Numeric weight of this discovered face or named instance. */
    public prop weight: FontWeight {
        get() {
            style.weight
        }
    }
    /** Independent copy of the font's supported design axes. */
    public func axes(): Array<FontAxis> {
        variationAxes.clone()
    }

    public init(source: FontSource, familyName: String, styleName: String, style: FontStyle, widthClass!: Int64 = 5,
        axes!: Array<FontAxis> = [], variations!: FontVariations = FontVariations()) {
        this.source = source
        this.familyName = familyName
        this.styleName = styleName
        this.style = style
        this.widthClass = widthClass
        this.variationAxes = axes.clone()
        this.variations = variations
    }
}

// Cached platform/directory metadata. File matching remains separate from per-character fallback.
internal class SystemFontCatalog {
    private let catalog: NativeFontCatalog
    private let families = HashMap<String, FontFamily>()
    private let displayNames = HashMap<String, String>()

    init(refreshMetadata!: Bool = false) {
        let platform = nativePlatformFonts(4)
        let roots = ArrayList<String>(systemFontDirectories())
        for (record in platform) {
            roots.add(record.path)
        }
        this.catalog = discoverNativeFonts(roots.toArray(), cachePath: Fonts.metadataCache(), refresh: refreshMetadata)
        let groups = HashMap<String, ArrayList<NativeInstalledFont>>()
        for (face in catalog.faces) {
            if (face.familyName.isEmpty()) {
                continue
            }
            let key = face.familyName.toAsciiLower()
            displayNames[key] = face.familyName
            match (groups.get(key)) {
                case Some(group) => group.add(face)
                case None => groups[key] = ArrayList<NativeInstalledFont>([face])
            }
        }
        for ((key, group) in groups) {
            families[key] = familyFromInstalledFaces(group)
        }
        let roles = [FontRole.systemUI, FontRole.sansSerif, FontRole.serif, FontRole.monospace]
        let fallbackNames = [
            ["Microsoft YaHei UI", "Segoe UI", "PingFang SC", "Noto Sans CJK SC", "DejaVu Sans"],
            ["Arial", "Helvetica", "Noto Sans", "DejaVu Sans"],
            ["Times New Roman", "Times", "Noto Serif", "DejaVu Serif"],
            ["Cascadia Code", "Consolas", "Menlo", "DejaVu Sans Mono"]
        ]
        for (i in 0..roles.size) {
            let names = ArrayList<String>()
            for (record in nativePlatformFonts(Int32(i))) {
                names.add(record.family)
            }
            for (name in fallbackNames[i]) {
                names.add(name)
            }
            for (name in names) {
                if (let Some(family) <- families.get(name.toAsciiLower())) {
                    families[roles[i]] = family
                    break
                }
            }
        }
    }

    func find(name: String): ?FontFamily {
        families.get(name.toAsciiLower())
    }

    func faces(): Array<InstalledFontFace> {
        publicInstalledFaces(catalog.faces)
    }

    func names(): Array<String> {
        let names = ArrayList<String>()
        for ((_, name) in displayNames) {
            names.add(name)
        }
        let result = names.toArray()
        sort<String, String>(result, key: {value => value.toAsciiLower()})
        result
    }

    func warnings(): Array<String> {
        catalog.warnings.clone()
    }
}

extend Fonts {
    /** Resolves only this family/role/registered alias and returns its available faces and axes.
     * Does not enumerate the system catalog. A missing name returns an empty array.
     */
    public static func familyFaces(name: String): Array<InstalledFontFace> {
        if (let Some(family) <- Fonts.resolveFamily(name)) {
            let native = family.native("metadata:${name}")
            return publicInstalledFaces(inspectFontCandidates(native.primary, native))
        }
        []
    }
}

private func publicInstalledFaces(faces: Array<NativeInstalledFont>): Array<InstalledFontFace> {
    Array<InstalledFontFace>(faces.size) {
        i =>
            let face = faces[i]
            InstalledFontFace(FontSource(face.source.path, faceIndex: face.source.faceIndex), face.familyName,
                face.styleName,
                FontStyle(weight: FontWeight(max(1, min(1000, face.weight))), italic: (face.styleFlags & 2) != 0),
                widthClass: face.width, axes: publicFontAxes(face.axes),
                variations: publicFontVariations(face.coordinates))
    }
}

internal func familyFromInstalledFaces(faces: ArrayList<NativeInstalledFont>): FontFamily {
    let members = faces.toArray()
    let regular = match (selectNativeFont(members, 400, italic: false)) {
        case Some(face) => face.source
        case None => throw IllegalArgumentException("Cannot create a font family without faces")
    }
    let family = FontFamily(FontSource(regular.path, faceIndex: regular.faceIndex))
    family.installedMembers = members
    family
}

private func systemFontDirectories(): Array<String> {
    let roots = ArrayList<String>(Fonts.searchDirectories())
    if (let Some(local) <- getVariable("LOCALAPPDATA")) {
        roots.add(local + "/Microsoft/Windows/Fonts")
    }
    if (let Some(userDirectory) <- getVariable("HOME")) {
        roots.add(userDirectory + "/.local/share/fonts")
        roots.add(userDirectory + "/.fonts")
        roots.add(userDirectory + "/Library/Fonts")
    }
    if (let Some(dataHome) <- getVariable("XDG_DATA_HOME")) {
        roots.add(dataHome + "/fonts")
    }
    if (let Some(dataDirs) <- getVariable("XDG_DATA_DIRS")) {
        for (directory in dataDirs.split(":")) {
            if (!directory.isEmpty()) {
                roots.add(directory + "/fonts")
            }
        }
    }
    let windows = match (getVariable("WINDIR")) {
        case Some(value) => value;
        case None => "C:/Windows"
    }
    for (path in [windows + "/Fonts", "/System/Library/Fonts", "/Library/Fonts", "/usr/local/share/fonts",
            "/usr/share/fonts"]) {
        roots.add(path)
    }
    roots.toArray()
}

@When[os == "Windows"]
internal func fontPathKey(path: String): String {
    path.replace("\\", "/").toAsciiLower()
}

@When[os != "Windows"]
internal func fontPathKey(path: String): String {
    path
}
