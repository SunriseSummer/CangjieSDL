package sdl.text

import std.fs.exists
import std.sort.sort
import std.runtime.gc

@Test
func sfntDirectoryCopiesRemainStableDuringAllocationAndCollection(): Unit {
    let path = "C:/Windows/Fonts/seguiemj.ttf"
    if (!exists(path)) { return }
    let reader = SfntReader(path)
    let retained = Array<Array<SfntTable>>(8, { _ => [] })
    try {
        let expected = reader.tables(0)[1]
        sort<SfntTable, UInt32>(expected, key: { table => table.tagCode })
        for (iteration in 0..600) {
            let tables = reader.tables(0)[1]
            sort<SfntTable, UInt32>(tables, key: { table => table.tagCode })
            retained[iteration % retained.size] = tables
            if (iteration % 47 == 0) { gc(heavy: true) }
            @Assert(tables.size, expected.size)
            for (i in 0..tables.size) {
                @Expect(tables[i].tagCode, expected[i].tagCode)
                @Expect(tables[i].checksum, expected[i].checksum)
                @Expect(tables[i].offset, expected[i].offset)
                @Expect(tables[i].length, expected[i].length)
            }
        }
    } finally { reader.file.close() }
    for (tables in retained) { @Expect(!tables.isEmpty()) }
}

@Test
func numericTableTagsPreserveAsciiValidation(): Unit {
    @Expect(sfntTagCode([0x43, 0x4F, 0x4C, 0x52], 0), UInt32(0x434F4C52))
    let invalid: Array<Array<UInt8>> = [[0x43, 0, 0x4C, 0x52], [0x43, 0xFF, 0x4C, 0x52], [0x43, 0x4F, 0x4C]]
    for (bytes in invalid) {
        var rejected = false
        try { let _ = sfntTagCode(bytes, 0) } catch (_: NativeTextException) { rejected = true }
        @Expect(rejected)
    }
}
