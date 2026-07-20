package contra.render

import contra.config.*
import contra.geom.*
import contra.model.*
import std.math.sin
import sdl.Color
import sdl.Pen
import sdl.Rect
import sdl.Renderer
import sdl.Texture
import sdl.TextureFlip
import sdl.TextureRenderOptions

/*
 * 动态实体的绘制:补给、敌人(步兵贴图 + 炮台/无人机/Boss 代码绘制)、子弹、
 * 粒子、鼠标准星。敌人受击时 flash 期整体泛白作为命中反馈。
 */
func drawPickups(r: Renderer, state: GameState): Unit {
    for (pickup in state.pickups) {
        if (!pickup.isActive) {
            continue
        }
        let rect = screenRect(state, pickup.rect)
        r.fillRoundedRect(grown(rect, 8.0, 8.0), 10.0, Pal.PICKUP_GLOW)
        r.fillRoundedRect(rect, 7.0, Pal.PICKUP)
        r.strokeRoundedRect(rect, 7.0, Pen(width: 2.0, color: Pal.WHITE))
        r.textCenter("S", rect, Pal.METAL_DARK, pointSize: 18.0)
    }
}

func drawEnemies(r: Renderer, state: GameState, assets: GameAssets): Unit {
    for (enemy in state.enemies) {
        if (!enemy.isActive && !isBoss(enemy.kind)) {
            continue
        }
        let rect = screenRect(state, enemy.rect)
        if (rect.right() < -100.0 || rect.x > Stage.WIDTH_F + 100.0) {
            continue
        }
        match (enemy.kind) {
            case EnemyKind.Grunt => drawGrunt(r, rect, assets.enemyGrunt, state.player.x < enemy.rect.x)
            case EnemyKind.Turret => drawTurret(r, rect, enemy)
            case EnemyKind.Drone => drawDrone(r, rect, enemy)
            case EnemyKind.Boss =>
                if (state.bossAwake) {
                    drawBoss(r, rect, enemy, state.elapsed)
                }
        }
    }
}

func drawGrunt(r: Renderer, rect: Rect, texture: Texture, facesLeft: Bool): Unit {
    let width: Float32 = 58.0
    let height: Float32 = 98.0
    let destination = Rect(rect.centerX() - width / 2.0, rect.bottom() - height, width, height)
    let flip = if (facesLeft) {
        TextureFlip.None
    } else {
        TextureFlip.Horizontal
    }
    let options = TextureRenderOptions(source: Some(Rect(108.0, 149.0, 697.0, 1182.0)), flip: flip)
    r.textureRotated(texture, destination, 0.0, options: options)
}

func drawTurret(r: Renderer, rect: Rect, enemy: Enemy): Unit {
    let bodyColor = if (enemy.flash > 0.0) {
        Pal.WHITE
    } else {
        Pal.METAL
    }
    fillArea(r, rect.x + 4.0, rect.y + 22.0, rect.w - 8.0, rect.h - 22.0, bodyColor)
    r.fillCircle(rect.centerX(), rect.y + 22.0, 18.0, Pal.FOE_DARK)
    fillArea(r, rect.x - 15.0, rect.y + 17.0, 38.0, 9.0, Pal.METAL_LIGHT)
    r.fillCircle(rect.centerX(), rect.y + 22.0, 7.0, Pal.FOE_LIGHT)
}

func drawDrone(r: Renderer, rect: Rect, enemy: Enemy): Unit {
    let bodyColor = if (enemy.flash > 0.0) {
        Pal.WHITE
    } else {
        Pal.DRONE
    }
    r.fillRoundedRect(Rect(rect.x + 8.0, rect.y + 7.0, rect.w - 16.0, rect.h - 12.0), 12.0, bodyColor)
    fillArea(r, rect.x, rect.y + 15.0, 20.0, 6.0, Pal.DRONE_LIGHT)
    fillArea(r, rect.right() - 20.0, rect.y + 15.0, 20.0, 6.0, Pal.DRONE_LIGHT)
    r.fillCircle(rect.centerX(), rect.centerY(), 7.0, Pal.BOSS_CORE)
}

func drawBoss(r: Renderer, rect: Rect, enemy: Enemy, elapsed: Float32): Unit {
    let bodyColor = if (enemy.flash > 0.0) {
        Pal.WHITE
    } else {
        Pal.BOSS
    }
    r.fillRoundedRect(rect, 18.0, bodyColor)
    r.strokeRoundedRect(rect, 18.0, Pen(width: 4.0, color: Pal.METAL_LIGHT))
    fillArea(r, rect.x + 28.0, rect.y + 24.0, rect.w - 56.0, 34.0, Pal.METAL)
    fillArea(r, rect.x + 20.0, rect.y + 84.0, 44.0, 118.0, Pal.METAL_DARK)
    fillArea(r, rect.right() - 64.0, rect.y + 84.0, 44.0, 118.0, Pal.METAL_DARK)
    let pulse = 26.0 + Float32(sin(Float64(elapsed * 6.0))) * 4.0
    r.fillCircle(rect.centerX(), rect.y + 126.0, pulse + 12.0, Pal.FOE_GLOW)
    r.fillCircle(rect.centerX(), rect.y + 126.0, pulse, Pal.BOSS_CORE)
    r.fillCircle(rect.centerX(), rect.y + 126.0, 10.0, Pal.BOSS_CORE_HOT)
    fillArea(r, rect.x - 32.0, rect.y + 112.0, 54.0, 18.0, Pal.METAL_LIGHT)
}

func drawBullets(r: Renderer, state: GameState): Unit {
    for (bullet in state.bullets) {
        let rect = screenRect(state, bullet.rect)
        if (bullet.isFriendly) {
            r.fillRoundedRect(grown(rect, 5.0, 5.0), 7.0, Pal.SHOT_GLOW)
            r.fillRoundedRect(rect, 4.0, Pal.SHOT)
        } else {
            r.fillCircle(rect.centerX(), rect.centerY(), 9.0, Pal.FOE_GLOW)
            r.fillCircle(rect.centerX(), rect.centerY(), 5.0, Pal.FOE_SHOT)
        }
    }
}

func drawParticles(r: Renderer, state: GameState): Unit {
    for (particle in state.particles) {
        let alpha = Int64(FxSpec.FULL_ALPHA * particle.life / particle.maxLife)
        let color = if (particle.isSmoke) {
            Pal.SMOKE.withAlpha(alpha)
        } else {
            Pal.SPARK.withAlpha(alpha)
        }
        let size: Float32 = if (particle.isSmoke) {
            8.0
        } else {
            5.0
        }
        fillArea(r, worldX(state, particle.x), particle.y, size, size, color)
    }
}

func drawCrosshair(r: Renderer, state: GameState): Unit {
    if (!state.input.isUsingMouse || !isPlaying(state.phase)) {
        return
    }
    let x = state.input.mouseX
    let y = state.input.mouseY
    let pulse = 11.0 + Float32(sin(Float64(state.elapsed * 8.0))) * 2.0
    r.strokeCircle(x, y, pulse, Pen(width: 1.8, color: Pal.SHOT))
    r.line(x - 19.0, y, x - 7.0, y, Pal.SHOT)
    r.line(x + 7.0, y, x + 19.0, y, Pal.SHOT)
    r.line(x, y - 19.0, x, y - 7.0, Pal.SHOT)
    r.line(x, y + 7.0, x, y + 19.0, Pal.SHOT)
    r.fillCircle(x, y, 2.5, Pal.MUZZLE)
}
