package sdl.text

import std.collection.{ArrayList, HashSet}
import std.math.abs

// Each search band dominates every possible 1..1000 weight distance.
private let WEIGHT_SEARCH_BAND: Int64 = 2000
private let SLANT_MISMATCH_COST: Int64 = 100000
private let WIDTH_CLASS_COST: Int64 = 10000
private let NORMAL_WIDTH_CLASS: Int64 = 5

// CSS weight search order, including the asymmetric 400..500 interval.
protected func fontWeightMatchRank(request: Int64, candidate: Int64): Int64 {
    if (request < 400) {
        if (candidate <= request) {
            request - candidate
        } else {
            WEIGHT_SEARCH_BAND + candidate - request
        }
    } else if (request > 500) {
        if (candidate >= request) {
            candidate - request
        } else {
            WEIGHT_SEARCH_BAND + request - candidate
        }
    } else {
        if (candidate >= request && candidate <= 500) {
            candidate - request
        } else if (candidate < request) {
            WEIGHT_SEARCH_BAND + request - candidate
        } else {
            WEIGHT_SEARCH_BAND * 2 + candidate - request
        }
    }
}

protected func selectNativeFont(faces: Array<NativeInstalledFont>, weight: Int64, italic!: Bool): ?NativeInstalledFont {
    var selected: ?NativeInstalledFont = None
    var rank = Int64.Max
    for (face in faces) {
        let slantPenalty: Int64 = if (((face.styleFlags & 2) != 0) == italic) {
            0
        } else {
            SLANT_MISMATCH_COST
        }
        let widthPenalty = abs(face.width - NORMAL_WIDTH_CLASS) * WIDTH_CLASS_COST
        let score = slantPenalty + widthPenalty + fontWeightMatchRank(weight, face.weight)
        // Input discovery order is deterministic. Prefer the base face over a duplicate 400 instance.
        if (score < rank) {
            rank = score
            selected = Some(face)
        }
    }
    selected
}

protected func inspectFontCandidates(source: NativeFontSource, family: NativeFontFamily): Array<NativeInstalledFont> {
    if (!family.members.isEmpty()) {
        return family.members
    }
    let sources = ArrayList<NativeFontSource>([source])
    for (candidate in [family.bold, family.italic, family.boldItalic]) {
        if (let Some(value) <- candidate) {
            sources.add(value)
        }
    }
    if (source.faceIndex < 65536) {
        for (flags in [Int32(1), Int32(2), Int32(3)]) {
            for (path in styleCompanionCandidates(source.path, flags)) {
                sources.add(NativeFontSource(path, source.faceIndex))
            }
        }
    }
    let faces = ArrayList<NativeInstalledFont>(family.additional)
    for (candidate in sources) {
        try {
            for (face in inspectNativeFontFile(candidate.path)) {
                if ((face.source.faceIndex & 65535) == (candidate.faceIndex & 65535) && (candidate.faceIndex < 65536 ||
                    face.source.faceIndex == candidate.faceIndex)) {
                    let selectedSource = NativeFontSource(face.source.path, face.source.faceIndex,
                        coordinates: candidate.coordinates)
                    faces.add(
                        NativeInstalledFont(selectedSource, face.familyName, face.styleName, face.styleFlags,
                            weight: face.weight, width: face.width, axes: face.axes, coordinates: face.coordinates))
                }
            }
        } catch (_: NativeTextException) {
            // Optional companion probes recover by trying the next source. The primary open reports failure.
            continue
        }
    }
    faces.toArray()
}

/** Refresh only the original discovered files/collection faces, without enumerating a directory. */
protected func refreshDiscoveredFontFaces(sources: Array<NativeFontSource>): Array<NativeInstalledFont> {
    let faces = ArrayList<NativeInstalledFont>()
    let seen = HashSet<String>()
    for (source in sources) {
        let collection = source.faceIndex & 65535
        if (!seen.add("${source.path}:${collection}")) {
            continue
        }
        try {
            for (face in inspectNativeFontFile(source.path)) {
                if ((face.source.faceIndex & 65535) == collection) {
                    faces.add(face)
                }
            }
        } catch (_: NativeTextException) {
            // A removed or damaged file is retried after the next registry revision.
            continue
        }
    }
    faces.toArray()
}
