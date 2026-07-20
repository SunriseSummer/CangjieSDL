package game

import std.math.cos
import std.math.sin
import sdl.clampF32

func update(state: GameState, dt: Float32): Unit {
    updateStars(state, dt)
    updateParticles(state, dt)

    if (state.isOver) {
        return
    }

    updatePlayer(state, dt)
    updateBullets(state, dt)
    updateEnemies(state, dt)
    handleCollisions(state)
}

func updateStars(state: GameState, dt: Float32): Unit {
    for (star in state.stars) {
        star.y += star.speed * dt
        if (star.y > Stars.RESET_Y) {
            star.x = randRange(state.rng, 0.0, Stage.WIDTH_F)
            star.y = Stars.SPAWN_Y
            star.speed = randRange(state.rng, Stars.MIN_SPEED, Stars.MAX_SPEED)
            star.size = randRange(state.rng, Stars.MIN_SIZE, Stars.MAX_SIZE)
        }
    }
}

func updatePlayer(state: GameState, dt: Float32): Unit {
    let player = state.player
    // 按住开火时降速，方便精确走位
    let speed = if (state.input.isFireHeld) {
        Ship.FOCUS_SPEED
    } else {
        Ship.FAST_SPEED
    }

    if (state.input.isLeftHeld) {
        player.rect.x -= speed * dt
    }
    if (state.input.isRightHeld) {
        player.rect.x += speed * dt
    }
    if (state.input.isUpHeld) {
        player.rect.y -= speed * dt
    }
    if (state.input.isDownHeld) {
        player.rect.y += speed * dt
    }

    player.rect.x = clampF32(player.rect.x, Ship.MARGIN, Stage.WIDTH_F - player.rect.w - Ship.MARGIN)
    player.rect.y = clampF32(player.rect.y, Ship.TOP_LIMIT, Stage.HEIGHT_F - player.rect.h - Ship.BOTTOM_MARGIN)

    if (player.cooldown > 0.0) {
        player.cooldown -= dt
    }
    if (player.invincible > 0.0) {
        player.invincible -= dt
    }
    if (state.input.isFireHeld && player.cooldown <= 0.0) {
        fire(state)
    }
}

func fire(state: GameState): Unit {
    let ship = state.player.rect
    let cx = ship.centerX()

    state.bullets.add(Bullet(cx - Shot.W / 2.0, ship.y + Shot.NOSE_Y))
    state.bullets.add(Bullet(cx + Shot.LEFT_X, ship.y + Shot.SIDE_Y))
    state.bullets.add(Bullet(cx + Shot.RIGHT_X, ship.y + Shot.SIDE_Y))
    state.player.cooldown = Ship.FIRE_COOLDOWN
}

func updateBullets(state: GameState, dt: Float32): Unit {
    var i = state.bullets.size - 1
    while (i >= 0) {
        let bullet = state.bullets[i]
        bullet.rect.y -= bullet.speed * dt
        if (bullet.rect.bottom() < Shot.VANISH_Y) {
            state.bullets.remove(at: i)
        }
        i -= 1
    }
}

func updateEnemies(state: GameState, dt: Float32): Unit {
    state.spawnTimer -= dt
    if (state.spawnTimer <= 0.0) {
        spawnEnemy(state)
    }

    var i = state.enemies.size - 1
    while (i >= 0) {
        let enemy = state.enemies[i]
        enemy.rect.y += enemy.speed * dt
        enemy.rect.x += wobble(enemy.rect.y) * dt

        // 敌机突破底线按漏防处理，扣一条命
        if (enemy.rect.y > Foe.VANISH_Y) {
            state.enemies.remove(at: i)
            loseLife(state)
        }
        i -= 1
    }
}

func spawnEnemy(state: GameState): Unit {
    let size = randRange(state.rng, Foe.MIN_SIZE, Foe.MAX_SIZE)
    let x = randRange(state.rng, Foe.MARGIN, Stage.WIDTH_F - size - Foe.MARGIN)
    let speed = randRange(state.rng, Foe.MIN_SPEED, Foe.MAX_SPEED)

    state.enemies.add(Enemy(x, Foe.SPAWN_Y, speed, size))
    state.spawnTimer = nextSpawnDelay(state.score)
}

/* 分数越高刷新越快，构成难度曲线。 */
func nextSpawnDelay(score: Int64): Float32 {
    let delay = Foe.SPAWN_INTERVAL - Float32(score) * Foe.SCORE_FACTOR
    clampF32(delay, Foe.MIN_INTERVAL, Foe.SPAWN_INTERVAL)
}

/* 以纵坐标为相位做正弦横移，敌机呈蛇形下压。 */
func wobble(y: Float32): Float32 {
    Float32(sin(Float64(y) * Foe.WOBBLE_PHASE)) * Foe.WOBBLE_SPEED
}

func updateParticles(state: GameState, dt: Float32): Unit {
    var i = state.particles.size - 1
    while (i >= 0) {
        let p = state.particles[i]
        p.x += p.vx * dt
        p.y += p.vy * dt
        p.vy += Fx.GRAVITY * dt
        p.life -= dt
        if (p.life <= 0.0) {
            state.particles.remove(at: i)
        }
        i -= 1
    }
}

func burst(state: GameState, x: Float32, y: Float32, count: Int64): Unit {
    for (_ in 0..count) {
        let angle = randRange(state.rng, 0.0, Fx.TAU)
        let speed = randRange(state.rng, Fx.MIN_SPEED, Fx.MAX_SPEED)
        let vx = Float32(cos(Float64(angle))) * speed
        let vy = Float32(sin(Float64(angle))) * speed
        let life = randRange(state.rng, Fx.MIN_LIFE, Fx.MAX_LIFE)

        state.particles.add(Particle(x, y, vx, vy, life))
    }
}
