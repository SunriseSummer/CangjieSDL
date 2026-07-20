package contra.render

import contra.config.*
import contra.model.*
import std.math.floor
import std.math.sin
import sdl.Color
import sdl.Rect
import sdl.Renderer
import sdl.clampF32

/*
 * 帧渲染入口与全局坐标工具。draw 按远及近铺一帧:背景 → 水 → 地形 → 补给 →
 * 敌人 → 子弹 → 主角 → 粒子 → 准星 → HUD。世界坐标经 worldX/screenRect 转到屏幕,
 * 并叠加屏幕震动;super-sampling 由 sdl 的 beginScene/endScene 负责。
 */
protected func draw(renderer: Renderer, state: GameState, assets: GameAssets): Unit {
    renderer.beginScene(Stage.WIDTH_F, Stage.HEIGHT_F, Pal.SKY_TOP)
    drawBackdrop(renderer, state, assets)
    drawWater(renderer, state)
    drawSolids(renderer, state)
    drawPickups(renderer, state)
    drawEnemies(renderer, state, assets)
    drawBullets(renderer, state)
    drawPlayer(renderer, state, assets)
    drawParticles(renderer, state)
    drawCrosshair(renderer, state)
    drawHud(renderer, state)
    renderer.endScene()
    renderer.present()
}

/* 世界 X 转屏幕 X:减去镜头并叠加横向震动。 */
func worldX(state: GameState, x: Float32): Float32 {
    x - state.cameraX + shakeX(state)
}

/* 世界矩形转屏幕矩形。 */
func screenRect(state: GameState, rect: Rect): Rect {
    Rect(worldX(state, rect.x), rect.y + shakeY(state), rect.w, rect.h)
}

func shakeX(state: GameState): Float32 {
    if (state.screenShake <= 0.0) {
        return 0.0
    }
    Float32(sin(Float64(state.elapsed * 79.0))) * 7.0 * clampF32(state.screenShake * 2.0, 0.0, 1.0)
}

func shakeY(state: GameState): Float32 {
    if (state.screenShake <= 0.0) {
        return 0.0
    }
    Float32(sin(Float64(state.elapsed * 103.0))) * 4.0 * clampF32(state.screenShake * 2.0, 0.0, 1.0)
}

/* 把值折叠回 [0, period),用于视差纹理无缝滚动。 */
func wrappedOffset(value: Float32, period: Float32): Float32 {
    value - Float32(floor(Float64(value / period))) * period
}

/* 只在正尺寸时填充矩形,避免退化矩形产生绘制噪声。 */
func fillArea(r: Renderer, x: Float32, y: Float32, w: Float32, h: Float32, color: Color): Unit {
    if (w > 0.0 && h > 0.0) {
        r.fill(Rect(x, y, w, h), color)
    }
}
