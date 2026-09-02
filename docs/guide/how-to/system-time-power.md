# 使用系统信息、时间与电源状态

## 目标

基于[平台诊断工具](../tutorials/platform-toolbox.md)，同时使用日历时间、高精度性能计数器和电源快照：日志显示本地日期，性能统计使用单调计数器，耗电工作在电量低或状态未知时采用保守策略。完成后不会用系统时钟计算运动，也不会把未知电量误写成 0%。

## 适用场景

适用于日志时间戳、存档日期、帧耗时、基准测量、后台任务限速和便携设备省电。业务时间与性能时间目的不同：`Time` 可在本地/UTC、Windows FILETIME 与日历部件间转换；`PerformanceClock` 测量经过时长；`powerInfo` 是瞬时设备快照。

## 准备工作

保留平台探针的完整 `main`，在输出后加入计时和策略函数。测试不要断言当前年份等于固定值，也不要断言所有机器都有电池。性能测试先预热，记录多次结果，并避免把一次操作系统调度抖动当回归。

## 操作步骤

用 `Time.currentDateTime(local: true)` 和 `Time.localePreferences()` 显示本地日期与区域格式。性能测量先读取 `PerformanceClock.counter()`，执行工作后再次读取，并除以 `PerformanceClock.frequency()` 得到秒数。电源策略匹配 `powerInfo().percent`：有值时比较阈值，`None` 时采用保守策略，但不要把未知显示成 0%。[平台诊断工具](../tutorials/platform-toolbox.md)包含可独立编译的完整程序。

游戏帧循环只需要经过时间，可继续使用 `window.ticks()`；需要分析 update 与 draw 微秒级耗时时再用 PerformanceClock。用户界面展示时间时根据 `localePreferences` 选择顺序和 12/24 小时格式，不硬编码某一地区习惯。

## 确认结果

程序退出码为 0，日期字段处于合法范围，5ms 延时测得值大于 0 且通常不少于目标值。台式机可能输出电量未知，此时 `expensiveEffects=false` 是设计结果；笔记本有电量时阈值逻辑符合数值。将系统时钟调整不应影响 PerformanceClock 两次计数差。记录实际平台、计数频率和测量结果，避免不同机器直接比较绝对耗时。

## 常见错误

用 `Time.currentNanoseconds()` 驱动运动可能受墙钟调整；把 `delayPrecise` 用于普通等待会增加 CPU；把一次短基准当稳定性能结论会受调度影响。日期转换的 local 参数必须明确，存储通常用 UTC、显示再转本地。`daysInMonth`、`dayOfWeek` 对非法日期会抛出异常，外部输入先校验。

## 可以继续修改

把 `Time.currentDateTime(local: true)` 得到的 `DateTimeParts` 传给 `Time.toNanoseconds`，再用 `Time.toDateTime(..., local: false)` 转为 UTC。比较两者的偏移，并用 `Time.dayOfWeek` 验证日期。外部日期进入这些函数前必须先检查范围。

## 相关 API

- [`Time`](../../api/sdl/system/Time.md)：墙钟、日历与格式偏好。
- [`DateTimeParts`](../../api/sdl/system/DateTimeParts.md)：拆分时间值。
- [`PerformanceClock`](../../api/sdl/system/PerformanceClock.md)：单调计数与延时。
- [`PowerInfo`](../../api/sdl/system/PowerInfo.md) 与[系统函数](../../api/sdl/system/functions.md)：电源、CPU 和平台。

## 下一步

继续[部署原生运行库](deploy-native-runtime.md)，把本机可运行状态变成干净目录中仍可复现的交付。
