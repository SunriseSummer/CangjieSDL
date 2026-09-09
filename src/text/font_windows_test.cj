package sdl.text

@When[os == "Windows"]
import std.collection.HashSet

@When[os == "Windows"]
@Test
func explicitWindowsFontCatalogIncludesDirectWriteFiles(): Unit {
    let collection = windowsCollectionFonts()
    @Expect(!collection.isEmpty())
    let all = HashSet<String>()
    for (record in platformFontFiles()) { all.add(record.path.toAsciiLower()) }
    // App-package fonts can exist outside the Fonts registry keys and standard directories.
    for (record in collection) { @Expect(all.contains(record.path.toAsciiLower())) }
}
