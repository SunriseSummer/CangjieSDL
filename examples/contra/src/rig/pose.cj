package contra.rig

import contra.geom.*
import contra.model.*

/*
 * contra.rig —— 英雄的轻量 2D 骨骼动画运行时。
 *
 * 每帧从 Player 的连续状态(位置、速度、朝向、瞄准、各种融合权重)解析出一副
 * 全新的 HeroSkeleton,不保留跨帧动画状态、不依赖固定帧率。奔跑、腾空、下蹲、
 * 落地、翻身、连续瞄准都由同一套求值统一驱动,天然可插值、可镜像。
 *
 * 分工:pose(本文件,骨架数据 + 顶层编排)、spine(脊柱/呼吸/前倾)、
 * legs(髋膝踝 IK + 步态)、arms(肩肘腕 IK + 持枪约束)。
 * 只有 HeroSkeleton / evaluateHeroSkeleton / weaponMuzzlePoint 对外,其余是内部姿态。
 */

/* 一帧解算出的完整骨架:脊柱四段 + 双腿双臂骨链 + 握枪点。渲染层只读它。 */
protected class HeroSkeleton {
    protected let facing: Float32
    protected let hip: RigPoint
    protected let pelvis: RigBone
    protected let abdomen: RigBone
    protected let chest: RigBone
    protected let head: RigBone
    protected let rearLeg: RigChain
    protected let frontLeg: RigChain
    protected let rearArm: RigChain
    protected let frontArm: RigChain
    protected let weaponGrip: RigPoint

    protected init(
        facing: Float32,
        hip: RigPoint,
        pelvis: RigBone,
        abdomen: RigBone,
        chest: RigBone,
        head: RigBone,
        rearLeg: RigChain,
        frontLeg: RigChain,
        rearArm: RigChain,
        frontArm: RigChain,
        weaponGrip: RigPoint
    ) {
        this.facing = facing
        this.hip = hip
        this.pelvis = pelvis
        this.abdomen = abdomen
        this.chest = chest
        this.head = head
        this.rearLeg = rearLeg
        this.frontLeg = frontLeg
        this.rearArm = rearArm
        this.frontArm = frontArm
        this.weaponGrip = weaponGrip
    }
}

/* 脊柱各段的中间姿态(基点 + 面向右时的角度 + 奔跑融合权重)。 */
class HeroBodyPose {
    let facing: Float32
    let hip: RigPoint
    let abdomenBase: RigPoint
    let chestBase: RigPoint
    let neck: RigPoint
    let pelvisAngle: Float32
    let abdomenAngle: Float32
    let chestAngle: Float32
    let headAngle: Float32
    let runBlend: Float32

    init(
        facing: Float32,
        hip: RigPoint,
        abdomenBase: RigPoint,
        chestBase: RigPoint,
        neck: RigPoint,
        pelvisAngle: Float32,
        abdomenAngle: Float32,
        chestAngle: Float32,
        headAngle: Float32,
        runBlend: Float32
    ) {
        this.facing = facing
        this.hip = hip
        this.abdomenBase = abdomenBase
        this.chestBase = chestBase
        this.neck = neck
        this.pelvisAngle = pelvisAngle
        this.abdomenAngle = abdomenAngle
        this.chestAngle = chestAngle
        this.headAngle = headAngle
        this.runBlend = runBlend
    }
}

/* 双臂解算结果与握枪点。 */
class HeroArmPose {
    let rearArm: RigChain
    let frontArm: RigChain
    let weaponGrip: RigPoint

    init(rearArm: RigChain, frontArm: RigChain, weaponGrip: RigPoint) {
        this.rearArm = rearArm
        this.frontArm = frontArm
        this.weaponGrip = weaponGrip
    }
}

/* 单只脚的落点与脚掌角度。 */
class FootPose {
    let ankle: RigPoint
    let rightFacingAngle: Float32

    init(ankle: RigPoint, rightFacingAngle: Float32) {
        this.ankle = ankle
        this.rightFacingAngle = rightFacingAngle
    }
}

/* 步态一帧的采样:前后位移、抬脚高度、脚掌角度。 */
struct GaitSample {
    let x: Float32
    let lift: Float32
    let footAngle: Float32

    init(x: Float32, lift: Float32, footAngle: Float32) {
        this.x = x
        this.lift = lift
        this.footAngle = footAngle
    }
}

/* 顶层编排:先解脊柱,再挂骨盆/腹/胸/头,最后解双腿双臂,组装成骨架。 */
protected func evaluateHeroSkeleton(player: Player): HeroSkeleton {
    let body = evaluateHeroBody(player)
    let pelvis = RigBone(body.hip, mirroredAngle(body.pelvisAngle, body.facing))
    let abdomen = RigBone(body.abdomenBase, mirroredAngle(body.abdomenAngle, body.facing))
    let chest = RigBone(body.chestBase, mirroredAngle(body.chestAngle, body.facing))
    let head = RigBone(body.neck, mirroredAngle(body.headAngle, body.facing))
    let rearLeg = evaluateHeroLeg(player, body, false)
    let frontLeg = evaluateHeroLeg(player, body, true)
    let arms = evaluateHeroArms(player, body)

    HeroSkeleton(
        body.facing,
        body.hip,
        pelvis,
        abdomen,
        chest,
        head,
        rearLeg,
        frontLeg,
        arms.rearArm,
        arms.frontArm,
        arms.weaponGrip
    )
}
