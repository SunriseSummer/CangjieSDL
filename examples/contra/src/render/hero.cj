package contra.render

import contra.config.*
import contra.geom.*
import contra.model.*
import contra.rig.*
import std.math.atan2
import std.math.sin
import sdl.Point
import sdl.Rect
import sdl.Renderer
import sdl.Texture
import sdl.TextureFlip
import sdl.TextureRenderOptions

/*
 * 主角骨架的分层绘制。部件按人体遮挡关系从后往前铺:后肢 → 支撑臂上臂 → 骨盆/
 * 腹/胸 → 支撑臂前臂/手 → 枪 → 前臂/手 → 头。四肢用蒙皮条带(见 skinning.cj)弯折,
 * 躯干/头/战靴/头巾用刚体贴图旋转。枪与子弹共享 rig.weaponGrip,握点与弹道不分离。
 */

/* 一次部件绘制的共享上下文:渲染器、状态(取镜头/震动)、图集纹理、朝向。 */
class RigDrawContext {
    let renderer: Renderer
    let state: GameState
    let texture: Texture
    let facing: Float32

    init(renderer: Renderer, state: GameState, texture: Texture, facing: Float32) {
        this.renderer = renderer
        this.state = state
        this.texture = texture
        this.facing = facing
    }
}

func drawPlayer(r: Renderer, state: GameState, assets: GameAssets): Unit {
    let player = state.player
    if (!isPlaying(state.phase) || isPlayerBlinking(player)) {
        return
    }

    let rig = evaluateHeroSkeleton(player)
    drawHeroRig(r, state, assets, rig)
}

func drawHeroRig(r: Renderer, state: GameState, assets: GameAssets, rig: HeroSkeleton): Unit {
    let bodyContext = RigDrawContext(r, state, assets.commandoParts, rig.facing)
    let handContext = RigDrawContext(r, state, assets.commandoHands, rig.facing)
    drawHeadbandTails(bodyContext, rig)

    let rearThigh: LimbPartSpec = (Rect(65.0, 672.0, 146.0, 274.0), 8.0, 0.135)
    let frontThigh: LimbPartSpec = (Rect(698.0, 677.0, 142.0, 269.0), 8.0, 0.135)
    drawRigPart(bodyContext, rig.rearLeg.terminal, Rect(441.0, 769.0, 188.0, 167.0), RigPoint(25.0, 18.0), (0.0, 0.12))
    drawLimbSkin(bodyContext, rig.rearLeg, rearThigh, (Rect(279.0, 692.0, 97.0, 239.0), 15.0, 0.135))
    drawRigPart(bodyContext, rig.frontLeg.terminal, Rect(1056.0, 778.0, 181.0, 159.0), RigPoint(24.0, 17.0), (0.0, 0.12))
    drawLimbSkin(bodyContext, rig.frontLeg, frontThigh, (Rect(904.0, 696.0, 92.0, 237.0), 15.0, 0.135))

    /* 支撑臂上臂在躯干后,前臂跨过胸前伸向护木,因此共用一条脊骨、拆开分层。 */
    let rearArmSpine = limbSpine(rig.rearArm)
    let rearUpperArm: LimbPartSpec = (Rect(52.0, 392.0, 129.0, 229.0), 10.0, 0.12)
    let rearForearm: LimbPartSpec = (Rect(274.0, 409.0, 91.0, 193.0), 8.0, 0.13)
    drawSkinnedPart(bodyContext, rearArmSpine, rearUpperArm, rearForearm, isLower: false)
    drawRigPart(bodyContext, rig.pelvis, Rect(44.0, 185.0, 225.0, 139.0), RigPoint(112.0, 24.0), (0.0, 0.125))
    /* 腰带盖住大腿顶端后,再把大腿顶部沿腰带下沿向上渐隐叠回,消除刚性腰带
     * 底边与摆动大腿之间的牛仔布错位缝,让大腿看起来自然探入腰带下方。 */
    drawHipBlend(bodyContext, rig.rearLeg, rearThigh)
    drawHipBlend(bodyContext, rig.frontLeg, frontThigh)
    drawRigPart(bodyContext, rig.abdomen, Rect(326.0, 142.0, 160.0, 159.0), RigPoint(80.0, 155.0), (0.0, 0.115))
    drawRigPart(bodyContext, rig.chest, Rect(512.0, 50.0, 259.0, 281.0), RigPoint(130.0, 277.0), (0.0, 0.13))

    drawSkinnedPart(bodyContext, rearArmSpine, rearUpperArm, rearForearm, isLower: true)
    drawHeroRearHand(handContext, rig)
    drawRigWeapon(r, state, assets, rig)
    drawLimbSkin(bodyContext, rig.frontArm, (Rect(711.0, 390.0, 121.0, 231.0), 10.0, 0.115),
        (Rect(903.0, 409.0, 89.0, 193.0), 8.0, 0.12))
    drawHeroFrontHand(handContext, rig)
    drawRigPart(bodyContext, rig.head, Rect(833.0, 81.0, 184.0, 230.0), RigPoint(95.0, 225.0), (0.0, 0.12))
}

func drawHeroRearHand(context: RigDrawContext, rig: HeroSkeleton): Unit {
    let isRecoiling = context.state.player.recoil > 0.28
    let supportSource = if (isRecoiling) {
        Rect(1660.0, 212.0, 386.0, 274.0)
    } else {
        Rect(618.0, 215.0, 386.0, 273.0)
    }
    drawRigPart(context, rig.rearArm.terminal, supportSource, RigPoint(18.0, supportSource.h / 2.0), (0.0, 0.036))
}

func drawHeroFrontHand(context: RigDrawContext, rig: HeroSkeleton): Unit {
    let isRecoiling = context.state.player.recoil > 0.28
    let triggerSource = if (isRecoiling) {
        Rect(1143.0, 196.0, 405.0, 295.0)
    } else {
        Rect(70.0, 199.0, 460.0, 285.0)
    }
    drawRigPart(context, rig.frontArm.terminal, triggerSource, RigPoint(20.0, triggerSource.h / 2.0), (0.0, 0.034))
}

/*
 * 把一块刚体部件贴图绕关节旋转铺到骨上。pivotInSource 是关节在源图中的像素位置,
 * restAngle 是该部件"面向右、未旋转"时骨的基准角度,朝左时整体水平镜像。
 */
func drawRigPart(
    context: RigDrawContext,
    bone: RigBone,
    source: Rect,
    pivotInSource: RigPoint,
    metrics: (Float32, Float32)
): Unit {
    let (restAngle, scale) = metrics
    let width = source.w * scale
    let height = source.h * scale
    let sourcePivotX = pivotInSource.x * scale
    let pivotX = if (context.facing < 0.0) {
        width - sourcePivotX
    } else {
        sourcePivotX
    }
    let pivotY = pivotInSource.y * scale
    let mirroredRestAngle = if (context.facing < 0.0) {
        180.0 - restAngle
    } else {
        restAngle
    }
    let destination = Rect(
        worldX(context.state, bone.joint.x) - pivotX,
        bone.joint.y + shakeY(context.state) - pivotY,
        width,
        height
    )
    let flip = if (context.facing < 0.0) {
        TextureFlip.Horizontal
    } else {
        TextureFlip.None
    }
    let options = TextureRenderOptions(
        source: Some(source),
        center: Some(Point(pivotX, pivotY)),
        flip: flip
    )
    context
        .renderer
        .textureRotated(context.texture, destination, Float64(bone.angle - mirroredRestAngle), options: options)
}

func drawHeadbandTails(context: RigDrawContext, rig: HeroSkeleton): Unit {
    let sway = Float32(sin(Float64(context.state.player.animationTime * 3.2 + context.state.player.animationPhase))) *
        4.0
    let attachment = RigPoint(rig.head.joint.x - rig.facing * 2.0, rig.head.joint.y - 19.0)
    drawRibbonPart(context, attachment, Rect(1061.0, 142.0, 151.0, 60.0), sway)
    drawRibbonPart(context, RigPoint(attachment.x, attachment.y + 4.0), Rect(1093.0, 198.0, 135.0, 76.0),
        -3.0 + sway * 0.7)
}

func drawRibbonPart(
    context: RigDrawContext,
    attachment: RigPoint,
    source: Rect,
    rightAngle: Float32
): Unit {
    let scale: Float32 = 0.12
    let width = source.w * scale
    let height = source.h * scale
    let pivotX: Float32 = if (context.facing < 0.0) {
        3.0
    } else {
        width - 3.0
    }
    let pivotY = height / 2.0
    let flip = if (context.facing < 0.0) {
        TextureFlip.Horizontal
    } else {
        TextureFlip.None
    }
    let angle = if (context.facing < 0.0) {
        -rightAngle
    } else {
        rightAngle
    }
    let destination = Rect(worldX(context.state, attachment.x) - pivotX, attachment.y + shakeY(context.state) - pivotY,
        width, height)
    let options = TextureRenderOptions(source: Some(source), center: Some(Point(pivotX, pivotY)), flip: flip)
    context.renderer.textureRotated(context.texture, destination, Float64(angle), options: options)
}

func drawRigWeapon(r: Renderer, state: GameState, assets: GameAssets, rig: HeroSkeleton): Unit {
    let (aimX, aimY) = playerAim(state)
    let anchorX = worldX(state, rig.weaponGrip.x)
    let anchorY = rig.weaponGrip.y + shakeY(state)
    let aimAngle = Float64(atan2(Float64(aimY), Float64(aimX))) * 57.2957795
    let facesLeft = aimX < 0.0
    let angle = if (facesLeft) {
        aimAngle - 180.0
    } else {
        aimAngle
    }
    let width = WeaponSpec.DRAW_WIDTH
    let height = WeaponSpec.DRAW_HEIGHT
    let pivotX: Float32 = if (facesLeft) {
        width - WeaponSpec.PIVOT_X
    } else {
        WeaponSpec.PIVOT_X
    }
    let flip = if (facesLeft) {
        TextureFlip.Horizontal
    } else {
        TextureFlip.None
    }
    let destination = Rect(anchorX - pivotX, anchorY - height / 2.0, width, height)
    let source = Rect(111.0, 173.0, 1559.0, 531.0)
    let options = TextureRenderOptions(
        source: Some(source),
        center: Some(Point(pivotX, height / 2.0)),
        flip: flip
    )
    r.textureRotated(assets.rifle, destination, angle, options: options)
    if (state.player.muzzleFlash > 0.0) {
        let muzzle = weaponMuzzlePoint(rig, aimX, aimY)
        let muzzleX = worldX(state, muzzle.x)
        let muzzleY = muzzle.y + shakeY(state)
        let flashX = muzzleX + aimX * 3.0
        let flashY = muzzleY + aimY * 3.0
        r.fillCircle(flashX, flashY, 9.0, Pal.SHOT_GLOW)
        r.line(muzzleX - aimX * 2.0, muzzleY - aimY * 2.0, flashX + aimX * 4.0, flashY + aimY * 4.0, Pal.MUZZLE)
        r.fillCircle(flashX, flashY, 4.5, Pal.MUZZLE)
        r.fillCircle(muzzleX, muzzleY, 3.0, Pal.MUZZLE)
    }
}

/* 受击无敌期内按 BLINK_RATE 闪烁:偶数半周期跳过绘制,形成闪白反馈。 */
func isPlayerBlinking(player: Player): Bool {
    player.invincible > 0.0 && Int64(player.invincible * HeroSpec.BLINK_RATE) % 2 == 0
}
