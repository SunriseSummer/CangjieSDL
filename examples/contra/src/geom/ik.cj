package contra.geom

import std.math.acos
import std.math.sin
import std.math.sqrt
import sdl.clampF32

/*
 * 解析式双骨 IK:已知根、末端目标和上下段长度,求中间关节位置。
 *
 * 用余弦定理算出中间关节到"根—目标"连线的投影与垂距,再由 pole(极点)决定
 * 向连线的哪一侧弯曲——这一步固定了肘/膝的朝向,避免瞄准扫过时关节突然翻面。
 * 目标超出可及范围时把距离夹到臂展内,肢体自然伸直而非抖动。
 */
protected func solveTwoBoneWithPole(
    root: RigPoint,
    target: RigPoint,
    upperLength: Float32,
    lowerLength: Float32,
    pole: RigPoint
): RigLimb {
    let rawX = target.x - root.x
    let rawY = target.y - root.y
    let rawDistance = Float32(sqrt(Float64(rawX * rawX + rawY * rawY)))
    let distance = clampF32(rawDistance, 1.0, upperLength + lowerLength - 0.1)
    let directionX: Float32 = if (rawDistance > 0.001) {
        rawX / rawDistance
    } else {
        1.0
    }
    let directionY: Float32 = if (rawDistance > 0.001) {
        rawY / rawDistance
    } else {
        0.0
    }
    let projection = (upperLength * upperLength - lowerLength * lowerLength + distance * distance) / (2.0 * distance)
    let cosine = clampF32(projection / upperLength, -1.0, 1.0)
    let height = Float32(sin(acos(Float64(cosine)))) * upperLength
    let perpendicularX = -directionY
    let perpendicularY = directionX
    let poleDot = perpendicularX * (pole.x - root.x) + perpendicularY * (pole.y - root.y)
    let bend: Float32 = if (poleDot < 0.0) {
        -1.0
    } else {
        1.0
    }
    let middle = RigPoint(root.x + directionX * projection + perpendicularX * height * bend,
        root.y + directionY * projection + perpendicularY * height * bend)
    RigLimb(boneBetween(root, middle), boneBetween(middle, target))
}
