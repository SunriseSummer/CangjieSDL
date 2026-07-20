[sdl](../../index.md) › sdl.system

# sdl.system

```cangjie
import sdl.system.*
```

应用元数据、路径与文件系统、SDL hint、时钟与日历时间、平台与电源信息。本包的设施大多不依赖窗口与视频子系统，可在应用启动最早期使用（元数据与 hint 正应如此——须在子系统初始化前设置）。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`ApplicationMetadata`](ApplicationMetadata.md) | 应用元数据的写入与查询入口。 |
| [`ApplicationPaths`](ApplicationPaths.md) | 应用相关目录的查询入口：可执行文件所在目录、当前目录、按组织/应用名生成的首选项目录，以及标准用户目录。 |
| [`FileSystem`](FileSystem.md) | SDL 文件系统操作的入口：建目录、删除、改名、复制、查询，以及按通配模式列出目录。 |
| [`PerformanceClock`](PerformanceClock.md) | 单调高精度计时：毫秒/纳秒计时、性能计数器与高精度延时。 |
| [`SdlHints`](SdlHints.md) | SDL hint 的读写入口。 |
| [`Time`](Time.md) | 系统实时钟与日历换算：读取当前时间（1970-01-01 UTC 起算的纳秒），在纳秒时间戳与 `DateTimeParts` 之间互转，查询每月天数、一年中的第几天和星期，以及与 Windows FILETIME 互转。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`AppMetadata`](AppMetadata.md) | 一组应用元数据：名称、版本、标识符、开发者、版权、主页与类别，全部可选。 |
| [`CpuInfo`](CpuInfo.md) | CPU 与内存能力快照：核心数、缓存行、内存与页大小，以及各 SIMD 指令集的可用性。 |
| [`DateTimeLocalePreferences`](DateTimeLocalePreferences.md) | 系统区域的日期时间显示偏好：日期字段顺序与报时制式。 |
| [`DateTimeParts`](DateTimeParts.md) | 拆解后的日历时间：年月日、时分秒、纳秒、星期与 UTC 偏移。 |
| [`PathInfo`](PathInfo.md) | 一个路径的元信息：条目种类、字节大小与创建/修改/访问三组时间戳（SDL 时间，纳秒）。 |
| [`PowerInfo`](PowerInfo.md) | 电源信息快照：供电状态、剩余秒数与剩余百分比；系统无法给出的项为 `None`。 |
| [`SdlHintSetting`](SdlHintSetting.md) | 一条完整的 hint 设置：hint 名、值与优先级，供 `SdlHints.apply` 批量应用。 |
| [`WindowsFileTime`](WindowsFileTime.md) | Windows FILETIME 的高低 32 位组合（1601-01-01 起算的 100 纳秒滴答），与 SDL 时间互转时使用。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`AppMetadataProperty`](AppMetadataProperty.md) | 可单独读写的应用元数据属性名；`CustomMetadataProperty` 携带任意 SDL 属性名。 |
| [`AppMetadataType`](AppMetadataType.md) | 应用类别元数据的取值：普通应用、游戏、媒体播放器，或自定义字符串。 |
| [`ClockFormat`](ClockFormat.md) | 系统区域偏好的报时制式；SDL 报告未识别的编码时以 `UnknownClockFormat` 携带原始值。 |
| [`DateFormat`](DateFormat.md) | 系统区域偏好的日期字段顺序；SDL 报告未识别的编码时以 `UnknownDateFormat` 携带原始值。 |
| [`FileSystemEntryType`](FileSystemEntryType.md) | 文件系统条目的种类，出现在 `PathInfo.entryType` 中。 |
| [`HintPriority`](HintPriority.md) | 设置 SDL hint 时的优先级；高优先级覆盖低优先级已写入的值。 |
| [`PowerState`](PowerState.md) | 设备的供电状态，出现在 `PowerInfo.state` 中。 |
| [`SdlHint`](SdlHint.md) | 常用 SDL hint 的名称；`CustomHint` 携带任意 SDL hint 名。 |
| [`UserFolder`](UserFolder.md) | 操作系统的标准用户目录，交给 `ApplicationPaths.userFolder` 解析为具体路径。 |
| [`Weekday`](Weekday.md) | 星期几，周日起算，由 `Time.dayOfWeek` 与 `DateTimeParts.dayOfWeek` 使用。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`platformName`](functions.md#platformname) | 返回运行平台的名称（如 `"Windows"`、`"Linux"`、`"macOS"`）；SDL 未返回时为 `"Unknown"`。 |
| [`cpuInfo`](functions.md#cpuinfo) | 查询 CPU 与内存能力快照：核心数、缓存行、内存、页大小与各 SIMD 指令集可用性。 |
| [`powerInfo`](functions.md#powerinfo) | 查询电源信息：供电状态、剩余秒数与剩余百分比（不可知的项为 `None`）。 |
| [`openUrl`](functions.md#openurl) | 请求操作系统用默认处理程序打开 URL（`https://` 开浏览器，`file://` 开文件管理器等）。 |
