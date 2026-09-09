package sdl.text

/** Invalidates only the platform matcher's snapshot; enumeration remains lazy. */
@When[os == "Windows"]
protected func refreshNativePlatformFonts(): Unit {
    WindowsFontApi.checkForUpdates = 1
}

@When[os == "Linux"]
protected func refreshNativePlatformFonts(): Unit {
    synchronized(LinuxFontApi.lock) {
        fontconfigDestroy("FcConfigDestroy", LinuxFontApi.config)
        LinuxFontApi.config = CPointer<Unit>()
    }
}

@When[os == "macOS"]
protected func refreshNativePlatformFonts(): Unit {
    // CoreText queries create fresh immutable descriptors; Cangjie owns no platform collection.
}
