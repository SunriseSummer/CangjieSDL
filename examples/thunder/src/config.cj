package game

import sdl.FontSizes
import sdl.Rect

/* 舞台：窗口尺寸与帧循环参数。 */
struct Stage {
    static let TITLE: String = "Cangjie SDL Thunder Fighter"
    static let WIDTH: Int32 = 800
    static let HEIGHT: Int32 = 600
    static let WIDTH_F: Float32 = 800.0
    static let HEIGHT_F: Float32 = 600.0
    static let FRAME_DELAY_MS: UInt32 = 1
    static let MS_PER_SECOND: Float32 = 1000.0
    static let MAX_DELTA: Float32 = 0.05
    static let STRIPE_STEP: Float32 = 12.0
}

/* 背景星空滚动参数。 */
struct Stars {
    static let COUNT: Int64 = 96
    static let RESET_Y: Float32 = 604.0
    static let SPAWN_Y: Float32 = -8.0
    static let MIN_SPEED: Float32 = 40.0
    static let MAX_SPEED: Float32 = 220.0
    static let MIN_SIZE: Float32 = 1.0
    static let MAX_SIZE: Float32 = 3.4
}

/* 玩家战机：移动速度、活动范围、开火冷却与受击无敌时间。 */
struct Ship {
    static let START: Rect = Rect(381.0, 500.0, 38.0, 48.0)
    static let LIVES: Int64 = 3
    static let FAST_SPEED: Float32 = 330.0
    static let FOCUS_SPEED: Float32 = 250.0
    static let MARGIN: Float32 = 18.0
    static let TOP_LIMIT: Float32 = 150.0
    static let BOTTOM_MARGIN: Float32 = 18.0
    static let FIRE_COOLDOWN: Float32 = 0.13
    static let RESPAWN_INVINCIBLE: Float32 = 1.5
    static let HIT_INVINCIBLE: Float32 = 1.4
    static let BLINK_RATE: Float32 = 16.0
    static let HITBOX_X: Float32 = 5.0
    static let HITBOX_TOP: Float32 = 6.0
    static let HITBOX_W: Float32 = 10.0
    static let HITBOX_H: Float32 = 8.0
}

/* 子弹：尺寸、速度与三发弹道的相对出膛位置。 */
struct Shot {
    static let W: Float32 = 5.0
    static let H: Float32 = 18.0
    static let SPEED: Float32 = 640.0
    static let VANISH_Y: Float32 = -20.0
    static let NOSE_Y: Float32 = -12.0
    static let SIDE_Y: Float32 = 5.0
    static let LEFT_X: Float32 = -17.5
    static let RIGHT_X: Float32 = 12.5
    static let RADIUS: Float32 = 2.5
    static let GLOW_X: Float32 = 3.0
    static let GLOW_Y: Float32 = 4.0
}

/* 敌机：体型与速度区间、蛇形摆动和随分数收紧的刷新间隔。 */
struct Foe {
    static let MIN_SIZE: Float32 = 32.0
    static let MAX_SIZE: Float32 = 54.0
    static let MIN_SPEED: Float32 = 70.0
    static let MAX_SPEED: Float32 = 165.0
    static let SPAWN_Y: Float32 = -70.0
    static let MARGIN: Float32 = 28.0
    static let VANISH_Y: Float32 = 640.0
    static let HEIGHT_RATIO: Float32 = 0.78
    static let WOBBLE_PHASE: Float64 = 0.025
    static let WOBBLE_SPEED: Float32 = 45.0
    static let SPAWN_INTERVAL: Float32 = 0.82
    static let MIN_INTERVAL: Float32 = 0.24
    static let SCORE_FACTOR: Float32 = 0.004
    static let POINTS: Int64 = 10
    static let GLOW: Float32 = 3.0
}

/* 爆炸粒子效果。 */
struct Fx {
    static let GRAVITY: Float32 = 160.0
    static let DESTROY_COUNT: Int64 = 18
    static let HIT_COUNT: Int64 = 28
    static let MIN_SPEED: Float32 = 60.0
    static let MAX_SPEED: Float32 = 260.0
    static let MIN_LIFE: Float32 = 0.28
    static let MAX_LIFE: Float32 = 0.72
    static let SPARK_SIZE: Float32 = 4.0
    static let TAU: Float32 = 6.28318
    static let FULL_ALPHA: Float32 = 255.0
}

/* HUD 与结算界面布局。 */
struct Hud {
    static let BOX: Rect = Rect(18.0, 16.0, 220.0, 54.0)
    static let RADIUS: Float32 = 10.0
    static let SCORE_X: Float32 = 32.0
    static let LIFE_X: Float32 = 610.0
    static let TEXT_Y: Float32 = 32.0
    static let TEXT_SIZE: Float32 = FontSizes.BODY
    static let OVER_BOX: Rect = Rect(130.0, 210.0, 540.0, 170.0)
    static let OVER_RADIUS: Float32 = 16.0
    static let OVER_TITLE_RECT: Rect = Rect(130.0, 240.0, 540.0, 44.0)
    static let OVER_TITLE_SIZE: Float32 = FontSizes.DISPLAY
    static let OVER_HINT_RECT: Rect = Rect(130.0, 312.0, 540.0, 22.0)
    static let OVER_HINT_SIZE: Float32 = FontSizes.BODY
}
