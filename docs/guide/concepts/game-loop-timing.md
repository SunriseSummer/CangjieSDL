# 时间步长与游戏循环

## 先用一句话说明

实时程序用相邻帧的单调时钟差得到秒数 `dt`，以“单位每秒”的速度更新，并限制异常长帧，再按事件、模拟、碰撞、渲染和提交的稳定顺序运行。

## 为什么重要

进入本页前应理解[输入事件与持续状态](input-state.md)以及[场景、逻辑坐标与高 DPI](render-scene-coordinates.md)：前者提供跨帧输入，后者保证运动与绘制处于同一逻辑空间。

如果每帧固定移动 4 像素，60Hz 时每秒 240 像素，144Hz 时则达到 576 像素；垂直同步设置会直接改变游戏速度。使用 `speed * dt` 后，速度与帧率大致解耦。另一方面，拖动窗口、断点调试或系统暂停可能产生一秒以上的 `dt`，一次更新就会让实体穿过墙或错过碰撞，因此还要限制最大步长。

`SdlWindow.ticks()` 提供 SDL 初始化以来的毫秒计时，适合简单帧循环；`PerformanceClock` 提供纳秒和高精度计数器，适合测量阶段耗时。`Time` 是日历和墙钟，不适合运动积分，因为用户调整系统时间可能让它跳变。

## 工作模型

一帧开始读取 `now`，用 `now - last` 得到毫秒差并除以 1000 转成秒，然后夹在 0 到 0.05。先处理事件，让本帧输入可见；再更新运动、刷新计时器和粒子；随后做碰撞与结算；最后绘制稳定状态并提交。`delay` 只控制空转，不进入运动公式。

下面的反例按固定帧位移，并把延时当作准确时钟。

```cangjie role=contrast
while (running) {
    player.x += 4.0
    updateEnemies()
    draw()
    window.delay(UInt32(16))
}
```

稳定结构显式测量经过时间，并限制长帧。

```cangjie role=trace
let now = window.ticks()
let dt = clampF32(Float32(now - lastTicks) / 1000.0, 0.0, 0.05)
lastTicks = now
handleEvents(window, state)
update(state, dt)
resolveCollisions(state)
draw(window.renderer, state)
```

## 选择与取舍

可变步长简单，适合小型游戏和视觉效果；复杂物理可用固定步长累加器，在一帧内执行零到多次固定更新，但要限制追赶次数，避免慢帧越追越慢。无论哪种方案，渲染可按最新状态进行。最大 `dt` 太小会在卡顿后表现为游戏时间变慢，太大则增加穿透风险，应结合最高速度和最小碰撞体尺寸选择。

垂直同步减少撕裂，可能在 `present` 阻塞；额外 `delay` 可降低 CPU，但设置过大会降低响应。先测量实际帧耗时，再调整，不要把 16ms 当作所有显示器的事实。性能统计应分开测 update 与 draw，平均值之外还要关注偶发长帧。

## 应用这个模型

`thunder` 用毫秒时钟和 50ms 上限，所有速度以每秒为单位。子弹、敌机和粒子存在 ArrayList 中，更新时倒序删除；碰撞在位置更新后结算；渲染层只读取结果。`contra` 使用定步长并增加更细的模拟与动画层，但仍保持输入、模拟和渲染单向流动。

扩展敌机时把刷新间隔、速度和生命放进配置，把生成与运动放系统，把命中放碰撞，把图形放渲染。诊断时打印 `dt` 的最小、平均和最大值；若最大值常到上限，先查耗时阶段，而不是继续加大上限掩盖卡顿。

## 常见误解

`delay(16)` 不保证一帧正好 16ms；它只是至少等待一段时间。垂直同步也不保证逻辑必定 60Hz，显示器可能是 75、120 或 144Hz。限制 `dt` 不等于修复所有碰撞问题，高速小物体仍可能需要连续碰撞或更小固定步长。最后，墙钟时间适合日志和存档时间戳，不应直接驱动运动。

## 相关 API

- [`SdlWindow`](../../api/sdl/SdlWindow.md)：毫秒 ticks 与 delay。
- [`PerformanceClock`](../../api/sdl/system/PerformanceClock.md)：高精度计数与纳秒延时。
- [`Time`](../../api/sdl/system/Time.md)：日历和本地/UTC 时间。
- [`FrameInfo`](../../api/sdl/FrameInfo.md)：帧相关值对象。

## 下一步

完成[实时小游戏](../tutorials/real-time-game.md)，再把相同循环映射到 `thunder` 与 `contra` 的真实分层工程。
