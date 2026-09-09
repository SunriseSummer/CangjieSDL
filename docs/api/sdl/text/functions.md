# sdl.text 字素边界函数

### graphemeByteBoundaries

```cangjie
public func graphemeByteBoundaries(text: String): Array<Int64>
```

返回 Unicode 17 扩展字素的 UTF-8 字节边界，包括开头 `0` 和文本结尾。空字符串返回 `[0]`。不修改文本、不规范化换行；CRLF、组合字符、Emoji 肤色与 ZWJ 序列按完整字素处理。可用相邻两个边界截取一个可编辑单元。

### graphemeRuneBoundaries

```cangjie
public func graphemeRuneBoundaries(runes: Array<Rune>): Array<Int64>
```

规则与前一函数相同，但返回 Rune 数组下标，结尾为 `runes.size`；不是 UTF-8 字节下标。两个函数都按输入长度线性处理，结果空间与字素数量成正比。

```cangjie verify
package docexample

import sdl.text.{graphemeByteBoundaries, graphemeRuneBoundaries}

main(): Unit {
    let text = "👩🏽‍💻"
    println(graphemeByteBoundaries(text)) // [0, 15]，一个完整表情
    println(graphemeRuneBoundaries(text.toRuneArray())) // [0, 4]
    println(graphemeByteBoundaries("👩🏽 💻")) // [0, 8, 9, 13]，表情、空格、表情
}
```
