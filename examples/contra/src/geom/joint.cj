package contra.geom

import std.math.cos
import std.math.sin

/*
 * 轻量骨骼动画的最小数据模型:点、骨、双骨肢体、带末端骨的骨链。
 * 全部是不可变值——每帧从玩家状态重新求值一副全新骨架,不做增量修改,
 * 逻辑简单且天然线程安全,是"数据即快照"的示范。
 */

/* 世界坐标下的一个关节点。 */
protected struct RigPoint {
    protected let x: Float32
    protected let y: Float32

    protected init(x: Float32, y: Float32) {
        this.x = x
        this.y = y
    }
}

/* 一根可绘制骨:自 joint 起,沿 angle(SDL 角度)方向延伸。 */
protected struct RigBone {
    protected let joint: RigPoint
    protected let angle: Float32

    protected init(joint: RigPoint, angle: Float32) {
        this.joint = joint
        this.angle = angle
    }
}

/* 双骨 IK 解出的上/下两段。 */
protected class RigLimb {
    protected let upper: RigBone
    protected let lower: RigBone

    protected init(upper: RigBone, lower: RigBone) {
        this.upper = upper
        this.lower = lower
    }
}

/* 在双骨链末端再加一根腕/踝末端骨(手掌、脚掌的朝向)。 */
protected class RigChain {
    protected let upper: RigBone
    protected let lower: RigBone
    protected let terminal: RigBone

    protected init(upper: RigBone, lower: RigBone, terminal: RigBone) {
        this.upper = upper
        this.lower = lower
        this.terminal = terminal
    }
}

/*
 * 在 root 的局部坐标系放置一个点:先按朝向镜像 X,再绕 root 旋转 rightAngle
 * (面向右时的角度),返回世界坐标。脊柱各段、肩髋锚点都用它挂到父节点上。
 */
protected func posePoint(root: RigPoint, localX: Float32, localY: Float32, rightAngle: Float32,
    facing: Float32): RigPoint {
    let mirroredX = localX * facing
    let angle = if (facing < 0.0) {
        -rightAngle
    } else {
        rightAngle
    }
    let radians = Float64(angle * TAU / 360.0)
    let cosine = Float32(cos(radians))
    let sine = Float32(sin(radians))
    RigPoint(root.x + mirroredX * cosine - localY * sine, root.y + mirroredX * sine + localY * cosine)
}

/* 构造一根从 start 指向 end 的骨。 */
protected func boneBetween(start: RigPoint, end: RigPoint): RigBone {
    RigBone(start, directionAngle(end.x - start.x, end.y - start.y))
}

/* 面向左时把"面向右的角度"水平镜像(180°-a),让同一套姿态左右通用。 */
protected func mirroredAngle(rightFacingAngle: Float32, facing: Float32): Float32 {
    if (facing < 0.0) {
        180.0 - rightFacingAngle
    } else {
        rightFacingAngle
    }
}
