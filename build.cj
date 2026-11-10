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
//
// For a native build the host format is mandatory: a miss aborts the build
// with an actionable message. For a cross build (target detected from the
// script's own cache path) both the host and the target format are provided
// on a best-effort basis, because cjpm does not validate `[ffi.c]` for cross
// builds; only cross-linking an executable needs the target libraries.
//
// A resolvable existing `.sdl3` library file is never overwritten; dangling
// links are replaced with a real copy. `.sdl3` is a generated, git-ignored
// build artifact. On other platforms (Android, OHOS, ...) the script is a
// no-op.
//
// All output goes to cjpm's `build-script-cache/<mode>/sdl/bin/script-log`.

import std.env.{getCommandLine, getVariable, getWorkingDirectory}
import std.fs.{Directory, canonicalize, copy, exists, remove}
import std.collection.ArrayList
import std.sort.sort

func ensureSDL3Libraries(): Int64 {
    let host = hostKind()
    if (host.isEmpty()) {
        return 0
    }
    let target = targetKind()
    let crossBuild = target != host
    let dest = "${getWorkingDirectory().toString()}/.sdl3"
    let searched = searchDirectories()
    let names = ["SDL3", "SDL3_ttf", "SDL3_image"]

    let failures = ArrayList<String>()
    for (name in names) {
        if (!provisionLibrary(dest, searched, name, host)) {
            if (!crossBuild) {
                failures.add("${dest}/${libraryFileName(host, name)}")
            }
        }
    }

    if (crossBuild) {
        let missing = ArrayList<String>()
        for (name in names) {
            if (!provisionLibrary(dest, searched, name, target)) {
                missing.add(libraryFileName(target, name))
            }
        }
        if (!missing.isEmpty()) {
            println("note: cross-compiling for ${target}, but these target libraries were not found:")
            for (file in missing) {
                println("  missing .sdl3/${file} (only needed to cross-link executables)")
            }
            println("      point $SDL3_LIB_DIR at an extracted release of the target platform.")
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
func provisionLibrary(dest: String, searched: ArrayList<String>, name: String, kind: String): Bool {
    let target = "${dest}/${libraryFileName(kind, name)}"
    if (isRealFile(target)) {
        return true
    }
    match (locateLibrary(searched, name, exactLibraryNames(kind, name), libraryPatterns(kind, name))) {
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

// Returns the real file of the first usable hit across the search path; a hit
// that does not resolve (e.g. a dangling symlink) is skipped, not fatal.
func locateLibrary(searched: ArrayList<String>, name: String, exacts: Array<String>,
    patterns: Array<(String, String)>): Option<String> {
    for (dir in searched) {
        if (let Some(source) <- findInDirectory(dir, exacts, patterns)) {
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
func findInDirectory(dir: String, exacts: Array<String>, patterns: Array<(String, String)>): Option<String> {
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

// Platform kinds: "linux", "windows", "macos".

@When[os == "Linux"]
func hostKind(): String {
    "linux"
}

@When[os == "Windows"]
func hostKind(): String {
    "windows"
}

@When[os == "macOS"]
func hostKind(): String {
    "macos"
}

@When[os != "Linux" && os != "Windows" && os != "macOS"]
func hostKind(): String {
    ""
}

// cjpm compiles build scripts as host binaries and passes no target argument;
// for cross builds the target triple only shows up in the script's own cache
// path: <project>/build-script-cache/<triple>/<mode>/<module>/bin/build-script.
// Native builds have <mode> directly after the cache directory.
func targetKind(): String {
    let arguments = getCommandLine()
    if (arguments.isEmpty()) {
        return hostKind()
    }
    let self = arguments[0].replace("\\", "/")
    let marker = "/build-script-cache/"
    var index = -1
    if (let Some(value) <- self.indexOf(marker)) {
        index = value
    }
    if (index < 0) {
        return hostKind()
    }
    let rest = self[index + marker.size..self.size]
    var separator = -1
    if (let Some(value) <- rest.indexOf("/")) {
        separator = value
    }
    let segment = if (separator >= 0) {
        rest[0..separator]
    } else {
        rest
    }
    if (segment.contains("windows")) {
        "windows"
    } else if (segment.contains("darwin") || segment.contains("macos")) {
        "macos"
    } else if (segment.contains("linux")) {
        "linux"
    } else {
        hostKind()
    }
}

// File name a library must have for cjpm to accept and link it.
func libraryFileName(kind: String, name: String): String {
    match (kind) {
        case "linux" => "lib${name}.so"
        case "windows" => "${name}.dll"
        case "macos" => "lib${name}.dylib"
        case _ => ""
    }
}

// File names that can be used verbatim as the link-time library.
func exactLibraryNames(kind: String, name: String): Array<String> {
    match (kind) {
        case "linux" => ["lib${name}.so"]
        case "windows" => ["${name}.dll", "lib${name}.dll"]
        case "macos" => ["lib${name}.dylib"]
        case _ => []
    }
}

// (prefix, suffix) pairs for versioned/renamed variants, e.g. the SONAME
// files of a distro package, mingw-w64's libSDL3-0.dll, or the versioned
// dylibs inside an official macOS dmg.
func libraryPatterns(kind: String, name: String): Array<(String, String)> {
    match (kind) {
        case "linux" => [("lib${name}.so.", "")]
        case "windows" => [("${name}-", ".dll"), ("lib${name}-", ".dll"), ("${name}.", ".dll")]
        case "macos" => [("lib${name}.", ".dylib")]
        case _ => []
    }
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
