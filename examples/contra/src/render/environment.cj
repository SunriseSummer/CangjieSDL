package contra.render

import contra.config.*
import contra.model.*
import std.math.sin
import sdl.Color
import sdl.Rect
import sdl.Renderer

/*
 * 静态与半静态场景:视差背景、滚动水面、地面/断桥平台、Boss 闸门。
 * 平台按世界坐标裁剪,只画进入视口的部分。
 */
func drawBackdrop(r: Renderer, state: GameState, assets: GameAssets): Unit {
    let parallax = state.cameraX * 0.012
    r.texture(assets.background, Rect(-80.0 - parallax, -38.0, 1440.0, 810.0))
    fillArea(r, 0.0, 0.0, Stage.WIDTH_F, Stage.HEIGHT_F, Color.rgba(8, 28, 34, 26))
}

func drawWater(r: Renderer, state: GameState): Unit {
    fillArea(r, 0.0, Stage.WATER_Y, Stage.WIDTH_F, Stage.HEIGHT_F - Stage.WATER_Y, Pal.WATER_DARK)
    for (index in 0..18) {
        let x = Float32(index) * 92.0 - wrappedOffset(state.cameraX * 0.25, 92.0)
        let wave = Float32(sin(Float64(state.elapsed * 2.4 + Float32(index)))) * 5.0
        fillArea(r, x, Stage.WATER_Y + 16.0 + wave, 54.0, 4.0, Pal.WATER_LIGHT)
        fillArea(r, x + 26.0, Stage.WATER_Y + 43.0 - wave, 70.0, 3.0, Pal.WATER)
    }
}

func drawSolids(r: Renderer, state: GameState): Unit {
    for (solid in state.solids) {
        let x = worldX(state, solid.rect.x)
        if (x + solid.rect.w < -40.0 || x > Stage.WIDTH_F + 40.0) {
            continue
        }
        if (solid.isBridge) {
            drawBridge(r, x, solid.rect)
        } else {
            drawGround(r, x, solid.rect)
        }
    }
    drawBossGate(r, state)
}

func drawGround(r: Renderer, x: Float32, rect: Rect): Unit {
    fillArea(r, x, rect.y, rect.w, rect.h, Pal.SOIL)
    fillArea(r, x, rect.y, rect.w, 12.0, Pal.GRASS_LIGHT)
    fillArea(r, x, rect.y + 12.0, rect.w, 12.0, Pal.GRASS)
    fillArea(r, x, rect.y + 56.0, rect.w, rect.h - 56.0, Pal.SOIL_DARK)

    var tileX: Float32 = 8.0
    while (tileX < rect.w) {
        fillArea(r, x + tileX, rect.y + 34.0, 28.0, 6.0, Pal.SOIL_DARK)
        tileX += 62.0
    }
}

func drawBridge(r: Renderer, x: Float32, rect: Rect): Unit {
    fillArea(r, x, rect.y, rect.w, 10.0, Pal.METAL_LIGHT)
    fillArea(r, x, rect.y + 10.0, rect.w, rect.h - 10.0, Pal.METAL_DARK)
    var beamX: Float32 = 6.0
    while (beamX < rect.w) {
        fillArea(r, x + beamX, rect.y + 3.0, 32.0, 5.0, Pal.METAL)
        r.line(x + beamX, rect.y + 12.0, x + beamX + 28.0, rect.y + rect.h, Pal.METAL_LIGHT)
        beamX += 44.0
    }
}

func drawBossGate(r: Renderer, state: GameState): Unit {
    let x = worldX(state, 5718.0)
    if (x < -220.0 || x > Stage.WIDTH_F + 80.0) {
        return
    }
    fillArea(r, x, 250.0, 260.0, 348.0, Pal.METAL_DARK)
    fillArea(r, x + 18.0, 270.0, 224.0, 328.0, Pal.BOSS)
    for (index in 0..6) {
        fillArea(r, x + 25.0, 286.0 + Float32(index) * 48.0, 210.0, 9.0, Pal.METAL)
    }
    fillArea(r, x - 22.0, 238.0, 34.0, 360.0, Pal.METAL_LIGHT)
}
