package contra.geom

import std.math.atan2
import std.math.floor
import std.random.Random
import sdl.clampF32

/*
 * contra.geom —— 与游戏无关的 2D 数学与轻量骨骼工具箱。
 *
 * 本包不 import 任何游戏类型(config/model 等),只依赖标准库与 sdl 的
 * 几何原语。因此它是整棵依赖树的叶子,可被 rig / sim / render 各层共享,
 * 也可原样搬去别的项目。所有对外符号显式标 `protected`(模块内可见)。
 */

/* 一圈的弧度(2π)。角度↔弧度换算与相位循环都以它为基准。 */
protected let TAU: Float32 = 6.28318

/* 线性插值:amount=0 取 start,=1 取 end。 */
protected func lerp(start: Float32, end: Float32, amount: Float32): Float32 {
    start + (end - start) * amount
}

/* 平滑阶跃 3t²-2t³:把 [0,1] 映射为首尾导数为 0 的 S 曲线,消除线性拐点。 */
protected func smoothStep(value: Float32): Float32 {
    let clamped = clampF32(value, 0.0, 1.0)
    clamped * clamped * (3.0 - 2.0 * clamped)
}

/* 每帧把 value 朝 target 逼近最多 amount,不会过冲。用于速度、计时器收敛。 */
protected func approach(value: Float32, target: Float32, amount: Float32): Float32 {
    if (value < target) {
        return clampF32(value + amount, value, target)
    }
    clampF32(value - amount, target, value)
}

/* [min, max) 区间上的均匀随机数。 */
protected func randRange(rng: Random, min: Float32, max: Float32): Float32 {
    min + Float32(rng.nextFloat64()) * (max - min)
}

/* 向量 (x, y) 的方向角,单位为 SDL 角度(度、顺时针、0°指向 +x)。 */
protected func directionAngle(x: Float32, y: Float32): Float32 {
    Float32(atan2(Float64(y), Float64(x)) * 360.0 / Float64(TAU))
}

/* 把相位折叠回 [0,1) 的循环单位,用于步态等周期动画。 */
protected func cycleUnit(phase: Float32): Float32 {
    let cycle = phase / TAU
    cycle - Float32(floor(Float64(cycle)))
}
