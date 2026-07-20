[sdl](../../index.md) › [sdl.system](index.md) › 函数

# 函数 — sdl.system

`sdl.system` 包的包级函数。`openUrl` 在 SDL 无法把请求交给系统默认处理程序时，将失败状态转换为 `CuiException`。

### platformName

返回运行平台的名称（如 `"Windows"`、`"Linux"`、`"macOS"`）；SDL 未返回时为 `"Unknown"`。

```cangjie
public func platformName(): String
```

**返回值** `String` — 平台名。

### cpuInfo

查询 CPU 与内存能力快照：核心数、缓存行、内存、页大小与各 SIMD 指令集可用性。

```cangjie
public func cpuInfo(): CpuInfo
```

**返回值** `CpuInfo` — 填充完毕的能力快照。

### powerInfo

查询电源信息：供电状态、剩余秒数与剩余百分比（不可知的项为 `None`）。

```cangjie
public func powerInfo(): PowerInfo
```

**返回值** `PowerInfo` — 电源快照。

### openUrl

请求操作系统用默认处理程序打开 URL（`https://` 开浏览器，`file://` 开文件管理器等）。调用是异步移交——返回不代表打开成功完成。

```cangjie
public func openUrl(url: String): Unit
```

**参数**

- `url`: `String` — 要打开的 URL。

**异常**

- `CuiException` — SDL 无法发起打开请求时。
