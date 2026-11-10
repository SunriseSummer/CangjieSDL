// CangjieSDL build script (cjpm `build.cj`).
//
// The SDL3 dynamic libraries must live in `.sdl3/` under the link-time names
// cjpm expects: `libSDL3.so`/`libSDL3_ttf.so`/`libSDL3_image.so` on Linux,
// `SDL3.dll`/`SDL3_ttf.dll`/`SDL3_image.dll` on Windows, and
// `libSDL3.dylib`/... on macOS. This script finds a locally installed or
// extracted copy and puts it there, so developers no longer have to download
// and rename the libraries by hand.
//
// Search order for every library:
//   1. $SDL3_LIB_DIR (explicit override, e.g. an extracted official release)
//   2. directories from $LD_LIBRARY_PATH (Linux), $PATH (Windows),
//      $DYLD_LIBRARY_PATH (macOS)
//   3. the usual installation directories of the platform
// A resolvable existing `.sdl3` library file is never overwritten; dangling
// links are replaced with a real copy. On other platforms
// (Android, OHOS, ...) the script is a no-op.
//
// All output goes to cjpm's `build-script-cache/<mode>/sdl/bin/script-log`.

import std.env.{getCommandLine, getVariable, getWorkingDirectory}
import std.fs.{Directory, canonicalize, copy, exists, remove}
import std.collection.ArrayList
import std.sort.sort

func ensureSDL3Libraries(): Int64 {
    if (!supportedPlatform()) {
        return 0
    }
    let dest = "${getWorkingDirectory().toString()}/.sdl3"
    let searched = searchDirectories()
    var destCreated = false

    let failures = ArrayList<String>()
    for (name in ["SDL3", "SDL3_ttf", "SDL3_image"]) {
        let target = "${dest}/${libraryFileName(name)}"
        if (isRealFile(target)) {
            continue
        }
        match (locateLibrary(searched, name)) {
            case Some(real) =>
                if (!destCreated) {
                    if (!exists(dest)) {
                        Directory.create(dest)
                    }
                    destCreated = true
                }
                if (exists(target)) {
                    remove(target)
                }
                copy(real, to: target)
                println("linked SDL library: ${real} -> ${target}")
            case None =>
                failures.add(target)
        }
    }

    if (failures.isEmpty()) {
        return 0
    }
    println("error: no local install found for these SDL3 libraries:")
    for (path in failures) {
        println("  missing ${path}")
    }
    println("hint: install SDL3 (apt/brew or vcpkg/msys2, or an official")
    println("      release), or point $SDL3_LIB_DIR at a directory containing")
    println("      the SDL3/SDL3_ttf/SDL3_image libraries.")
    return 1
}

@When[os == "Linux" || os == "Windows" || os == "macOS"]
func supportedPlatform(): Bool {
    true
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func supportedPlatform(): Bool {
    false
}

// Returns the real file of the first usable hit across the search path; a hit
// that does not resolve (e.g. a dangling symlink) is skipped, not fatal.
func locateLibrary(searched: ArrayList<String>, name: String): Option<String> {
    for (dir in searched) {
        if (let Some(source) <- findInDirectory(dir, name)) {
            if (let Some(real) <- realPath(source)) {
                return Some(real)
            }
        }
    }
    None
}

// Resolves symlinks to the real file. std.fs.copy preserves symlinks verbatim,
// which would leave dangling links inside `.sdl3` when only the source side
// has the versioned file; cjpm canonicalizes ffi.c entries itself, so only a
// resolvable real file is usable.
func realPath(path: String): Option<String> {
    try {
        Some(canonicalize(path).toString())
    } catch (error: Exception) {
        println("warning: skipping unusable ${path}: ${error.message}")
        None
    }
}

func isRealFile(path: String): Bool {
    try {
        canonicalize(path)
        true
    } catch (error: Exception) {
        false
    }
}

// Returns a library file usable under `libraryFileName(name)`: an exact-name
// file, otherwise the highest-versioned variant (e.g. libSDL3.so.3.4.12,
// libSDL3-0.dll from mingw, or libSDL3.0.dylib from an official macOS dmg).
func findInDirectory(dir: String, name: String): Option<String> {
    if (!exists(dir)) {
        return None
    }
    for (exact in exactLibraryNames(name)) {
        let path = "${dir}/${exact}"
        if (isRealFile(path)) {
            return Some(path)
        }
    }
    let candidates = ArrayList<String>()
    try {
        for (entry in Directory.readFrom(dir)) {
            if (entry.isDirectory()) {
                continue
            }
            let fileName = entry.name
            if (fileName.endsWith(".debug") || fileName.endsWith(".dbg")) {
                continue
            }
            for ((prefix, suffix) in libraryPatterns(name)) {
                if (fileName.startsWith(prefix) && fileName.size > prefix.size && fileName.endsWith(suffix)) {
                    candidates.add("${dir}/${fileName}")
                    break
                }
            }
        }
    } catch (error: Exception) {
        println("warning: cannot scan ${dir}: ${error.message}")
        return None
    }
    if (candidates.isEmpty()) {
        return None
    }
    let sorted = candidates.toArray()
    sort(sorted)
    Some(sorted[sorted.size - 1])
}

// File names that can be used verbatim as the link-time library.
@When[os == "Linux"]
func exactLibraryNames(name: String): Array<String> {
    ["lib${name}.so"]
}

@When[os == "Windows"]
func exactLibraryNames(name: String): Array<String> {
    ["${name}.dll", "lib${name}.dll"]
}

@When[os == "macOS"]
func exactLibraryNames(name: String): Array<String> {
    ["lib${name}.dylib"]
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func exactLibraryNames(name: String): Array<String> {
    []
}

// (prefix, suffix) pairs for versioned/renamed variants, e.g. the SONAME
// files of a distro package or mingw-w64's libSDL3-0.dll.
@When[os == "Linux"]
func libraryPatterns(name: String): Array<(String, String)> {
    [("lib${name}.so.", "")]
}

@When[os == "Windows"]
func libraryPatterns(name: String): Array<(String, String)> {
    [("${name}-", ".dll"), ("lib${name}-", ".dll"), ("${name}.", ".dll")]
}

@When[os == "macOS"]
func libraryPatterns(name: String): Array<(String, String)> {
    [("lib${name}.", ".dylib")]
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func libraryPatterns(name: String): Array<(String, String)> {
    []
}

@When[os == "Linux"]
func libraryFileName(name: String): String {
    "lib${name}.so"
}

@When[os == "Windows"]
func libraryFileName(name: String): String {
    "${name}.dll"
}

@When[os == "macOS"]
func libraryFileName(name: String): String {
    "lib${name}.dylib"
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func libraryFileName(name: String): String {
    ""
}

@When[os == "Linux"]
func searchDirectories(): ArrayList<String> {
    let dirs = ArrayList<String>()
    if (let Some(dir) <- getVariable("SDL3_LIB_DIR")) {
        dirs.add(dir)
    }
    appendSplit(dirs, "LD_LIBRARY_PATH", ":")
    for (dir in [
        "/usr/local/lib",
        "/usr/lib/x86_64-linux-gnu",
        "/usr/lib/aarch64-linux-gnu",
        "/usr/lib64",
        "/usr/lib",
        "/lib/x86_64-linux-gnu",
        "/lib/aarch64-linux-gnu",
        "/usr/local/lib64",
    ]) {
        dirs.add(dir)
    }
    dirs
}

@When[os == "Windows"]
func searchDirectories(): ArrayList<String> {
    let dirs = ArrayList<String>()
    if (let Some(dir) <- getVariable("SDL3_LIB_DIR")) {
        dirs.add(dir)
    }
    appendSplit(dirs, "PATH", ";")
    if (let Some(root) <- getVariable("VCPKG_ROOT")) {
        dirs.add("${root}\\installed\\x64-windows\\bin")
        dirs.add("${root}\\installed\\x64-windows\\lib")
    }
    for (dir in [
        "C:\\vcpkg\\installed\\x64-windows\\bin",
        "C:\\vcpkg\\installed\\x64-windows\\lib",
        "C:\\msys64\\mingw64\\bin",
        "C:\\SDL3\\x64\\bin",
        "C:\\SDL3\\x64\\lib",
    ]) {
        dirs.add(dir)
    }
    dirs
}

@When[os == "macOS"]
func searchDirectories(): ArrayList<String> {
    let dirs = ArrayList<String>()
    if (let Some(dir) <- getVariable("SDL3_LIB_DIR")) {
        dirs.add(dir)
    }
    appendSplit(dirs, "DYLD_LIBRARY_PATH", ":")
    appendSplit(dirs, "LD_LIBRARY_PATH", ":")
    if (let Some(prefix) <- getVariable("HOMEBREW_PREFIX")) {
        dirs.add("${prefix}/lib")
    }
    for (dir in [
        "/opt/homebrew/lib",
        "/usr/local/lib",
        "/opt/local/lib",
    ]) {
        dirs.add(dir)
    }
    dirs
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func searchDirectories(): ArrayList<String> {
    ArrayList<String>()
}

func appendSplit(dirs: ArrayList<String>, variable: String, separator: String): Unit {
    if (let Some(path) <- getVariable(variable)) {
        for (entry in path.split(separator)) {
            let dir = unquote(entry)
            if (!dir.isEmpty()) {
                dirs.add(dir)
            }
        }
    }
}

// Windows often stores quoted PATH entries ("C:\Program Files\...").
func unquote(entry: String): String {
    if (entry.size >= 2 && ((entry.startsWith("\"") && entry.endsWith("\"")) ||
        (entry.startsWith("'") && entry.endsWith("'")))) {
        entry[1..entry.size - 1]
    } else {
        entry
    }
}

main(): Int64 {
    // cjpm runs this script for every module it compiles; the working
    // directory is that module's root, so `./.sdl3` is the right destination.
    let arguments = getCommandLine()
    let step = if (arguments.size > 1) { arguments[1] } else { "" }
    match (step) {
        case "pre-build" => ensureSDL3Libraries()
        case "pre-test" => ensureSDL3Libraries()
        case _ => 0
    }
}
