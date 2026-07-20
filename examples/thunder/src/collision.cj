package game

func handleCollisions(state: GameState): Unit {
    var ei = state.enemies.size - 1
    while (ei >= 0) {
        let enemy = state.enemies[ei]
        let isDestroyed = hitByBullets(state, enemy, ei)

        if (!isDestroyed && canHitPlayer(state, enemy)) {
            hitPlayer(state, enemy, ei)
        }
        ei -= 1
    }
}

func hitByBullets(state: GameState, enemy: Enemy, enemyIndex: Int64): Bool {
    var bi = state.bullets.size - 1
    while (bi >= 0) {
        let bullet = state.bullets[bi]
        if (intersects(bullet.rect, enemy.rect)) {
            state.bullets.remove(at: bi)
            enemy.hp -= 1
            if (enemy.hp <= 0) {
                destroyEnemy(state, enemy, enemyIndex)
                return true
            }
        }
        bi -= 1
    }
    false
}

func destroyEnemy(state: GameState, enemy: Enemy, index: Int64): Unit {
    burst(state, enemy.rect.centerX(), enemy.rect.centerY(), Fx.DESTROY_COUNT)
    state.enemies.remove(at: index)
    state.score += Foe.POINTS
}

func canHitPlayer(state: GameState, enemy: Enemy): Bool {
    state.player.invincible <= 0.0 && intersects(state.player.bounds(), enemy.rect)
}

func hitPlayer(state: GameState, enemy: Enemy, index: Int64): Unit {
    burst(state, enemy.rect.centerX(), enemy.rect.centerY(), Fx.HIT_COUNT)
    state.enemies.remove(at: index)
    state.player.invincible = Ship.HIT_INVINCIBLE
    loseLife(state)
}

func loseLife(state: GameState): Unit {
    state.player.lives -= 1
    if (state.player.lives <= 0) {
        state.isOver = true
    }
}
