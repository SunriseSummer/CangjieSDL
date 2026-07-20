package contra.model

import contra.config.*

/*
 * 游戏中出现的"种类"枚举,以及围绕它们的纯判定/查表函数。
 *
 * 把 "boss 是不是 boss"、"某种敌人的体型/血量/得分" 这类分类知识集中在一处,
 * 逻辑层与渲染层只调具名函数,不散写 match,新增敌种时改这一个文件即可。
 */

/* 关卡阶段:进行中 / 通关 / 失败。 */
protected enum GamePhase {
    | Playing
    | Won
    | Lost
}

/* 武器:步枪(单发)/ 扩散枪(三向)。 */
protected enum WeaponKind {
    | Rifle
    | Spread
}

/* 敌人种类。 */
protected enum EnemyKind {
    | Grunt
    | Turret
    | Drone
    | Boss
}

protected func isPlaying(phase: GamePhase): Bool {
    match (phase) {
        case GamePhase.Playing => true
        case _ => false
    }
}

protected func isWon(phase: GamePhase): Bool {
    match (phase) {
        case GamePhase.Won => true
        case _ => false
    }
}

protected func hasSpread(kind: WeaponKind): Bool {
    match (kind) {
        case WeaponKind.Spread => true
        case _ => false
    }
}

protected func isBoss(kind: EnemyKind): Bool {
    match (kind) {
        case EnemyKind.Boss => true
        case _ => false
    }
}

protected func isDrone(kind: EnemyKind): Bool {
    match (kind) {
        case EnemyKind.Drone => true
        case _ => false
    }
}

protected func isTurret(kind: EnemyKind): Bool {
    match (kind) {
        case EnemyKind.Turret => true
        case _ => false
    }
}

/* 敌种的出生属性:(宽, 高, 血量, 首次开火延迟)。 */
func enemySpec(kind: EnemyKind): (Float32, Float32, Int64, Float32) {
    match (kind) {
        case EnemyKind.Grunt => (42.0, 58.0, FoeSpec.GRUNT_HP, 0.8)
        case EnemyKind.Turret => (54.0, 50.0, FoeSpec.TURRET_HP, 1.0)
        case EnemyKind.Drone => (64.0, 38.0, FoeSpec.DRONE_HP, 0.65)
        case EnemyKind.Boss => (FoeSpec.BOSS_W, FoeSpec.BOSS_H, FoeSpec.BOSS_HP, 1.4)
    }
}

/* 击毁一个敌人的得分。 */
protected func enemyPoints(kind: EnemyKind): Int64 {
    match (kind) {
        case EnemyKind.Grunt => 100
        case EnemyKind.Turret => 240
        case EnemyKind.Drone => 180
        case EnemyKind.Boss => 5000
    }
}
