# 使用系统信息、时间与电源状态

## 目标

基于[平台诊断工具](../tutorials/platform-toolbox.md)，同时使用日历时间、高精度性能计数器和电源快照：日志显示本地日期，性能统计使用单调计数器，耗电工作在电量低或状态未知时采用保守策略。完成后不会用系统时钟计算运动，也不会把未知电量误写成 0%。

## 适用场景

适用于日志时间戳、存档日期、帧耗时、基准测量、后台任务限速和便携设备省电。业务时间与性能时间目的不同：`Time` 可在本地/UTC、Windows FILETIME 与日历部件间转换；`PerformanceClock` 测量经过时长；`powerInfo` 是瞬时设备快照。

## 准备工作

保留平台探针的完整 `main`，在输出后加入计时和策略函数。测试不要断言当前年份等于固定值，也不要断言所有机器都有电池。性能测试先预热，记录多次结果，并避免把一次操作系统调度抖动当回归。

## 操作步骤

下面片段分别打印本地日期与区域偏好，测量 5ms 延时，并根据电量决定是否启用高成本背景效果。`percent` 为 None 时选择保守但不报错。

```cangjie role=patch
let now = Time.currentDateTime(local: true)
let locale = Time.localePreferences()
println("date=${now.year}-${now.month}-${now.day}, format=${locale.dateFormat}")

let started = PerformanceClock.counter()
PerformanceClock.delayNanoseconds(PerformanceClock.millisecondsToNanoseconds(UInt64(5)))
let elapsed = PerformanceClock.counter() - started
let elapsedSeconds = Float64(elapsed) / Float64(PerformanceClock.frequency())
println("elapsedSeconds=${elapsedSeconds}")

let power = powerInfo()
let allowExpensiveEffects = match (power.percent) {
    case Some(percent) => percent >= 20
    case None => false
}
println("expensiveEffects=${allowExpensiveEffects}")
```

游戏帧循环只需要经过时间，可继续使用 `window.ticks()`；需要分析 update 与 draw 微秒级耗时时再用 PerformanceClock。用户界面展示时间时根据 `localePreferences` 选择顺序和 12/24 小时格式，不硬编码某一地区习惯。

## 确认结果

程序退出码为 0，日期字段处于合法范围，5ms 延时测得值大于 0 且通常不少于目标值。台式机可能输出电量未知，此时 `expensiveEffects=false` 是设计结果；笔记本有电量时阈值逻辑符合数值。将系统时钟调整不应影响 PerformanceClock 两次计数差。记录实际平台、计数频率和测量结果，避免不同机器直接比较绝对耗时。

## 常见错误

用 `Time.currentNanoseconds()` 驱动运动可能受墙钟调整；把 `delayPrecise` 用于普通等待会增加 CPU；把一次短基准当稳定性能结论会受调度影响。日期转换的 local 参数必须明确，存储通常用 UTC、显示再转本地。`daysInMonth`、`dayOfWeek` 对非法日期会抛出异常，外部输入先校验。

## 可以继续修改

把 DateTimeParts 转为纳秒，再转回 UTC，检查关键字段保持一致。这个变化验证转换路径而不是只读取当前时间。

```cangjie role=variation
let localNow = Time.currentDateTime(local: true)
let encoded = Time.toNanoseconds(localNow)
let utc = Time.toDateTime(encoded, local: false)
println("localOffset=${localNow.utcOffset}, utcOffset=${utc.utcOffset}")
println("weekday=${Time.dayOfWeek(localNow.year, localNow.month, localNow.day)}")
```

## 相关 API

- [`Time`](../../api/sdl/system/Time.md)：墙钟、日历与格式偏好。
- [`DateTimeParts`](../../api/sdl/system/DateTimeParts.md)：拆分时间值。
- [`PerformanceClock`](../../api/sdl/system/PerformanceClock.md)：单调计数与延时。
- [`PowerInfo`](../../api/sdl/system/PowerInfo.md) 与[系统函数](../../api/sdl/system/functions.md)：电源、CPU 和平台。

## 下一步

继续[部署原生运行库](deploy-native-runtime.md)，把本机可运行状态变成干净目录中仍可复现的交付。
