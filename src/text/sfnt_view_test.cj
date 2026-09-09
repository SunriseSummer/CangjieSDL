package sdl.text

import std.env.getVariable
import std.fs.{exists, Directory, copy, remove}
import std.runtime.gc

private func viewTestSource(): String {
    getVariable("LOCALAPPDATA").getOrDefault({=> ""}) + "/Microsoft/Windows/Fonts/CascadiaCode.ttf"
}

@Test
func refreshedFontFileDoesNotReuseTheMappingPinnedByAnOldSession(): Unit {
    let first = viewTestSource()
    let second = getVariable("WINDIR").getOrDefault({=> "C:/Windows"}) + "/Fonts/bahnschrift.ttf"
    if (!exists(first) || !exists(second)) { return }
    let directory = Directory.createTemp(".").toString()
    let path = directory + "/replace.ttf"
    copy(first, to: path)
    @Expect(unsafe { TTF_Init() })
    let baseline = activeFontStreams()
    var oldFont = CPointer<Unit>(); var oldStream = CPointer<Unit>()
    var newFont = CPointer<Unit>(); var newStream = CPointer<Unit>()
    try {
        let source = NativeFontSource(path, 0, coordinates: [NativeFontCoordinate("wght", 479.25)])
        (oldFont, oldStream) = openVariableNativeFont(source, 20.0)
        @Expect(unsafe { TTF_GetFontFamilyName(oldFont) }.toString(), "Cascadia Code")
        remove(path)
        copy(second, to: path)
        forgetNativeFontMetadata(path)
        (newFont, newStream) = openVariableNativeFont(source, 20.0)
        @Expect(unsafe { TTF_GetFontFamilyName(newFont) }.toString(), "Bahnschrift")
        @Expect(unsafe { TTF_GetFontFamilyName(oldFont) }.toString(), "Cascadia Code")
        @Expect(activeFontStreams(), baseline + 2)
    } finally {
        if (newFont.isNotNull()) { unsafe { TTF_CloseFont(newFont) } }
        if (oldFont.isNotNull()) { unsafe { TTF_CloseFont(oldFont) } }
        let _ = closeFontView(newStream); let _ = closeFontView(oldStream)
        @Expect(activeFontStreams(), baseline)
        unsafe { TTF_Quit() }
        forgetNativeFontMetadata(path)
        if (exists(path)) { remove(path) }; remove(directory)
    }
}

@Test
func variableCoordinatesRemainStableAcrossCollectionAndRepeatedReopening(): Unit {
    let path = viewTestSource()
    if (!exists(path)) { return }
    @Expect(unsafe { TTF_Init() })
    let before = activeFontStreams()
    try {
        for (iteration in 0..64) {
            let source = NativeFontSource(path, 0, coordinates: [NativeFontCoordinate("wght", 479.25 + Float32(iteration))])
            let metadata = sfntSourceInfo(source)
            gc(heavy: true)
            let (font, stream) = openVariableNativeFont(source, 24.0)
            try {
                @Expect(font.isNotNull())
                @Expect(metadata.coordinates[0].tagCode, AXIS_WEIGHT)
            } finally { unsafe { TTF_CloseFont(font) }; let _ = closeFontView(stream) }
        }
        @Expect(activeFontStreams(), before)
    } finally { unsafe { TTF_Quit() } }
}

@Test
func variableFontViewUsesSmallPatchesAndReleasesItsStream(): Unit {
    let path = viewTestSource()
    if (!exists(path)) { return }
    let source = NativeFontSource(path, 0, coordinates: [NativeFontCoordinate("wght", 479.25)])
    let metadata = sfntSourceInfo(source)
    let view = SfntView(source, metadata)
    @Expect(view.patchBytes < 8192)
    @Expect(view.length > view.patchBytes * 100)
    let before = activeFontStreams()
    @Expect(unsafe { TTF_Init() })
    try {
        let (font, stream) = openVariableNativeFont(source, 20.0)
        @Expect(font.isNotNull() && stream.isNotNull())
        @Expect(activeFontStreams(), before + 1)
        try {
            let text = unsafe { LibC.mallocCString("AV office ffi") }
            try (resource = text.asResource()) {
                var width: Int32 = 0; var height: Int32 = 0
                @Expect(unsafe { TTF_GetStringSize(font, resource.value, 13, inout width, inout height) })
                @Expect(width > 0 && height > 0)
            }
        } finally { unsafe { TTF_CloseFont(font) }; let _ = closeFontView(stream) }
        @Expect(activeFontStreams(), before)
    } finally { unsafe { TTF_Quit() } }
}

@Test
func virtualFontStreamSupportsRandomReadsEofAndValidChecksums(): Unit {
    let path = viewTestSource()
    if (!exists(path)) { return }
    let source = NativeFontSource(path, 0, coordinates: [NativeFontCoordinate("wght", 479.25)])
    let view = SfntView(source, sfntSourceInfo(source))
    let stream = openFontView(path, view)
    let buffer = unsafe { LibC.malloc<UInt8>(count: 4096) }
    try {
        @Expect(buffer.isNotNull())
        if (buffer.isNull()) { return }
        var checksum: UInt64 = 0
        let streamLength = unsafe { SDL_GetIOSize(stream) }
        @Expect(streamLength > 0)
        var remaining = streamLength
        while (remaining > 0) {
            let size = min(4096, remaining)
            @Expect(unsafe { SDL_ReadIO(stream, CPointer<Unit>(buffer), UIntNative(size)) }, UIntNative(size))
            let bytes = Array<UInt8>(size) {i => unsafe { buffer.read(i) }}
            checksum = (checksum + UInt64(sfntChecksum(bytes))) & 0xFFFFFFFF
            remaining -= size
        }
        @Expect(checksum, UInt64(0xB1B0AFBA))
        @Expect(unsafe { SDL_ReadIO(stream, CPointer<Unit>(buffer), 1) }, UIntNative(0))
        // Stock SDL memory streams clamp an absolute negative seek to the beginning.
        @Expect(unsafe { SDL_SeekIO(stream, -1, 0) }, Int64(0))
        @Expect(unsafe { SDL_SeekIO(stream, 0, 0) }, Int64(0))
        @Expect(unsafe { SDL_ReadIO(stream, CPointer<Unit>(buffer), 4) }, UIntNative(4))
        @Expect(unsafe { buffer.read(1) }, UInt8(1))
        @Expect(unsafe { SDL_SeekIO(stream, -4, 2) }, streamLength - 4)
        @Expect(unsafe { SDL_ReadIO(stream, CPointer<Unit>(buffer), 8) }, UIntNative(4))
    } finally { let _ = closeFontView(stream); unsafe { LibC.free(buffer) } }
}
