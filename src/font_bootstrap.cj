package sdl

import std.collection.ArrayList
import sdl.text.{NativeFontSource, nativeSystemFontCandidates, canOpenNativeFont}

// Explicit application fonts must be usable before any platform fallback is opened.
internal func fontBootstrapSources(): Array<NativeFontSource> {
    let sources = ArrayList<NativeFontSource>()
    for (source in Fonts.configuredBootstrapSources()) {
        sources.add(source.native())
    }
    for (source in sources) {
        if (canOpenNativeFont(source)) {
            for (fallback in Fonts.fallbacks()) {
                sources.add(fallback.native())
            }
            return sources.toArray()
        }
    }
    if (let Some(family) <- Fonts.resolveFamily(FontRole.systemUI)) {
        sources.add(family.regular.native())
        if (canOpenNativeFont(family.regular.native())) {
            for (fallback in Fonts.fallbacks()) {
                sources.add(fallback.native())
            }
            return sources.toArray()
        }
    }
    for (source in nativeSystemFontCandidates()) {
        sources.add(source)
        if (canOpenNativeFont(source)) {
            for (fallback in Fonts.fallbacks()) {
                sources.add(fallback.native())
            }
            return sources.toArray()
        }
    }
    // Only consult a catalog the application explicitly loaded; bootstrap never triggers a full scan.
    if (Fonts.hasSystemCatalog()) {
        for (face in Fonts.systemFonts()) {
            if (!face.style.italic && face.weight == FontWeight.normal) {
                sources.add(face.source.native())
            }
        }
        for (face in Fonts.systemFonts()) {
            sources.add(face.source.native())
        }
    }
    for (source in Fonts.fallbacks()) {
        sources.add(source.native())
    }
    sources.toArray()
}
