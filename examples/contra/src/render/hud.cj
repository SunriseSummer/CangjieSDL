package contra.render

import contra.config.*
import contra.model.*
import sdl.Pen
import sdl.Rect
import sdl.Renderer
import sdl.clampF32

/*
 * 平视信息与结算面板:顶栏(分数/生命/武器/关卡)、进度条、Boss 血条、
 * 开场任务提示(淡出)、通关/失败面板。全部按逻辑分辨率的固定布局绘制。
 */
func drawHud(r: Renderer, state: GameState): Unit {
    r.fillRoundedRect(HudSpec.TOP_BAR, HudSpec.BAR_RADIUS, Pal.HUD)
    r.strokeRoundedRect(HudSpec.TOP_BAR, HudSpec.BAR_RADIUS, Pen(width: 1.5, color: Pal.HUD_EDGE))
    r.text("SCORE ${state.score}", 44.0, HudSpec.TEXT_Y, Pal.HUD_TEXT, pointSize: HudSpec.BODY)
    drawPlayerHealth(r, state.player)
    let weaponName = if (hasSpread(state.player.weapon)) {
        "SPREAD"
    } else {
        "RIFLE"
    }
    r.text("WEAPON ${weaponName}", 560.0, HudSpec.TEXT_Y, Pal.HUD_TEXT, pointSize: HudSpec.BODY)
    r.text("MISSION 01", 1050.0, HudSpec.TEXT_Y, Pal.HUD_ACCENT, pointSize: HudSpec.BODY)

    drawProgress(r, state)
    if (state.bossAwake && isPlaying(state.phase)) {
        drawBossHealth(r, state)
    }
    if (state.elapsed < Stage.INTRO_TIME && isPlaying(state.phase)) {
        drawMissionIntro(r, state.elapsed)
    }
    if (!isPlaying(state.phase)) {
        drawResultPanel(r, state)
    }
}

func drawPlayerHealth(r: Renderer, player: Player): Unit {
    r.text("VITALS", 260.0, HudSpec.TEXT_Y, Pal.HUD_ACCENT, pointSize: HudSpec.BODY)
    for (index in 0..HeroSpec.MAX_HEALTH) {
        let segment = Rect(354.0 + Float32(index) * 34.0, 38.0, 27.0, 16.0)
        r.fillRoundedRect(segment, 4.0, Pal.METAL_DARK)
        if (player.health > index) {
            let color = if (player.health <= 2) {
                Pal.LOSE
            } else {
                Pal.WIN
            }
            r.fillRoundedRect(segment.inset(2.0), 3.0, color)
        }
    }
}

func drawProgress(r: Renderer, state: GameState): Unit {
    let track = Rect(800.0, 43.0, 210.0, 10.0)
    r.fillRoundedRect(track, 5.0, Pal.METAL_DARK)
    let ratio = clampF32(state.player.x / FoeSpec.BOSS_X, 0.0, 1.0)
    r.fillRoundedRect(Rect(track.x, track.y, track.w * ratio, track.h), 5.0, Pal.PICKUP)
}

func drawBossHealth(r: Renderer, state: GameState): Unit {
    var hp: Int64 = 0
    for (enemy in state.enemies) {
        if (isBoss(enemy.kind)) {
            hp = enemy.hp
        }
    }
    r.fillRoundedRect(HudSpec.BOSS_BAR, 9.0, Pal.HUD)
    let ratio = clampF32(Float32(hp) / Float32(FoeSpec.BOSS_HP), 0.0, 1.0)
    r.fillRoundedRect(
        Rect(HudSpec.BOSS_BAR.x, HudSpec.BOSS_BAR.y, HudSpec.BOSS_BAR.w * ratio, HudSpec.BOSS_BAR.h),
        9.0,
        Pal.BOSS_CORE
    )
    r.textCenter("CORE", Rect(420.0, 91.0, 440.0, 22.0), Pal.WHITE, pointSize: 14.0)
}

func drawMissionIntro(r: Renderer, elapsed: Float32): Unit {
    let fade = clampF32((Stage.INTRO_TIME - elapsed) * 1.4, 0.0, 1.0)
    let panel = Rect(390.0, 274.0, 500.0, 112.0)
    r.fillRoundedRect(panel, 14.0, Pal.HUD.withAlpha(Int64(205.0 * fade)))
    r.strokeRoundedRect(panel, 14.0, Pen(width: 2.0, color: Pal.HUD_EDGE.withAlpha(Int64(255.0 * fade))))
    r.textCenter("MISSION 01", Rect(390.0, 292.0, 500.0, 38.0), Pal.HUD_ACCENT.withAlpha(Int64(255.0 * fade)),
        pointSize: 30.0)
    r.textCenter("BREAK THE JUNGLE CORE", Rect(390.0, 340.0, 500.0, 24.0), Pal.HUD_TEXT.withAlpha(Int64(255.0 * fade)),
        pointSize: 17.0)
}

func drawResultPanel(r: Renderer, state: GameState): Unit {
    r.fillRoundedRect(HudSpec.PANEL, HudSpec.PANEL_RADIUS, Pal.SHADE)
    let accent = if (isWon(state.phase)) {
        Pal.WIN
    } else {
        Pal.LOSE
    }
    r.strokeRoundedRect(HudSpec.PANEL, HudSpec.PANEL_RADIUS, Pen(width: 3.0, color: accent))
    let title = if (isWon(state.phase)) {
        "MISSION COMPLETE"
    } else {
        "MISSION FAILED"
    }
    let subtitle = if (isWon(state.phase)) {
        "THE JUNGLE CORE IS OFFLINE - SCORE ${state.score}"
    } else {
        "THE RESISTANCE NEEDS YOU BACK"
    }
    r.textCenter(title, HudSpec.PANEL_TITLE, accent, pointSize: HudSpec.TITLE)
    r.textCenter(subtitle, HudSpec.PANEL_SUBTITLE, Pal.HUD_TEXT, pointSize: HudSpec.BODY)
    r.textCenter("ENTER OR R TO RESTART", HudSpec.PANEL_HINT, Pal.HUD_ACCENT, pointSize: HudSpec.BODY)
}
