package contra.sim

import contra.config.*
import contra.geom.*
import contra.model.*
import contra.rig.*
import std.math.abs
import sdl.clampF32

/*
 * 玩家物理与战斗:水平加速、平台落地、跳跃(离地宽容 + 输入缓冲 + 快按增高)、
 * 冷却衰减、瞄准解算与开火。所有量以秒为单位,长帧已在 loop 处截断。
 */
func updatePlayer(state: GameState, dt: Float32): Unit {
    updatePlayerMovement(state, dt)
    updatePlayerCombat(state, dt)
    checkPlayerProgress(state)
}

func updatePlayerMovement(state: GameState, dt: Float32): Unit {
    let player = state.player
    let previousX = player.x
    let wasOnGround = player.isOnGround
    let direction = movementDirection(state.input)
    if (direction < -0.001 || direction > 0.001 || state.input.isJumpPressed) {
        state.hasPlayerMoved = true
    }
    player.isCrouching = state.input.isDownHeld && player.isOnGround
    if (!state.input.isUsingMouse && (direction < -0.001 || direction > 0.001)) {
        player.facing = direction
    }
    player.vx = approach(player.vx, playerTargetSpeed(player, direction), HeroSpec.RUN_ACCEL * dt)

    updateJumpWindows(state, dt)
    applyJumpInput(state)

    let previousBottom = player.y + HeroSpec.H
    player.x += player.vx * dt
    player.x = clampF32(player.x, 20.0, playerMaxX(state))
    let maxJumpSpeed = HeroSpec.JUMP_SPEED + HeroSpec.JUMP_BOOST * Float32(HeroSpec.MAX_JUMP_TAPS)
    player.vy = clampF32(player.vy + HeroSpec.GRAVITY * dt, -maxJumpSpeed, HeroSpec.MAX_FALL_SPEED)
    player.y += player.vy * dt
    resolveLanding(state, previousBottom)
    player.animationTime += dt
    player.animationPhase += Float32(abs(Float64(player.x - previousX))) * HeroSpec.RUN_CYCLE_PER_PIXEL
    if (!wasOnGround && player.isOnGround) {
        player.landingBlend = 1.0
    }
}

/* 落地首跳后,在短窗口内快速再次按空格可逐级增加向上冲量。 */
func applyJumpInput(state: GameState): Unit {
    let player = state.player
    if (player.isCrouching) {
        return
    }
    if (player.jumpBufferTimer > 0.0 && (player.isOnGround || player.coyoteTimer > 0.0)) {
        player.vy = -HeroSpec.JUMP_SPEED
        player.isOnGround = false
        player.coyoteTimer = 0.0
        player.jumpBufferTimer = 0.0
        player.jumpTapTimer = HeroSpec.JUMP_TAP_WINDOW
        player.jumpTapCount = 0
        return
    }
    if (state.input.isJumpPressed && player.jumpTapTimer > 0.0 && player.jumpTapCount < HeroSpec.MAX_JUMP_TAPS &&
        player.vy < 80.0) {
        player.vy -= HeroSpec.JUMP_BOOST
        player.jumpTapCount += 1
        player.jumpBufferTimer = 0.0
        player.jumpTapTimer = HeroSpec.JUMP_TAP_WINDOW
    }
}

func updateJumpWindows(state: GameState, dt: Float32): Unit {
    let player = state.player
    if (player.isOnGround) {
        player.coyoteTimer = HeroSpec.COYOTE_TIME
    } else {
        player.coyoteTimer = approach(player.coyoteTimer, 0.0, dt)
    }
    if (state.input.isJumpPressed) {
        player.jumpBufferTimer = HeroSpec.JUMP_BUFFER_TIME
    } else {
        player.jumpBufferTimer = approach(player.jumpBufferTimer, 0.0, dt)
    }
}

func movementDirection(input: InputState): Float32 {
    var direction: Float32 = 0.0
    if (input.isLeftHeld) {
        direction -= 1.0
    }
    if (input.isRightHeld) {
        direction += 1.0
    }
    direction
}

func playerTargetSpeed(player: Player, direction: Float32): Float32 {
    if (player.isCrouching) {
        return 0.0
    }
    if (player.isOnGround) {
        return direction * HeroSpec.RUN_SPEED
    }
    direction * HeroSpec.RUN_SPEED * HeroSpec.AIR_CONTROL
}

func updatePlayerCombat(state: GameState, dt: Float32): Unit {
    let player = state.player
    if (player.cooldown > 0.0) {
        player.cooldown -= dt
    }
    if (player.invincible > 0.0) {
        player.invincible -= dt
    }
    if (player.muzzleFlash > 0.0) {
        player.muzzleFlash -= dt
    }
    if (player.jumpTapTimer > 0.0) {
        player.jumpTapTimer -= dt
    }
    player.recoil = approach(player.recoil, 0.0, HeroSpec.RECOIL_RECOVERY * dt)
    player.landingBlend = approach(player.landingBlend, 0.0, HeroSpec.LANDING_RECOVERY * dt)
    updatePlayerAim(state, dt)
    if (state.input.isUsingMouse) {
        let (aimX, _) = playerAim(state)
        if (aimX < -0.12) {
            player.facing = -1.0
        } else if (aimX > 0.12) {
            player.facing = 1.0
        }
    }
    if ((state.input.isFireHeld || state.input.isMouseFireHeld) && player.cooldown <= 0.0) {
        firePlayerWeapon(state)
    }
}

func checkPlayerProgress(state: GameState): Unit {
    let player = state.player
    if (player.y > Stage.FALL_LIMIT) {
        damagePlayer(state, shouldRespawn: true)
    }

    if (!state.bossAwake && player.x > FoeSpec.BOSS_TRIGGER_X) {
        state.bossAwake = true
        state.screenShake = 0.55
    }
}

func playerMaxX(state: GameState): Float32 {
    if (state.bossAwake) {
        return HeroSpec.MAX_X_BEFORE_BOSS
    }
    Stage.WORLD_WIDTH - HeroSpec.W
}

func resolveLanding(state: GameState, previousBottom: Float32): Unit {
    let player = state.player
    player.isOnGround = false
    if (player.vy < 0.0) {
        return
    }

    for (solid in state.solids) {
        let hasHorizontalOverlap = player.x + HeroSpec.W - 6.0 > solid.rect.x && player.x + 6.0 < solid.rect.right()
        if (hasHorizontalOverlap && previousBottom <= solid.rect.y + 10.0 && player.y + HeroSpec.H >= solid.rect.y) {
            player.y = solid.rect.y - HeroSpec.H
            player.vy = 0.0
            player.isOnGround = true
            player.jumpTapTimer = 0.0
            player.jumpTapCount = 0
        }
    }
}

func firePlayerWeapon(state: GameState): Unit {
    let player = state.player
    let (aimX, aimY) = playerAim(state)
    let rig = evaluateHeroSkeleton(player)
    let muzzle = weaponMuzzlePoint(rig, aimX, aimY)

    addFriendlyBullet(state, muzzle.x, muzzle.y, aimX, aimY)
    if (hasSpread(player.weapon)) {
        addSpreadBullet(state, (muzzle.x, muzzle.y), (aimX, aimY), -0.18)
        addSpreadBullet(state, (muzzle.x, muzzle.y), (aimX, aimY), 0.18)
        player.cooldown = HeroSpec.SPREAD_COOLDOWN
    } else {
        player.cooldown = HeroSpec.RIFLE_COOLDOWN
    }
    player.muzzleFlash = 0.06
    player.recoil = 1.0
}

func updatePlayerAim(state: GameState, dt: Float32): Unit {
    let player = state.player
    let (targetX, targetY) = targetPlayerAim(state)
    if (!state.input.isUsingMouse) {
        player.aimX = targetX
        player.aimY = targetY
        return
    }
    let blend = clampF32(HeroSpec.AIM_RESPONSE * dt, 0.0, 1.0)
    let (nextX, nextY) = normalized(
        player.aimX + (targetX - player.aimX) * blend,
        player.aimY + (targetY - player.aimY) * blend
    )
    player.aimX = nextX
    player.aimY = nextY
}

/* 鼠标模式:朝握点到指针的方向瞄准。键盘模式:八向离散瞄准(上/下斜/平)。 */
func targetPlayerAim(state: GameState): (Float32, Float32) {
    let input = state.input
    let player = state.player
    if (input.isUsingMouse) {
        let rig = evaluateHeroSkeleton(player)
        let anchorX = rig.weaponGrip.x - state.cameraX
        let anchorY = rig.weaponGrip.y
        return normalized(input.mouseX - anchorX, input.mouseY - anchorY)
    }

    var x = player.facing
    var y: Float32 = 0.0

    if (input.isUpHeld) {
        y = -1.0
        if (!input.isLeftHeld && !input.isRightHeld) {
            x = 0.0
        }
    } else if (input.isDownHeld && !player.isOnGround) {
        y = 1.0
        if (!input.isLeftHeld && !input.isRightHeld) {
            x = 0.0
        }
    }
    normalized(x, y)
}

func addFriendlyBullet(state: GameState, x: Float32, y: Float32, dx: Float32, dy: Float32): Unit {
    state.bullets.add(Bullet(x, y, dx * HeroSpec.BULLET_SPEED, dy * HeroSpec.BULLET_SPEED, true))
}

func addSpreadBullet(
    state: GameState,
    origin: (Float32, Float32),
    aim: (Float32, Float32),
    spread: Float32
): Unit {
    let (x, y) = origin
    let (dx, dy) = aim
    let (shotX, shotY) = normalized(dx - dy * spread, dy + dx * spread)
    state.bullets.add(Bullet(x, y, shotX * HeroSpec.BULLET_SPEED, shotY * HeroSpec.BULLET_SPEED, true))
}
