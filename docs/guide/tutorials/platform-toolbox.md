# 构建平台诊断工具

## 你将完成

本教程构建一个不打开窗口的命令行诊断工具，打印 SDL 识别的平台、CPU 核心与内存、首选项目录、当前日期和电源信息。它用输出和退出码验证 `sdl.system`，适合在 GUI 启动失败前缩小问题，也可作为部署后的环境报告。程序完整包含包、导入和 `main`，并正确处理路径、电量等可能不存在的值。

## 开始之前

你需要能够构建依赖 SDL 的仓颉项目，但不要求当前会话能显示窗口。`sdl.system` 的某些函数仍会调用 SDL 原生库，因此 Windows 运行时 DLL 仍须可加载。预计复制和运行约十分钟。输出中的平台名、目录、电量和核心数依机器而异，确认标准是字段有合理形式，而不是和文档示例逐字相同。

## 先建立一个模型

平台信息分三类。稳定身份如平台名和 CPU 能力适合启动时记录；路径由进程位置、当前工作目录和用户配置决定，不能硬编码；电源和当前时间是瞬时快照，需要在真正决策前重新读取。返回 `Option` 的 API 明确表示平台可能不给结果，调用方应保留“不可知”，不要把它伪装成空字符串或 0%。

这个探针不创建 `SdlWindow`，因此不能证明显示器、字体和真实渲染可用；它只证明系统包、动态库和若干平台查询能运行。后续测试应把“系统探针”“无窗口渲染逻辑”和“真实 GUI 截图”分开记录。

## 操作步骤

1. 在已配置 SDL 依赖的可执行项目中，把下面程序保存为 `src/main.cj`。
2. 运行 `cjpm run` 并保存完整输出与退出码。不要只截取最后一行。
3. 检查首选项目录是否非空，CPU 核心和内存是否大于零，日期是否合理。
4. 若某个可选值是 `None`，记录“平台未提供”，不要把整个探针判为失败。

## 完整程序

```cangjie verify role=complete
package guide_examples

import sdl.system.{ApplicationPaths, Time, cpuInfo, platformName, powerInfo}

main(): Unit {
    println("platform=${platformName()}")
    let cpu = cpuInfo()
    println("logicalCores=${cpu.logicalCores}")
    println("systemRamMb=${cpu.systemRamMb}")

    let preferences = ApplicationPaths.preferencePath("GuideLab", "SdlProbe")
    println("preferences=${preferences}")
    match (ApplicationPaths.basePath()) {
        case Some(path) => println("base=${path}")
        case None => println("base=<unavailable>")
    }

    let now = Time.currentDateTime()
    println("date=${now.year}-${now.month}-${now.day}")
    let power = powerInfo()
    match (power.percent) {
        case Some(percent) => println("battery=${percent}%")
        case None => println("battery=<unknown>")
    }
}
```

首选项目录调用会按组织名和应用名得到可写目录，并确保目录存在，因此它既是查询也是一次受控的目录准备。不要用 `currentDirectory` 代替它存配置：用户从不同目录启动同一程序时，当前目录会变化。

## 确认结果

命令应以退出码 0 结束，并打印平台、逻辑核心数、系统内存、首选目录、程序目录、日期和电量七项。核心数与内存应大于零；首选目录非空；日期年份合理。

程序目录或电量显示“不可用/未知”是受支持的结果。验证记录应保存实际命令和可观察输出；本页没有 GUI，因此不制造无意义截图。

## 接着试一试

加入性能计时，测量一次短延时的实际经过时间。它使用单调性能计数器，不受用户调整系统时钟影响；这与 `Time.currentDateTime()` 的业务时间用途不同。

```cangjie role=variation
import sdl.system.PerformanceClock

let started = PerformanceClock.counter()
PerformanceClock.delayNanoseconds(PerformanceClock.millisecondsToNanoseconds(UInt64(5)))
let elapsed = PerformanceClock.counter() - started
let seconds = Float64(elapsed) / Float64(PerformanceClock.frequency())
println("delaySeconds=${seconds}")
```

确认结果大于零且大致接近 0.005 秒，但不要要求精确等于；操作系统调度会增加等待时间。这个变化为后面的帧耗时统计提供近迁移练习。

## 如果没有成功

动态库加载失败说明系统探针也跨越了原生边界，转到[部署](../how-to/deploy-native-runtime.md)检查 DLL。`preferencePath` 失败时确认组织名和应用名非空，并记录 `CuiException` 完整信息。CPU 或平台字段异常时先运行最小的 `platformName()` 探针，再逐项加回。电量未知不属于错误；台式机、虚拟机和部分驱动本来可能不报告。

## 相关 API

- [`sdl.system` 函数](../../api/sdl/system/functions.md)：平台、CPU、电源与打开 URL。
- [`ApplicationPaths`](../../api/sdl/system/ApplicationPaths.md)：程序、当前、首选项与用户目录。
- [`Time`](../../api/sdl/system/Time.md)：当前时间、日历拆分与区域偏好。
- [`PowerInfo`](../../api/sdl/system/PowerInfo.md)：供电状态和可选剩余信息。

## 下一步

继续[文字度量与缓存](../concepts/text-font-cache.md)，理解为什么系统探针成功仍不等于字体和真实 GUI 已验证。
