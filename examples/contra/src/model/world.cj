package contra.model

import contra.config.*
import std.collection.ArrayList
import std.random.Random

/*
 * 世界状态容器与关卡编队。GameState 聚合一局游戏的全部可变数据;逻辑层
 * (contra.sim)按帧推进它,渲染层(contra.render)只读它。
 */
protected class GameState {
    protected let rng = Random()
    protected let input = InputState()
    protected var player = Player()
    protected let solids = ArrayList<Solid>()
    protected let bullets = ArrayList<Bullet>()
    protected let enemies = ArrayList<Enemy>()
    protected let pickups = ArrayList<Pickup>()
    protected let particles = ArrayList<Particle>()
    protected var phase: GamePhase = GamePhase.Playing
    protected var isRunning = true
    protected var score: Int64 = 0
    protected var cameraX: Float32 = 0.0
    protected var elapsed: Float32 = 0.0
    protected var screenShake: Float32 = 0.0
    protected var bossAwake = false
    protected var hasPlayerMoved = false

    protected init() {
        buildLevel(this)
    }
}

/* 当前朝向的单位瞄准向量。渲染与射击共用它,保证枪口与弹道一致。 */
protected func playerAim(state: GameState): (Float32, Float32) {
    (state.player.aimX, state.player.aimY)
}

/* 铺设本关的地形、断桥、敌人编队和补给。坐标为世界坐标。 */
func buildLevel(state: GameState): Unit {
    state.solids.add(Solid(-200.0, 582.0, 1770.0, 180.0))
    state.solids.add(Solid(1580.0, 548.0, 190.0, 24.0, isBridge: true))
    state.solids.add(Solid(1800.0, 548.0, 180.0, 24.0, isBridge: true))
    state.solids.add(Solid(2020.0, 582.0, 1510.0, 180.0))
    state.solids.add(Solid(3520.0, 532.0, 300.0, 230.0))
    state.solids.add(Solid(3840.0, 582.0, 2760.0, 180.0))
    state.solids.add(Solid(650.0, 455.0, 240.0, 24.0, isBridge: true))
    state.solids.add(Solid(1170.0, 410.0, 220.0, 24.0, isBridge: true))
    state.solids.add(Solid(2350.0, 448.0, 270.0, 24.0, isBridge: true))
    state.solids.add(Solid(3000.0, 392.0, 230.0, 24.0, isBridge: true))
    state.solids.add(Solid(4090.0, 450.0, 240.0, 24.0, isBridge: true))
    state.solids.add(Solid(4640.0, 398.0, 220.0, 24.0, isBridge: true))

    addEnemy(state, EnemyKind.Grunt, 840.0, 397.0)
    addEnemy(state, EnemyKind.Grunt, 1160.0, 524.0)
    addEnemy(state, EnemyKind.Turret, 1330.0, 360.0)
    addEnemy(state, EnemyKind.Drone, 1510.0, 285.0)
    addEnemy(state, EnemyKind.Grunt, 1860.0, 490.0)
    addEnemy(state, EnemyKind.Grunt, 2160.0, 524.0)
    addEnemy(state, EnemyKind.Turret, 2460.0, 398.0)
    addEnemy(state, EnemyKind.Drone, 2730.0, 250.0)
    addEnemy(state, EnemyKind.Grunt, 2900.0, 524.0)
    addEnemy(state, EnemyKind.Grunt, 3070.0, 334.0)
    addEnemy(state, EnemyKind.Turret, 3370.0, 532.0)
    addEnemy(state, EnemyKind.Drone, 3650.0, 230.0)
    addEnemy(state, EnemyKind.Grunt, 3990.0, 524.0)
    addEnemy(state, EnemyKind.Turret, 4180.0, 400.0)
    addEnemy(state, EnemyKind.Grunt, 4500.0, 524.0)
    addEnemy(state, EnemyKind.Drone, 4770.0, 250.0)
    addEnemy(state, EnemyKind.Grunt, 5030.0, 524.0)
    addEnemy(state, EnemyKind.Turret, 5260.0, 532.0)
    addEnemy(state, EnemyKind.Grunt, 5480.0, 524.0)
    addEnemy(state, EnemyKind.Boss, FoeSpec.BOSS_X, FoeSpec.BOSS_Y)

    state.pickups.add(Pickup(1340.0, 326.0))
    state.pickups.add(Pickup(3150.0, 344.0))
}

func addEnemy(state: GameState, kind: EnemyKind, x: Float32, y: Float32): Unit {
    state.enemies.add(Enemy(kind, x, y))
}

/* 重开直接换一个全新 Player,字段默认值只在类定义处维护一份。 */
protected func resetGame(state: GameState): Unit {
    state.player = Player()
    state.phase = GamePhase.Playing
    state.score = 0
    state.cameraX = 0.0
    state.elapsed = 0.0
    state.screenShake = 0.0
    state.bossAwake = false
    state.hasPlayerMoved = false
    state.bullets.clear()
    state.enemies.clear()
    state.pickups.clear()
    state.particles.clear()
    buildLevel(state)
}
