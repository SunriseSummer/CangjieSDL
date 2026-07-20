package contra.rig

import contra.config.*
import contra.geom.*
import contra.model.*
import sdl.clampF32

/*
 * 双臂:肩—肘—腕双段 IK。武器握点由枪托抵肩点沿瞄准方向外推得到,前后手再挂到
 * 握把与护木上;肘极点跟随"枪管下方"法线,让平/仰/俯射的肘朝向都自然。前肩锚点
 * 对齐躯干贴图自带的三角肌,使手臂看起来从肩窝长出而非贴在胸前。
 */
func evaluateHeroArms(player: Player, body: HeroBodyPose): HeroArmPose {
    let aimX = player.aimX
    let aimY = player.aimY
    let (belowX, belowY) = barrelDownNormal(aimX, aimY, body.facing)
    let raise = clampF32(-aimY, 0.0, 1.0)
    let dip = clampF32(aimY, 0.0, 1.0)

    let rearShoulder = posePoint(body.chestBase, 4.0, -25.0, body.chestAngle, body.facing)
    let frontShoulder = posePoint(body.chestBase, -6.5, -24.0, body.chestAngle, body.facing)
    /* 仰俯越陡,枪托越滑出肩窝并推向体前,让枪身避开头部和大腿。 */
    let stockContact = posePoint(
        body.chestBase,
        3.0 + raise * 15.0 + dip * 7.0,
        -19.0 + raise * 8.0 - dip * 3.0,
        body.chestAngle,
        body.facing
    )
    let gripReach = WeaponSpec.STOCK_TO_GRIP - player.recoil * WeaponSpec.RECOIL_SLIDE
    let grip = RigPoint(stockContact.x + aimX * gripReach, stockContact.y + aimY * gripReach)
    let supportGrip = RigPoint(grip.x + aimX * WeaponSpec.SUPPORT_GRIP_OFFSET,
        grip.y + aimY * WeaponSpec.SUPPORT_GRIP_OFFSET)
    /* 扳机手落在握把上,护木手从枪管下方托住前护木。 */
    let triggerWrist = RigPoint(grip.x - aimX * 7.5 + belowX * 3.8, grip.y - aimY * 7.5 + belowY * 3.8)
    let supportWrist = RigPoint(supportGrip.x - aimX * 1.2 + belowX * 2.6,
        supportGrip.y - aimY * 1.2 + belowY * 2.6)
    /* 肘极点跟随枪管下方:平射肘朝下,仰射肘朝前,俯射肘收向身后。 */
    let rearPole = RigPoint(rearShoulder.x + belowX * 36.0, rearShoulder.y + belowY * 36.0)
    let frontPole = RigPoint(frontShoulder.x + belowX * 34.0, frontShoulder.y + belowY * 34.0)
    let rearLimb = solveTwoBoneWithPole(rearShoulder, supportWrist, 27.5, 25.5, rearPole)
    let frontLimb = solveTwoBoneWithPole(frontShoulder, triggerWrist, 25.0, 24.0, frontPole)
    let handAngle = directionAngle(aimX, aimY)
    let rearArm = RigChain(rearLimb.upper, rearLimb.lower, RigBone(supportWrist, handAngle))
    let frontArm = RigChain(frontLimb.upper, frontLimb.lower, RigBone(triggerWrist, handAngle))
    HeroArmPose(rearArm, frontArm, grip)
}

/* 屏幕空间中"枪管下方"的单位法线;乘朝向修正后左右镜像保持同侧。 */
func barrelDownNormal(aimX: Float32, aimY: Float32, facing: Float32): (Float32, Float32) {
    (-aimY * facing, aimX * facing)
}

/* 枪口世界坐标:握点沿瞄准前移 + 抬到枪管中线。渲染火焰与生成子弹共用它。 */
protected func weaponMuzzlePoint(rig: HeroSkeleton, aimX: Float32, aimY: Float32): RigPoint {
    let (belowX, belowY) = barrelDownNormal(aimX, aimY, rig.facing)
    RigPoint(rig.weaponGrip.x + aimX * WeaponSpec.MUZZLE_OFFSET + belowX * WeaponSpec.MUZZLE_LIFT,
        rig.weaponGrip.y + aimY * WeaponSpec.MUZZLE_OFFSET + belowY * WeaponSpec.MUZZLE_LIFT)
}
