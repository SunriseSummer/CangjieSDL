package contra.sim

import contra.config.*
import contra.geom.*
import contra.model.*
import std.math.abs
import std.math.sin
import sdl.clampF32

/*
 * 敌人 AI 与开火。开场先做进入激活判定与受击闪白衰减(与玩家是否移动无关),
 * 玩家首次移动后才推进移动与射击。无人机漂移、步兵巡逻、炮台/Boss 定点,
 * Boss 打五连发扇形弹幕。
 */
func updateEnemies(state: GameState, dt: Float32): Unit {
    for (enemy in state.enemies) {
        if (!enemy.isActive && enemy.rect.x < state.cameraX + Stage.WIDTH_F + 140.0) {
            enemy.isActive = !isBoss(enemy.kind) || state.bossAwake
        }
        if (!enemy.isActive) {
            continue
        }
        /* 受击闪白与玩家是否移动无关,先于开场警戒判断衰减。 */
        if (enemy.flash > 0.0) {
            enemy.flash -= dt
        }
        if (!state.hasPlayerMoved) {
            continue
        }

        if (enemy.cooldown > 0.0) {
            enemy.cooldown -= dt
        }
        updateEnemyMovement(state, enemy, dt)
        updateEnemyWeapon(state, enemy)
    }
}

func updateEnemyMovement(state: GameState, enemy: Enemy, dt: Float32): Unit {
    enemy.phase += dt
    if (isDrone(enemy.kind)) {
        enemy.rect.y = enemy.baseY + Float32(sin(Float64(enemy.phase * FoeSpec.DRONE_BOB_RATE))) *
            FoeSpec.DRONE_BOB_RANGE
        enemy.rect.x -= FoeSpec.DRONE_DRIFT_SPEED * dt
        return
    }
    if (isBoss(enemy.kind) || isTurret(enemy.kind)) {
        return
    }

    let distance = state.player.x - enemy.rect.centerX()
    if (Float32(abs(Float64(distance))) < FoeSpec.ALERT_DISTANCE) {
        let direction: Float32 = if (distance < 0.0) {
            -1.0
        } else {
            1.0
        }
        enemy.rect.x += direction * FoeSpec.GRUNT_SPEED * dt
        enemy.rect.x = clampF32(enemy.rect.x, enemy.baseX - FoeSpec.GRUNT_PATROL_RANGE,
            enemy.baseX + FoeSpec.GRUNT_PATROL_RANGE)
    }
}

func updateEnemyWeapon(state: GameState, enemy: Enemy): Unit {
    let dx = state.player.x + HeroSpec.W / 2.0 - enemy.rect.centerX()
    let dy = state.player.y + HeroSpec.H / 2.0 - enemy.rect.centerY()
    let distanceSquared = dx * dx + dy * dy

    if (enemy.cooldown > 0.0 || distanceSquared > FoeSpec.SHOT_DISTANCE * FoeSpec.SHOT_DISTANCE) {
        return
    }
    if (isBoss(enemy.kind)) {
        fireBossVolley(state, enemy, dx, dy)
        enemy.cooldown = FoeSpec.BOSS_FIRE_DELAY
    } else {
        let (aimX, aimY) = normalized(dx, dy)
        state.bullets.add(
            Bullet(
                enemy.rect.centerX(),
                enemy.rect.centerY(),
                aimX * FoeSpec.BULLET_SPEED,
                aimY * FoeSpec.BULLET_SPEED,
                false
            )
        )
        enemy.cooldown = randRange(state.rng, FoeSpec.MIN_FIRE_DELAY, FoeSpec.MAX_FIRE_DELAY)
    }
}

func fireBossVolley(state: GameState, enemy: Enemy, dx: Float32, dy: Float32): Unit {
    let (aimX, aimY) = normalized(dx, dy)
    for (offset in [Float32(-0.34), Float32(-0.17), Float32(0.0), Float32(0.17), Float32(0.34)]) {
        let (shotX, shotY) = normalized(aimX - aimY * offset, aimY + aimX * offset)
        state.bullets.add(Bullet(enemy.rect.x + 22.0, enemy.rect.centerY(), shotX * FoeSpec.BOSS_BULLET_SPEED,
            shotY * FoeSpec.BOSS_BULLET_SPEED, false))
    }
}
