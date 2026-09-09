package sdl

import sdl.text.{nativePlatformFonts, nativePlatformNamedFonts}

@When[os == "Windows"]
@Test
func namedWindowsFontsResolveWithoutBuildingACatalog(): Unit {
    Fonts.clear()
    try {
        let records = nativePlatformNamedFonts("Segoe UI")
        @Expect(!records.isEmpty())
        @Expect(Fonts.registerSystem("lazy-ui", "Segoe UI"))
        @Expect(!Fonts.hasSystemCatalog())
        @Expect(!Fonts.registerSystem("missing-ui", "CSDL non-existent font 9e734105"))
        @Expect(!Fonts.hasSystemCatalog())
        let window = SdlWindow(WindowSpec("Lazy named font", 180, 100, supersample: 1), hidden: true)
        try {
            let resolved = window.renderer.resolveFont(font: "Segoe UI", style: FontStyle(bold: true, italic: true))
            @Expect(resolved.faces[0].familyName, "Segoe UI")
            @Expect(!resolved.faces[0].synthesizedStyle.bold && !resolved.faces[0].synthesizedStyle.italic)
            @Expect(!Fonts.hasSystemCatalog())
        } finally { window.close() }
    } finally { Fonts.clear() }
}

@Test
func platformRolesAndAliasesResolveToFiles(): Unit {
    let window = SdlWindow(WindowSpec("System font roles", 180, 100, supersample: 1))
    try {
        for (role in [FontRole.systemUI, FontRole.sansSerif, FontRole.serif, FontRole.monospace]) {
            let resolved = window.renderer.resolveFont(font: role)
            @Expect(!resolved.faces.isEmpty())
            @Expect(!resolved.faces[0].source.path.isEmpty())
        }
        let system = nativePlatformFonts(0)
        if (!system.isEmpty()) {
            @Expect(Fonts.registerSystem("platform-ui-alias", system[0].family))
            let named = window.renderer.resolveFont(font: "platform-ui-alias")
            let role = window.renderer.resolveFont(font: FontRole.systemUI)
            @Expect(named.faces[0].source.path, role.faces[0].source.path)
            @Expect(named.faces[0].source.faceIndex, role.faces[0].source.faceIndex)
        }
    } finally { window.close(); Fonts.unregister("platform-ui-alias") }
}

@Test
func applicationDiscoveryDirectoriesAreCopiedAndInvalidateCatalog(): Unit {
    let roots = ["application-fonts"]
    let revision = Fonts.revision()
    Fonts.setSearchDirectories(roots)
    try {
        roots[0] = "mutated"
        @Expect(Fonts.searchDirectories()[0], "application-fonts")
        @Expect(Fonts.revision() > revision)
    } finally { Fonts.setSearchDirectories([]) }
}

@Test
func explicitlySelectedNamedInstanceRetainsItsCoordinates(): Unit {
    for (face in Fonts.systemFonts()) {
        if (face.familyName == "Cascadia Code" && face.weight == FontWeight.bold && !face.style.italic) {
            Fonts.registerFamily("pinned-bold-instance", FontFamily(face.source))
            let window = SdlWindow(WindowSpec("Pinned named instance", 180, 100, supersample: 1))
            try {
                let resolved = window.renderer.resolveFont(font: "pinned-bold-instance")
                @Expect(resolved.faces[0].source.faceIndex, face.source.faceIndex)
                @Expect(resolved.faces[0].weight, FontWeight.bold)
                @Expect(!resolved.faces[0].synthesizedStyle.bold)
            } finally { window.close(); Fonts.unregister("pinned-bold-instance") }
            return
        }
    }
}
