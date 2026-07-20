package game

import std.random.Random
import sdl.Rect

func randRange(rng: Random, min: Float32, max: Float32): Float32 {
    min + Float32(rng.nextFloat64()) * (max - min)
}

/* 新版 Rect 只有 inset（单值内缩），这里补一个双向外扩，用于光晕等包络矩形。 */
func grown(rect: Rect, dx: Float32, dy: Float32): Rect {
    Rect(rect.x - dx, rect.y - dy, rect.w + dx * 2.0, rect.h + dy * 2.0)
}

/* 新版 Rect 不再内置相交检测，碰撞判定自备 AABB 重叠测试。 */
func intersects(a: Rect, b: Rect): Bool {
    a.x < b.right() && a.right() > b.x && a.y < b.bottom() && a.bottom() > b.y
}
