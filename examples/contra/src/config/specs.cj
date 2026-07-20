package contra.config

import sdl.FontSizes
import sdl.Rect

/*
 * 集中调参层。所有可调数值都以命名常量的形式收在这里,而不是散落在逻辑里的
 * "魔法数",这样调平衡、教学演示、改手感都只改这一处。每个常量都显式标注
 * `protected`——仓颉里跨子包访问的成员必须显式放开可见性,`protected` 表示
 * "本模块(应用)内可见",正合本项目"内部约定、非对外 API"的定位。
 */

/* 逻辑画布、关卡边界与帧循环参数。 */
protected struct Stage {
    protected static let TITLE: String = "Neon Commando - Cangjie SDL"
    protected static let WIDTH: Int32 = 1280
    protected static let HEIGHT: Int32 = 720
    protected static let WIDTH_F: Float32 = 1280.0
    protected static let HEIGHT_F: Float32 = 720.0
    protected static let WORLD_WIDTH: Float32 = 6400.0
    protected static let CAMERA_LEAD: Float32 = 390.0
    protected static let CAMERA_MAX: Float32 = 5120.0
    protected static let CAMERA_SPEED: Float32 = 520.0
    protected static let CAMERA_BOSS_SPEED: Float32 = 720.0
    protected static let FRAME_DELAY_MS: UInt32 = 1
    protected static let MS_PER_SECOND: Float32 = 1000.0
    protected static let MAX_DELTA: Float32 = 0.04
    protected static let WATER_Y: Float32 = 598.0
    protected static let FALL_LIMIT: Float32 = 790.0
    protected static let INTRO_TIME: Float32 = 3.5
}

/* 玩家运动、战斗和受击调参。 */
protected struct HeroSpec {
    protected static let START_X: Float32 = 150.0
    protected static let START_Y: Float32 = 520.0
    protected static let W: Float32 = 38.0
    protected static let H: Float32 = 62.0
    protected static let CROUCH_H: Float32 = 36.0
    protected static let RUN_SPEED: Float32 = 285.0
    protected static let RUN_ACCEL: Float32 = 1800.0
    protected static let AIR_CONTROL: Float32 = 0.82
    protected static let JUMP_SPEED: Float32 = 510.0
    protected static let JUMP_BOOST: Float32 = 105.0
    protected static let JUMP_TAP_WINDOW: Float32 = 0.52
    protected static let MAX_JUMP_TAPS: Int64 = 3
    protected static let COYOTE_TIME: Float32 = 0.11
    protected static let JUMP_BUFFER_TIME: Float32 = 0.12
    protected static let GRAVITY: Float32 = 1720.0
    protected static let MAX_FALL_SPEED: Float32 = 900.0
    protected static let MAX_HEALTH: Int64 = 5
    protected static let HIT_INVINCIBLE: Float32 = 1.0
    protected static let BLINK_RATE: Float32 = 18.0
    protected static let RIFLE_COOLDOWN: Float32 = 0.14
    protected static let SPREAD_COOLDOWN: Float32 = 0.22
    protected static let BULLET_SPEED: Float32 = 760.0
    protected static let MAX_X_BEFORE_BOSS: Float32 = 5480.0
    protected static let KNOCKBACK_X: Float32 = 260.0
    protected static let KNOCKBACK_Y: Float32 = 250.0
    protected static let RUN_CYCLE_PER_PIXEL: Float32 = 0.055
    protected static let AIM_RESPONSE: Float32 = 18.0
    protected static let RECOIL_RECOVERY: Float32 = 11.0
    protected static let LANDING_RECOVERY: Float32 = 7.5
}

/* 武器纹理比例与骨架约束。枪口偏移同时用于渲染和弹道,保证视觉与命中一致。 */
protected struct WeaponSpec {
    protected static let DRAW_WIDTH: Float32 = 96.0
    protected static let DRAW_HEIGHT: Float32 = 31.0
    protected static let PIVOT_X: Float32 = 39.0
    protected static let STOCK_TO_GRIP: Float32 = 36.0
    protected static let RECOIL_SLIDE: Float32 = 4.5
    protected static let MUZZLE_OFFSET: Float32 = 55.0
    protected static let MUZZLE_LIFT: Float32 = -2.8
    protected static let SUPPORT_GRIP_OFFSET: Float32 = 30.0
}

/* 敌人与 Boss 的难度曲线。 */
protected struct FoeSpec {
    protected static let GRUNT_SPEED: Float32 = 92.0
    protected static let GRUNT_PATROL_RANGE: Float32 = 105.0
    protected static let GRUNT_HP: Int64 = 3
    protected static let TURRET_HP: Int64 = 7
    protected static let DRONE_HP: Int64 = 4
    protected static let DRONE_DRIFT_SPEED: Float32 = 22.0
    protected static let DRONE_BOB_RANGE: Float32 = 54.0
    protected static let DRONE_BOB_RATE: Float32 = 2.7
    protected static let BOSS_HP: Int64 = 72
    protected static let ALERT_DISTANCE: Float32 = 820.0
    protected static let SHOT_DISTANCE: Float32 = 680.0
    protected static let BULLET_SPEED: Float32 = 285.0
    protected static let MIN_FIRE_DELAY: Float32 = 1.15
    protected static let MAX_FIRE_DELAY: Float32 = 2.15
    protected static let BOSS_TRIGGER_X: Float32 = 5200.0
    protected static let BOSS_FIRE_DELAY: Float32 = 0.72
    protected static let BOSS_BULLET_SPEED: Float32 = 330.0
    protected static let BOSS_X: Float32 = 5790.0
    protected static let BOSS_Y: Float32 = 346.0
    protected static let BOSS_W: Float32 = 184.0
    protected static let BOSS_H: Float32 = 250.0
}

/* 粒子、命中特效与屏幕提示。 */
protected struct FxSpec {
    protected static let GRAVITY: Float32 = 520.0
    protected static let MIN_SPEED: Float32 = 70.0
    protected static let MAX_SPEED: Float32 = 310.0
    protected static let MIN_LIFE: Float32 = 0.24
    protected static let MAX_LIFE: Float32 = 0.72
    protected static let HIT_COUNT: Int64 = 8
    protected static let DESTROY_COUNT: Int64 = 22
    protected static let BOSS_COUNT: Int64 = 72
    protected static let FULL_ALPHA: Float32 = 255.0
}

/* HUD 与结算面板布局。 */
protected struct HudSpec {
    protected static let TOP_BAR: Rect = Rect(22.0, 18.0, 1236.0, 62.0)
    protected static let BAR_RADIUS: Float32 = 12.0
    protected static let TEXT_Y: Float32 = 36.0
    protected static let BODY: Float32 = FontSizes.BODY
    protected static let TITLE: Float32 = FontSizes.DISPLAY
    protected static let BOSS_BAR: Rect = Rect(420.0, 94.0, 440.0, 18.0)
    protected static let PANEL: Rect = Rect(260.0, 206.0, 760.0, 276.0)
    protected static let PANEL_RADIUS: Float32 = 18.0
    protected static let PANEL_TITLE: Rect = Rect(260.0, 252.0, 760.0, 60.0)
    protected static let PANEL_SUBTITLE: Rect = Rect(260.0, 330.0, 760.0, 32.0)
    protected static let PANEL_HINT: Rect = Rect(260.0, 404.0, 760.0, 28.0)
}
