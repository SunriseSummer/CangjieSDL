package contra.rig

import contra.config.*
import contra.geom.*
import contra.model.*
import std.math.sin
import sdl.clampF32

/*
 * 双腿:髋—膝—踝双段 IK + 独立战靴末端骨。地面时脚跟随步态曲线前后滑摆,
 * 腾空时按上升/下落收放,下蹲时前后错步。膝极点固定在髋前下方,保证膝始终朝前弯。
 */
func evaluateHeroLeg(player: Player, body: HeroBodyPose, isFront: Bool): RigChain {
    let localHipX: Float32 = if (isFront) {
        4.5
    } else {
        -4.5
    }
    let hipJoint = posePoint(body.hip, localHipX, 2.0, body.pelvisAngle, body.facing)
    let foot = evaluateFootPose(player, body, isFront)
    let pole = posePoint(hipJoint, 25.0, 32.0, 0.0, body.facing)
    let upperLength = lerp(34.5, 36.0, body.runBlend)
    let lowerLength = lerp(30.5, 31.5, body.runBlend)
    let limb = solveTwoBoneWithPole(hipJoint, foot.ankle, upperLength, lowerLength, pole)
    let boot = RigBone(foot.ankle, mirroredAngle(foot.rightFacingAngle, body.facing))
    RigChain(limb.upper, limb.lower, boot)
}

func evaluateFootPose(player: Player, body: HeroBodyPose, isFront: Bool): FootPose {
    let feetY = player.y + HeroSpec.H
    if (player.isCrouching && player.isOnGround) {
        return evaluateCrouchingFoot(body, feetY, isFront)
    }
    if (!player.isOnGround) {
        return evaluateAirFoot(player, body, isFront)
    }

    let baseX: Float32 = if (isFront) {
        9.0
    } else {
        -7.0
    }
    let offsetPhase: Float32 = if (isFront) {
        0.0
    } else {
        TAU / 2.0
    }
    let gait = sampleGait(player.animationPhase + offsetPhase, 52.0, 15.0)
    let landingSpread: Float32 = if (isFront) {
        player.landingBlend * 8.0
    } else {
        -player.landingBlend * 8.0
    }
    let x = lerp(baseX, gait.x, body.runBlend) + landingSpread
    return FootPose(RigPoint(body.hip.x + body.facing * x, feetY - 18.0 - gait.lift * body.runBlend),
        gait.footAngle * body.runBlend)
}

func evaluateCrouchingFoot(body: HeroBodyPose, feetY: Float32, isFront: Bool): FootPose {
    let x: Float32 = if (isFront) {
        15.0
    } else {
        -13.0
    }
    let angle: Float32 = if (isFront) {
        -5.0
    } else {
        2.0
    }
    FootPose(RigPoint(body.hip.x + body.facing * x, feetY - 18.0), angle)
}

/* 上升段双腿向臀下收拢,下落段前腿前伸、脚尖下探准备落地。 */
func evaluateAirFoot(player: Player, body: HeroBodyPose, isFront: Bool): FootPose {
    let rising = clampF32(-player.vy / HeroSpec.JUMP_SPEED, -1.0, 1.0)
    let x: Float32 = if (isFront) {
        17.0 - rising * 3.0
    } else {
        -14.0 - rising * 2.0
    }
    let y: Float32 = if (isFront) {
        44.0 - rising * 13.0
    } else {
        40.0 - rising * 9.0
    }
    let angle: Float32 = if (isFront) {
        13.0 + rising * 6.0
    } else {
        -9.0 + rising * 10.0
    }
    FootPose(RigPoint(body.hip.x + body.facing * x, body.hip.y + y), angle)
}

/* 步态拆成 62% 支撑相(脚贴地滑过)+ 38% 摆动相(脚抬起弧线前摆)。 */
func sampleGait(phase: Float32, stride: Float32, lift: Float32): GaitSample {
    let cycle = cycleUnit(phase)
    if (cycle < 0.62) {
        let progress = smoothStep(cycle / 0.62)
        return GaitSample(lerp(stride / 2.0, -stride / 2.0, progress), 0.0, lerp(-10.0, 10.0, progress))
    }
    let progress = smoothStep((cycle - 0.62) / 0.38)
    let arc = Float32(sin(Float64(progress * TAU / 2.0)))
    GaitSample(lerp(-stride / 2.0, stride / 2.0, progress), arc * lift, lerp(10.0, -8.0, progress) - arc * 5.0)
}
