[sdl](../../index.md) › sdl.text

# sdl.text

Unicode 17.0.0 扩展字素分段。这里的函数只处理文本，不初始化 SDL、不打开字体，调用间没有共享的可变状态。

详细签名与示例见[字素边界函数](functions.md)。CangjieGUI 的编辑、选择和换行与 CangjieSDL 的 Emoji 后备使用同一套规则。

| 函数 | 返回的索引 |
|---|---|
| [`graphemeByteBoundaries`](functions.md#graphemebyteboundaries) | UTF-8 字节偏移 |
| [`graphemeRuneBoundaries`](functions.md#graphemeruneboundaries) | Rune 数组下标 |
