package contra.model

import contra.config.*
import sdl.Rect

/*
 * 游戏实体的可变状态。这些是纯"数据袋":字段公开、逻辑放在 contra.sim,
 * 渲染放在 contra.render。因为实体被这些兄弟子包读写,字段需显式 `protected`
 * (仓颉里跨子包成员必须显式放开可见性)。
 */

/* 键鼠事件转换成可逐帧读取的持续状态和单次触发状态。 */
protected class InputState {
    protected var isLeftHeld = false
    protected var isRightHeld = false
    protected var isUpHeld = false
    protected var isDownHeld = false
    protected var isFireHeld = false
    protected var isJumpPressed = false
    protected var isMouseFireHeld = false
    protected var isUsingMouse = false
    protected var mouseX: Float32 = 920.0
    protected var mouseY: Float32 = 320.0
}

/* 一块地面或断桥平台。isBridge 只从上方落地,可从下方穿过。 */
protected class Solid {
    protected let rect: Rect
    protected let isBridge: Bool

    protected init(x: Float32, y: Float32, w: Float32, h: Float32, isBridge!: Bool = false) {
        rect = Rect(x, y, w, h)
        this.isBridge = isBridge
    }
}

protected class Player {
    protected var x: Float32 = HeroSpec.START_X
    protected var y: Float32 = HeroSpec.START_Y
    protected var vx: Float32 = 0.0
    protected var vy: Float32 = 0.0
    protected var facing: Float32 = 1.0
    protected var isOnGround = false
    protected var isCrouching = false
    protected var cooldown: Float32 = 0.0
    protected var invincible: Float32 = 0.0
    protected var muzzleFlash: Float32 = 0.0
    protected var health: Int64 = HeroSpec.MAX_HEALTH
    protected var jumpTapTimer: Float32 = 0.0
    protected var jumpTapCount: Int64 = 0
    protected var coyoteTimer: Float32 = 0.0
    protected var jumpBufferTimer: Float32 = 0.0
    protected var animationPhase: Float32 = 0.0
    protected var animationTime: Float32 = 0.0
    protected var landingBlend: Float32 = 0.0
    protected var recoil: Float32 = 0.0
    protected var aimX: Float32 = 1.0
    protected var aimY: Float32 = 0.0
    protected var weapon: WeaponKind = WeaponKind.Rifle

    func visualRect(): Rect {
        if (isCrouching && isOnGround) {
            return Rect(x, y + HeroSpec.H - HeroSpec.CROUCH_H, HeroSpec.W + 10.0, HeroSpec.CROUCH_H)
        }
        Rect(x, y, HeroSpec.W, HeroSpec.H)
    }

    /* 判定框略收窄,像素轮廓擦边时不会惩罚玩家。 */
    protected func bounds(): Rect {
        let body = visualRect()
        Rect(body.x + 5.0, body.y + 4.0, body.w - 10.0, body.h - 6.0)
    }
}

protected class Bullet {
    protected var rect: Rect
    protected let vx: Float32
    protected let vy: Float32
    protected let isFriendly: Bool
    protected var life: Float32
    protected let damage: Int64

    protected init(x: Float32, y: Float32, vx: Float32, vy: Float32, isFriendly: Bool, damage!: Int64 = 1) {
        let size: Float32 = if (isFriendly) {
            8.0
        } else {
            10.0
        }
        rect = Rect(x - size / 2.0, y - size / 2.0, size, size)
        this.vx = vx
        this.vy = vy
        this.isFriendly = isFriendly
        this.damage = damage
        life = 3.0
    }
}

protected class Enemy {
    protected let kind: EnemyKind
    protected var rect: Rect
    protected let baseX: Float32
    protected let baseY: Float32
    protected var hp: Int64
    protected let maxHp: Int64
    protected var cooldown: Float32
    protected var phase: Float32
    protected var flash: Float32 = 0.0
    protected var isActive = false

    protected init(kind: EnemyKind, x: Float32, y: Float32) {
        let (w, h, health, delay) = enemySpec(kind)
        this.kind = kind
        rect = Rect(x, y, w, h)
        baseX = x
        baseY = y
        hp = health
        maxHp = health
        cooldown = delay
        phase = x * 0.013
    }
}

protected class Pickup {
    protected var rect: Rect
    protected let baseY: Float32
    protected var vy: Float32 = 0.0
    protected var life: Float32 = 18.0
    protected var phase: Float32 = 0.0
    protected var isActive = true

    protected init(x: Float32, y: Float32) {
        rect = Rect(x, y, 34.0, 30.0)
        baseY = y
    }
}

protected class Particle {
    protected var x: Float32
    protected var y: Float32
    protected var vx: Float32
    protected var vy: Float32
    protected var life: Float32
    protected let maxLife: Float32
    protected let isSmoke: Bool

    protected init(x: Float32, y: Float32, vx: Float32, vy: Float32, life: Float32, isSmoke!: Bool = false) {
        this.x = x
        this.y = y
        this.vx = vx
        this.vy = vy
        this.life = life
        maxLife = life
        this.isSmoke = isSmoke
    }
}
