package contra.sim

import contra.config.*
import contra.geom.*
import contra.model.*
import std.math.cos
import std.math.sin
import sdl.clampF32

/*
 * 世界杂项推进:镜头平滑跟随(Boss 区自动锁定)、子弹飞行与出界回收、补给漂浮、
 * 粒子重力衰减、命中/爆炸的粒子迸发、屏幕震动衰减。
 */
func updateCamera(state: GameState, dt: Float32): Unit {
    let target = clampF32(state.player.x - Stage.CAMERA_LEAD, 0.0, Stage.CAMERA_MAX)
    state.cameraX = approach(state.cameraX, target, Stage.CAMERA_SPEED * dt)
    if (state.bossAwake) {
        state.cameraX = approach(state.cameraX, Stage.CAMERA_MAX, Stage.CAMERA_BOSS_SPEED * dt)
    }
}

func updateBullets(state: GameState, dt: Float32): Unit {
    var index = state.bullets.size - 1
    while (index >= 0) {
        let bullet = state.bullets[index]
        bullet.rect.x += bullet.vx * dt
        bullet.rect.y += bullet.vy * dt
        bullet.life -= dt
        let isOutside = bullet.rect.right() < state.cameraX - 220.0 || bullet.rect.x > state.cameraX + Stage.WIDTH_F +
            220.0 || bullet.rect.bottom() < -100.0 || bullet.rect.y > Stage.HEIGHT_F + 120.0
        if (bullet.life <= 0.0 || isOutside) {
            state.bullets.remove(at: index)
        }
        index -= 1
    }
}

func updatePickups(state: GameState, dt: Float32): Unit {
    for (pickup in state.pickups) {
        if (!pickup.isActive) {
            continue
        }
        pickup.phase += dt * 2.6
        pickup.life -= dt
        pickup.rect.y = pickup.baseY + Float32(sin(Float64(pickup.phase))) * 9.0
        if (pickup.life <= 0.0) {
            pickup.isActive = false
        }
    }
}

func updateParticles(state: GameState, dt: Float32): Unit {
    var index = state.particles.size - 1
    while (index >= 0) {
        let particle = state.particles[index]
        particle.x += particle.vx * dt
        particle.y += particle.vy * dt
        particle.vy += FxSpec.GRAVITY * dt
        particle.life -= dt
        if (particle.life <= 0.0) {
            state.particles.remove(at: index)
        }
        index -= 1
    }
}

/* 在 (x, y) 迸发 count 个四散粒子,每 5 个掺一个上飘烟雾。 */
protected func burst(state: GameState, x: Float32, y: Float32, count: Int64): Unit {
    for (index in 0..count) {
        let angle = randRange(state.rng, 0.0, TAU)
        let speed = randRange(state.rng, FxSpec.MIN_SPEED, FxSpec.MAX_SPEED)
        let vx = Float32(cos(Float64(angle))) * speed
        let vy = Float32(sin(Float64(angle))) * speed
        let life = randRange(state.rng, FxSpec.MIN_LIFE, FxSpec.MAX_LIFE)
        state.particles.add(Particle(x, y, vx, vy, life, isSmoke: index % 5 == 0))
    }
}

func updateScreenShake(state: GameState, dt: Float32): Unit {
    if (state.screenShake > 0.0) {
        state.screenShake -= dt
    }
}
