[sdl](index.md) › Fonts

# Fonts

主线程访问的应用字体注册表和系统字体目录。显式注册优先，系统名称采用 ASCII 大小写不敏感匹配；平台提供的本地化别名也可使用。系统字体并不计入 names、isRegistered、familyFor 等应用注册查询。

setDefault(None) 恢复系统 UI 角色；setFallbacks 配置全局缺字/随附字体回退，也用于无系统字体环境的引导。setSearchDirectories 增加应用发现目录并刷新缓存，不替代系统目录。传入和返回的数组相互独立。

系统服务使用 Windows 系统设置及 DirectWrite、Linux fontconfig、macOS CoreText。默认角色、指定族名、registerSystem 和 familyFaces 只解析所需字体；未知名称不会触发全量系统扫描。systemFamilyNames、systemFonts、systemFontWarnings 显式加载完整目录，适合字体选择器。启动仅复用已经显式加载的目录，不因定向查找失败而全量扫描。仅支持可访问的文件字体，私有内存/远程字体、系统逐字符 fallback 和安装通知不在此接口范围内。

refreshSystemFonts 清除平台匹配、目录及文件元数据缓存并推进 revision，下次按需查询；reload 等同于 refreshSystemFonts(force: true)，包括强制失效持久元数据缓存，调用本身不扫描目录。重新注册同名文件也会重试之前的失败加载。已注册系统别名保留原文件位置，刷新后按需重读这些文件的元数据；若字体安装位置改变，重新 registerSystem。clear 清除应用注册、默认、全局回退和附加目录。存活测量会话保留原有字体图；替换字体文件前应关闭会话并 renderer.reloadFonts()，替换后调用 Fonts.reload()。

supportsVariations 查询官方 SDL_ttf 3.2+ 的支持版本。字体元数据、平台匹配和变量坐标处理均由仓颉代码实现，无需扩展 DLL 或修改 SDL_ttf。优先复用已有命名实例；任意坐标通过微小的虚拟 SFNT 数据表和公开 IOStream/face-index 接口打开，原字体文件不变，也不按坐标复制整份字库。显式未知或越界坐标报错。

## 声明与成员

```cangjie
public class Fonts
public static func setMetadataCache(path: ?String): Unit
public static func metadataCache(): ?String
public static func register(name: String, path: String): Unit
public static func registerFamily(name: String, primaryPath: String, fallbackPaths!: Array<String> = []): Unit
public static func registerFamily(name: String, family: FontFamily): Unit
public static func familyFor(name: String): ?FontFamily
public static func familyFaces(name: String): Array<InstalledFontFace>
public static func setSearchDirectories(directories: Array<String>): Unit
public static func searchDirectories(): Array<String>
public static func systemFamilyNames(): Array<String>
public static func systemFonts(): Array<InstalledFontFace>
public static func systemFontWarnings(): Array<String>
public static func registerSystem(name: String, familyName: String): Bool
public static func refreshSystemFonts(force!: Bool = false): Unit
public static func pathFor(name: String): ?String
public static func fallbackPathsFor(name: String): Array<String>
public static func isRegistered(name: String): Bool
public static func unregister(name: String): Unit
public static func clear(): Unit
public static func setFallbacks(sources: Array<FontSource>): Unit
public static func fallbacks(): Array<FontSource>
public static func setDefault(name: ?String): Unit
public static func defaultFamily(): ?String
public static func reload(): Unit
public static func revision(): UInt64
public static func names(): Array<String>
public static func supportsVariations(): Bool
```

参见[字体配置与绘制](../../guide/how-to/text-and-fonts.md)。

## 持久元数据缓存

setMetadataCache(path) 启用应用管理的可选目录元数据缓存，默认关闭，父目录需提前创建。显式枚举目录时仍检查文件大小和修改时间，命中则跳过 SFNT 元数据读取；缓存损坏、文件变化或缓存格式升级时重建。refreshSystemFonts(force: true) 包括同大小同时间戳替换等情况。日常定向匹配另有 8 MiB／512 文件的内存元数据缓存和 512 项失败路径缓存，不进行每帧文件检查；替换文件后须 reload 或重新注册。缓存不是字体文件或渲染结果的替代品，持久缓存写入失败仅记入 systemFontWarnings。

资源与输入上限见[文本与字体缓存](../../guide/concepts/text-font-cache.md)。常规启动和按族名查询不建立完整目录；`familyFaces(name)` 适合按需显示所选字体的样式和设计轴。
