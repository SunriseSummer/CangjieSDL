package game

import sdl.Color
import sdl.Pen
import sdl.Rect
import sdl.Renderer

func draw(renderer: Renderer, state: GameState): Unit {
    renderer.beginScene(Stage.WIDTH_F, Stage.HEIGHT_F, Pal.SPACE)
    drawBackground(renderer, state)
    drawBullets(renderer, state)
    drawEnemies(renderer, state)
    drawPlayer(renderer, state.player, state.isOver)
    drawParticles(renderer, state)
    drawHud(renderer, state)
    renderer.endScene()
    renderer.present()
}

func drawBackground(r: Renderer, state: GameState): Unit {
    drawSky(r)
    drawGrid(r)

    for (star in state.stars) {
        fillArea(r, star.x, star.y, star.size, star.size, Pal.STAR)
    }
}

func drawSky(r: Renderer): Unit {
    var y: Float32 = 0.0
    while (y < Stage.HEIGHT_F) {
        fillArea(r, 0.0, y, Stage.WIDTH_F, Stage.STRIPE_STEP, skyColor(y / Stage.HEIGHT_F))
        y += Stage.STRIPE_STEP
    }
}

/* 太空背景自上而下渐亮，按条带近似渐变。 */
func skyColor(t: Float32): Color {
    Color.rgba(Int64(4.0 + 14.0 * t), Int64(9.0 + 8.0 * t), Int64(24.0 + 38.0 * t), 255)
}

func drawGrid(r: Renderer): Unit {
    r.line(95.0, 0.0, 250.0, Stage.HEIGHT_F, Pal.GRID)
    r.line(705.0, 0.0, 545.0, Stage.HEIGHT_F, Pal.GRID)
    r.line(Stage.WIDTH_F / 2.0, 0.0, Stage.WIDTH_F / 2.0, Stage.HEIGHT_F, Pal.GRID_SOFT)
}

func drawBullets(r: Renderer, state: GameState): Unit {
    for (bullet in state.bullets) {
        r.fillRoundedRect(grown(bullet.rect, Shot.GLOW_X, Shot.GLOW_Y), Shot.RADIUS * 2.0, Pal.SHOT_GLOW)
        r.fillRoundedRect(bullet.rect, Shot.RADIUS, Pal.SHOT)
    }
}

func drawEnemies(r: Renderer, state: GameState): Unit {
    for (enemy in state.enemies) {
        drawEnemy(r, enemy.rect)
    }
}

func drawEnemy(r: Renderer, e: Rect): Unit {
    r.fill(grown(e, Foe.GLOW, Foe.GLOW), Pal.FOE_GLOW)
    fillArea(r, e.x + e.w * 0.18, e.y, e.w * 0.64, e.h, Pal.FOE)
    fillArea(r, e.x, e.y + e.h * 0.35, e.w, e.h * 0.34, Pal.FOE_WING)
    r.fillCircle(e.centerX(), e.centerY(), e.w * 0.18, Pal.FOE_CORE)
    r.line(e.x + 4.0, e.bottom(), e.centerX(), e.y + 4.0, Pal.FOE_LINE)
    r.line(e.right() - 4.0, e.bottom(), e.centerX(), e.y + 4.0, Pal.FOE_LINE)
}

func drawPlayer(r: Renderer, player: Player, isOver: Bool): Unit {
    if (isOver || isBlinking(player)) {
        return
    }

    let s = player.rect
    fillArea(r, s.x - 10.0, s.y + 28.0, 20.0, 13.0, Pal.SHIP_WING)
    fillArea(r, s.right() - 10.0, s.y + 28.0, 20.0, 13.0, Pal.SHIP_WING)
    fillArea(r, s.x + 9.0, s.y + 12.0, s.w - 18.0, s.h - 4.0, Pal.SHIP)
    fillArea(r, s.x + 16.0, s.y, s.w - 32.0, 20.0, Pal.COCKPIT)
    r.strokeLine(s.centerX(), s.y - 12.0, s.x + 4.0, s.bottom() - 2.0, Pen(width: 2.0, color: Pal.SHIP_LINE))
    r.strokeLine(s.centerX(), s.y - 12.0, s.right() - 4.0, s.bottom() - 2.0, Pen(width: 2.0, color: Pal.SHIP_LINE))
    fillArea(r, s.centerX() - 4.0, s.bottom() - 2.0, 8.0, 22.0, Pal.FLAME)
    fillArea(r, s.centerX() - 2.0, s.bottom(), 4.0, 24.0, Pal.FLAME_HOT)
}

/* 无敌时间内按固定频率闪烁，提示玩家当前不可受击。 */
func isBlinking(player: Player): Bool {
    player.invincible > 0.0 && (Int64(player.invincible * Ship.BLINK_RATE) % 2 == 0)
}

func drawParticles(r: Renderer, state: GameState): Unit {
    for (p in state.particles) {
        let alpha = Int64(Fx.FULL_ALPHA * p.life / p.maxLife)
        fillArea(r, p.x, p.y, Fx.SPARK_SIZE, Fx.SPARK_SIZE, Pal.SPARK.withAlpha(alpha))
    }
}

func drawHud(r: Renderer, state: GameState): Unit {
    r.fillRoundedRect(Hud.BOX, Hud.RADIUS, Pal.HUD)
    r.strokeRoundedRect(Hud.BOX, Hud.RADIUS, Pen(width: 1.5, color: Pal.HUD_EDGE))
    r.text("SCORE ${state.score}", Hud.SCORE_X, Hud.TEXT_Y, Pal.SCORE, pointSize: Hud.TEXT_SIZE)
    r.text("LIFE ${state.player.lives}", Hud.LIFE_X, Hud.TEXT_Y, Pal.LIFE, pointSize: Hud.TEXT_SIZE)

    if (state.isOver) {
        drawGameOver(r)
    }
}

func drawGameOver(r: Renderer): Unit {
    r.fillRoundedRect(Hud.OVER_BOX, Hud.OVER_RADIUS, Pal.SHADE)
    r.strokeRoundedRect(Hud.OVER_BOX, Hud.OVER_RADIUS, Pen(width: 2.0, color: Pal.WARN))
    r.textCenter("MISSION FAILED", Hud.OVER_TITLE_RECT, Pal.WARN_TEXT, pointSize: Hud.OVER_TITLE_SIZE)
    r.textCenter("SPACE TO RESTART", Hud.OVER_HINT_RECT, Pal.HINT, pointSize: Hud.OVER_HINT_SIZE)
}

/* 新版 fill 只接收 Rect，坐标绘制统一走这个便捷入口。 */
func fillArea(r: Renderer, x: Float32, y: Float32, w: Float32, h: Float32, color: Color): Unit {
    r.fill(Rect(x, y, w, h), color)
}
