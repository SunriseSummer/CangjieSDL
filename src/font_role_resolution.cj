package sdl

import std.collection.{ArrayList, HashSet, HashMap}
import sdl.text.{NativeInstalledFont, nativePlatformFonts, discoverNativeFonts, nativeSystemFontCandidates,
    nativePlatformNamedFonts, NativePlatformFont, nativeFontFileAliases, nativeEmojiFonts}

// Resolve the requested role before considering a complete installed-font catalog.
internal func resolvePlatformFontRole(name: String): ?FontFamily {
    if (name == FontRole.emoji) {
        return familyFromPlatformRecords(nativeEmojiFonts())
    }
    let roles = [FontRole.systemUI, FontRole.sansSerif, FontRole.serif, FontRole.monospace]
    for (i in 0..roles.size) {
        if (name != roles[i]) {
            continue
        }
        let records = nativePlatformFonts(Int32(i))
        if (let Some(family) <- familyFromPlatformRecords(records)) {
            return Some(family)
        }
        if (name == FontRole.systemUI) {
            for (source in nativeSystemFontCandidates()) {
                let fallback = discoverNativeFonts([source.path])
                if (!fallback.faces.isEmpty()) {
                    return Some(familyFromInstalledFaces(ArrayList<NativeInstalledFont>(fallback.faces)))
                }
            }
        }
        return None
    }
    None
}

internal func resolvePlatformFontName(name: String): ?FontFamily {
    if (let Some(family) <- familyFromPlatformRecords(nativePlatformNamedFonts(name))) {
        return Some(family)
    }
    // Application search roots are opt-in; unknown system names do not scan system directories.
    if (!Fonts.searchDirectories().isEmpty()) {
        let candidates = discoverNativeFonts(Fonts.searchDirectories())
        let matching = ArrayList<NativeInstalledFont>()
        for (face in candidates.faces) {
            if (face.familyName.toAsciiLower() == name.toAsciiLower()) {
                matching.add(face)
            }
        }
        if (!matching.isEmpty()) {
            return Some(familyFromInstalledFaces(matching))
        }
    }
    None
}

private func familyFromPlatformRecords(records: Array<NativePlatformFont>): ?FontFamily {
    let paths = ArrayList<String>()
    let seen = HashSet<String>()
    for (record in records) {
        if (seen.add(record.path)) {
            paths.add(record.path)
        }
    }
    let candidates = discoverNativeFonts(paths.toArray())
    let matching = ArrayList<NativeInstalledFont>()
    let fileFamilies = HashMap<String, HashSet<String>>()
    for (face in candidates.faces) {
        let key = fontPathKey(face.source.path)
        let names = fileFamilies.get(key).getOrDefault({=> HashSet<String>()})
        names.add(face.familyName.toAsciiLower())
        fileFamilies[key] = names
    }
    for (face in candidates.faces) {
        for (record in records) {
            if (fontPathKey(face.source.path) != fontPathKey(record.path)) {
                continue
            }
            if (record.index >= 0) {
                if ((record.index & 65535) == (face.source.faceIndex & 65535)) {
                    matching.add(face);
                    break
                }
            } else {
                var matches = face.familyName.toAsciiLower() == record.family.toAsciiLower()
                for (alias in nativeFontFileAliases(face.source.path, face.source.faceIndex & 65535)) {
                    matches = matches || alias.toAsciiLower() == record.family.toAsciiLower()
                }
                if (fileFamilies[fontPathKey(face.source.path)].size == 1 || matches) {
                    matching.add(face);
                    break
                }
            }
        }
    }
    if (matching.isEmpty()) {
        None
    } else {
        Some(familyFromInstalledFaces(matching))
    }
}
