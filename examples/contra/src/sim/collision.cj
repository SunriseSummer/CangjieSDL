package contra.sim

import contra.config.*
import contra.geom.*
import contra.model.*

/*
 * 每帧末尾的碰撞结算:友方子弹打敌人、敌方子弹/身体伤玩家、拾取补给。
 * 玩家判定框略小于视觉轮廓(见 Player.bounds),擦边不惩罚;受击后短暂无敌。
 * 跌落水域按 shouldRespawn 送回最近检查点,只扣一格而非直接判负。
 */
func handleCollisions(state: GameState): Unit {
    collideFriendlyBullets(state)
    collideEnemyBullets(state)
    collideEnemyBodies(state)
    collectPickups(state)
}

func collideFriendlyBullets(state: GameState): Unit {
    var bulletIndex = state.bullets.size - 1
    while (bulletIndex >= 0) {
        let bullet = state.bullets[bulletIndex]
        if (bullet.isFriendly) {
            hitEnemyWithBullet(state, bullet, bulletIndex)
        }
        bulletIndex -= 1
    }
}

func hitEnemyWithBullet(state: GameState, bullet: Bullet, bulletIndex: Int64): Unit {
    var enemyIndex = state.enemies.size - 1
    while (enemyIndex >= 0) {
        let enemy = state.enemies[enemyIndex]
        if (enemy.isActive && intersects(bullet.rect, enemy.rect)) {
            state.bullets.remove(at: bulletIndex)
            enemy.hp -= bullet.damage
            enemy.flash = 0.08
            burst(state, bullet.rect.centerX(), bullet.rect.centerY(), FxSpec.HIT_COUNT)
            if (enemy.hp <= 0) {
                destroyEnemy(state, enemy, enemyIndex)
            }
            return
        }
        enemyIndex -= 1
    }
}

func destroyEnemy(state: GameState, enemy: Enemy, enemyIndex: Int64): Unit {
    let count = if (isBoss(enemy.kind)) {
        FxSpec.BOSS_COUNT
    } else {
        FxSpec.DESTROY_COUNT
    }
    burst(state, enemy.rect.centerX(), enemy.rect.centerY(), count)
    state.enemies.remove(at: enemyIndex)
    state.score += enemyPoints(enemy.kind)
    if (isBoss(enemy.kind)) {
        state.screenShake = 1.0
        state.phase = GamePhase.Won
    } else {
        state.screenShake = 0.16
    }
}

func collideEnemyBullets(state: GameState): Unit {
    if (state.player.invincible > 0.0) {
        return
    }

    let playerBounds = state.player.bounds()
    var bulletIndex = state.bullets.size - 1
    while (bulletIndex >= 0) {
        let bullet = state.bullets[bulletIndex]
        if (!bullet.isFriendly && intersects(bullet.rect, playerBounds)) {
            state.bullets.remove(at: bulletIndex)
            damagePlayer(state)
            return
        }
        bulletIndex -= 1
    }
}

func collideEnemyBodies(state: GameState): Unit {
    if (state.player.invincible > 0.0) {
        return
    }

    let playerBounds = state.player.bounds()
    var enemyIndex = state.enemies.size - 1
    while (enemyIndex >= 0) {
        let enemy = state.enemies[enemyIndex]
        if (enemy.isActive && intersects(enemy.rect, playerBounds)) {
            if (!isBoss(enemy.kind)) {
                burst(state, enemy.rect.centerX(), enemy.rect.centerY(), FxSpec.DESTROY_COUNT)
                state.enemies.remove(at: enemyIndex)
            }
            damagePlayer(state)
            return
        }
        enemyIndex -= 1
    }
}

func collectPickups(state: GameState): Unit {
    let playerBounds = state.player.bounds()
    for (pickup in state.pickups) {
        if (pickup.isActive && intersects(pickup.rect, playerBounds)) {
            pickup.isActive = false
            state.player.weapon = WeaponKind.Spread
            state.score += 350
            burst(state, pickup.rect.centerX(), pickup.rect.centerY(), FxSpec.DESTROY_COUNT)
        }
    }
}

func damagePlayer(state: GameState, shouldRespawn!: Bool = false): Unit {
    let player = state.player
    if (player.invincible > 0.0 || !isPlaying(state.phase)) {
        return
    }

    burst(state, player.x + HeroSpec.W / 2.0, player.y + HeroSpec.H / 2.0, FxSpec.DESTROY_COUNT)
    state.screenShake = 0.45
    player.health -= 1
    player.invincible = HeroSpec.HIT_INVINCIBLE
    if (player.health <= 0) {
        state.phase = GamePhase.Lost
        return
    }
    if (shouldRespawn) {
        player.x = respawnX(player.x)
        player.y = 470.0
        player.vx = 0.0
        player.vy = 0.0
    } else {
        player.vx = -player.facing * HeroSpec.KNOCKBACK_X
        player.vy = -HeroSpec.KNOCKBACK_Y
    }
}

/* 跌落水域后送回最近一段安全地面的检查点。 */
func respawnX(x: Float32): Float32 {
    match {
        case x > 4300.0 => 3970.0
        case x > 2500.0 => 2120.0
        case x > 1250.0 => 920.0
        case _ => HeroSpec.START_X
    }
}
