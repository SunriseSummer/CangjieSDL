package contra.sim

import contra.model.*

/*
 * contra.sim —— 游戏世界的逐帧模拟(纯逻辑,不碰渲染)。
 *
 * 一帧的推进顺序集中在这里:先推进与胜负无关的粒子/震屏,再在"进行中"时依次
 * 推进玩家、镜头、子弹、敌人、补给,最后统一结算碰撞。拆分:player(玩家物理与
 * 战斗)、foes(敌人 AI 与弹幕)、effects(镜头/子弹/补给/粒子/震屏)、collision(结算)。
 * 只有 update 对外;loop 每帧调它一次。
 */
protected func update(state: GameState, dt: Float32): Unit {
    state.elapsed += dt
    updateParticles(state, dt)
    updateScreenShake(state, dt)

    if (!isPlaying(state.phase)) {
        state.input.isJumpPressed = false
        return
    }

    updatePlayer(state, dt)
    updateCamera(state, dt)
    updateBullets(state, dt)
    updateEnemies(state, dt)
    updatePickups(state, dt)
    handleCollisions(state)
    state.input.isJumpPressed = false
}
