[sdl](index.md) › FontResolution

# FontResolution

解析快照：requestedFamily、requestedWeight、实际 faces 和 warnings。faces[0] 是主字体；近似/范围钳制、加载失败或未知族可从结果识别。headless 的 faces 为空。

## 声明与成员

```cangjie
public struct FontResolution
public let requestedWeight: FontWeight
public let requestedFamily: ?String
public let faces: Array<ResolvedFontFace>
public let warnings: Array<String>
public init(requestedFamily: ?String, faces: Array<ResolvedFontFace>, warnings: Array<String>,
        requestedWeight!: FontWeight = FontWeight.normal)
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
