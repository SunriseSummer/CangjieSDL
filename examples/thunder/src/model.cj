package game

import std.collection.ArrayList
import std.random.Random
import sdl.Rect

/* 方向键与开火键的按住状态，事件驱动更新，逐帧读取。 */
class InputState {
    var isLeftHeld = false
    var isRightHeld = false
    var isUpHeld = false
    var isDownHeld = false
    var isFireHeld = false
}

class Star {
    var x: Float32
    var y: Float32
    var speed: Float32
    var size: Float32

    init(x: Float32, y: Float32, speed: Float32, size: Float32) {
        this.x = x
        this.y = y
        this.speed = speed
        this.size = size
    }
}

class Bullet {
    var rect: Rect
    var speed: Float32

    init(x: Float32, y: Float32) {
        rect = Rect(x, y, Shot.W, Shot.H)
        speed = Shot.SPEED
    }
}

class Enemy {
    var rect: Rect
    var speed: Float32
    var hp: Int64

    init(x: Float32, y: Float32, speed: Float32, size: Float32) {
        rect = Rect(x, y, size, size * Foe.HEIGHT_RATIO)
        this.speed = speed
        hp = 1
    }
}

class Particle {
    var x: Float32
    var y: Float32
    var vx: Float32
    var vy: Float32
    var life: Float32
    var maxLife: Float32

    init(x: Float32, y: Float32, vx: Float32, vy: Float32, life: Float32) {
        this.x = x
        this.y = y
        this.vx = vx
        this.vy = vy
        this.life = life
        maxLife = life
    }
}

class Player {
    var rect = Ship.START
    var cooldown: Float32 = 0.0
    var lives: Int64 = Ship.LIVES
    var invincible: Float32 = 0.0

    /* 受击判定框比机身小一圈，容错更友好。 */
    func bounds(): Rect {
        Rect(rect.x + Ship.HITBOX_X, rect.y + Ship.HITBOX_TOP, rect.w - Ship.HITBOX_W, rect.h - Ship.HITBOX_H)
    }
}

class GameState {
    let rng = Random()
    let input = InputState()
    let player = Player()
    let stars = ArrayList<Star>()
    let bullets = ArrayList<Bullet>()
    let enemies = ArrayList<Enemy>()
    let particles = ArrayList<Particle>()
    var score: Int64 = 0
    var spawnTimer: Float32 = 0.0
    var isRunning = true
    var isOver = false

    init() {
        for (_ in 0..Stars.COUNT) {
            stars.add(newStar(rng))
        }
    }
}

func newStar(rng: Random): Star {
    Star(
        randRange(rng, 0.0, Stage.WIDTH_F),
        randRange(rng, 0.0, Stage.HEIGHT_F),
        randRange(rng, Stars.MIN_SPEED, Stars.MAX_SPEED),
        randRange(rng, Stars.MIN_SIZE, Stars.MAX_SIZE)
    )
}

func resetGame(state: GameState): Unit {
    state.player.rect = Ship.START
    state.player.lives = Ship.LIVES
    state.player.cooldown = 0.0
    state.player.invincible = Ship.RESPAWN_INVINCIBLE
    state.score = 0
    state.spawnTimer = 0.0
    state.isOver = false
    state.bullets.clear()
    state.enemies.clear()
    state.particles.clear()
}
