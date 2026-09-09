[sdl](index.md) › FontCacheStats

# FontCacheStats

渲染器字体缓存诊断。fontConfigurations 不包含由存活测量会话单独保留的已淘汰配置；textTextureBytes 是整段文字纹理的 RGBA 估算字节；textRasterizations 是累计整段栅格化次数。

glyphAtlasBytes 是仓颉文字引擎当前字形图集的 RGBA 字节数，上限 16 MiB；cachedGlyphs 是缓存字形数量（含装饰线白色像素）；glyphAtlasEvictions 是累计图集页淘汰次数。图集与整段文字纹理分别计费，均不包含驱动、FreeType 内部对象和临时上传缓冲。

textTextures 按实际缓存的 GPU 纹理块计数；超长文字可能占多个块，textTextureBytes 包含分块的采样边缘。单次 CPU Surface 栅格化峰值不计入该缓存统计。

## 声明与成员

```cangjie
public struct FontCacheStats
public let fontConfigurations: Int64
public let textTextures: Int64
public let textTextureBytes: Int64
public let textRasterizations: UInt64
public let glyphAtlasBytes: Int64
public let cachedGlyphs: Int64
public let glyphAtlasEvictions: UInt64
public init(fontConfigurations: Int64, textTextures: Int64, textTextureBytes: Int64, textRasterizations: UInt64,
    glyphAtlasBytes!: Int64 = 0, cachedGlyphs!: Int64 = 0, glyphAtlasEvictions!: UInt64 = 0)
```

通过 [`Fonts`](Fonts.md)、[`Renderer`](Renderer.md) 使用；完整流程见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。
