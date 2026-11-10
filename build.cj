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
// links are replaced with a real copy. `.sdl3` is a generated, git-ignored
// build artifact. When cross-compiling to Windows, the DLLs are provisioned
// as well (best-effort: only executable links need them). On other platforms
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

    let failures = ArrayList<String>()
    for (name in ["SDL3", "SDL3_ttf", "SDL3_image"]) {
        if (!provisionLibrary(dest, searched, name, libraryFileName(name), exactLibraryNames(name),
            libraryPatterns(name))) {
            failures.add("${dest}/${libraryFileName(name)}")
        }
    }

    if (windowsCrossTarget()) {
        // Cross-linking a Windows executable also needs the DLLs; a static
        // library build does not, so this stays best-effort.
        let missingDlls = ArrayList<String>()
        for (name in ["SDL3", "SDL3_ttf", "SDL3_image"]) {
            if (!provisionLibrary(dest, searched, name, windowsLibraryFileName(name), windowsExactNames(name),
                windowsPatterns(name))) {
                missingDlls.add(windowsLibraryFileName(name))
            }
        }
        if (!missingDlls.isEmpty()) {
            println("note: cross-compiling for Windows, but these DLLs were not found locally:")
            for (file in missingDlls) {
                println("  missing .sdl3/${file} (only needed to cross-link executables)")
            }
            println("      point $SDL3_LIB_DIR at an extracted win64 SDL3 release to provide them.")
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

// Returns true when the target file was already present or got placed.
func provisionLibrary(dest: String, searched: ArrayList<String>, name: String, targetFileName: String,
    exacts: Array<String>, patterns: Array<(String, String)>): Bool {
    let target = "${dest}/${targetFileName}"
    if (isRealFile(target)) {
        return true
    }
    match (locateLibraryWith(searched, name, exacts, patterns)) {
        case Some(real) =>
            if (!exists(dest)) {
                Directory.create(dest)
            }
            if (exists(target)) {
                remove(target)
            }
            copy(real, to: target)
            println("linked SDL library: ${real} -> ${target}")
            true
        case None =>
            false
    }
}

@When[os == "Linux" || os == "Windows" || os == "macOS"]
func supportedPlatform(): Bool {
    true
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func supportedPlatform(): Bool {
    false
}

// cjpm runs build scripts as host binaries and passes no target information;
// the cross target triple only shows up in the script's own cache path, e.g.
// build-script-cache/x86_64-windows-gnu/release/<module>/bin/build-script.
func windowsCrossTarget(): Bool {
    let arguments = getCommandLine()
    arguments.size > 0 && arguments[0].contains("windows-gnu")
}

// Returns the real file of the first usable hit across the search path; a hit
// that does not resolve (e.g. a dangling symlink) is skipped, not fatal.
func locateLibraryWith(searched: ArrayList<String>, name: String, exacts: Array<String>,
    patterns: Array<(String, String)>): Option<String> {
    for (dir in searched) {
        if (let Some(source) <- findInDirectoryWith(dir, name, exacts, patterns)) {
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

// Returns a library file usable under the requested name: an exact-name file,
// otherwise the highest-versioned variant (e.g. libSDL3.so.3.4.12,
// libSDL3-0.dll from mingw, or libSDL3.0.dylib from an official macOS dmg).
func findInDirectoryWith(dir: String, name: String, exacts: Array<String>,
    patterns: Array<(String, String)>): Option<String> {
    if (!exists(dir)) {
        return None
    }
    for (exact in exacts) {
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
            for ((prefix, suffix) in patterns) {
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
    windowsExactNames(name)
}

@When[os == "macOS"]
func exactLibraryNames(name: String): Array<String> {
    ["lib${name}.dylib"]
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func exactLibraryNames(name: String): Array<String> {
    []
}

// Windows naming, also used when cross-compiling to Windows from another host.

func windowsExactNames(name: String): Array<String> {
    ["${name}.dll", "lib${name}.dll"]
}

func windowsPatterns(name: String): Array<(String, String)> {
    [("${name}-", ".dll"), ("lib${name}-", ".dll"), ("${name}.", ".dll")]
}

func windowsLibraryFileName(name: String): String {
    "${name}.dll"
}

// (prefix, suffix) pairs for versioned/renamed variants, e.g. the SONAME
// files of a distro package or mingw-w64's libSDL3-0.dll.
@When[os == "Linux"]
func libraryPatterns(name: String): Array<(String, String)> {
    [("lib${name}.so.", "")]
}

@When[os == "Windows"]
func libraryPatterns(name: String): Array<(String, String)> {
    windowsPatterns(name)
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
    windowsLibraryFileName(name)
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
    // Every stage that validates or consumes the `[ffi.c]` entries is hooked,
    // so `.sdl3` is populated before cjpm checks it.
    let arguments = getCommandLine()
    let step = if (arguments.size > 1) { arguments[1] } else { "" }
    match (step) {
        case "pre-build" | "pre-test" | "pre-bench" | "pre-run" | "pre-install" | "pre-check" | "pre-tree" | "pre-update" =>
            ensureSDL3Libraries()
        case _ => 0
    }
}
