package contra.rig

import contra.config.*
import contra.geom.*
import contra.model.*
import std.math.abs
import std.math.cos
import std.math.sin
import sdl.clampF32

/*
 * 脊柱姿态:由玩家状态推出臀点高度、整体前倾(guardLean)、奔跑重心起伏、
 * 待机呼吸与步态扭转,再沿骨盆→腹→胸→颈逐段挂点。头、胸、腹按不同权重跟随
 * 瞄准俯仰,使"瞄哪看哪"由整条脊柱协同完成,而非只转头。
 */
func evaluateHeroBody(player: Player): HeroBodyPose {
    let facing: Float32 = if (player.facing < 0.0) {
        -1.0
    } else {
        1.0
    }
    let feetX = player.x + HeroSpec.W / 2.0
    let feetY = player.y + HeroSpec.H
    let runBlend: Float32 = if (player.isOnGround && !player.isCrouching) {
        clampF32(Float32(abs(Float64(player.vx))) / HeroSpec.RUN_SPEED, 0.0, 1.0)
    } else {
        0.0
    }
    let breath = Float32(sin(Float64(player.animationTime * 2.2))) * (1.0 - runBlend)
    let gaitBounce = Float32(cos(Float64(player.animationPhase * 2.0))) * 0.9 * runBlend

    var hipHeight: Float32 = 82.0 - runBlend * 6.0
    if (player.isCrouching && player.isOnGround) {
        hipHeight = 44.0
    } else if (!player.isOnGround) {
        hipHeight = 64.0
    }
    let hip = RigPoint(feetX, feetY - hipHeight + gaitBounce - breath * 0.6 + player.landingBlend * 5.0)

    let localVelocity = clampF32(player.vx * facing / HeroSpec.RUN_SPEED, -1.0, 1.0)
    let guardLean: Float32 = if (player.isCrouching && player.isOnGround) {
        15.0
    } else if (player.isOnGround) {
        8.0
    } else {
        1.5
    }
    let movementLean = guardLean + localVelocity * 2.0 * runBlend
    let gaitTwist = Float32(sin(Float64(player.animationPhase * 2.0))) * 1.2 * runBlend
    let pelvisAngle = movementLean * 0.24 + gaitTwist
    let abdomenAngle = movementLean * 0.58 - gaitTwist * 0.35 + player.aimY * 2.2 + breath * 0.25
    let chestAngle = movementLean * 0.94 + gaitTwist * 0.18 + player.aimY * 4.6 + breath * 0.45
    let headAngle = movementLean * 0.12 + player.aimY * 13.0
    let abdomenBase = posePoint(hip, 0.0, -2.0, pelvisAngle, facing)
    let chestBase = posePoint(hip, 0.0, -12.0, abdomenAngle, facing)
    let neck = posePoint(chestBase, 1.0, -30.0, chestAngle, facing)
    HeroBodyPose(facing, hip, abdomenBase, chestBase, neck, pelvisAngle, abdomenAngle, chestAngle, headAngle, runBlend)
}
