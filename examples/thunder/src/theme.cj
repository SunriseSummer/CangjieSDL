package game

import sdl.Color

struct Pal {
    static let SPACE: Color = Color.rgb(5, 8, 18)
    static let STAR: Color = Color.rgba(180, 224, 255, 255)
    static let GRID: Color = Color.rgba(37, 116, 180, 55)
    static let GRID_SOFT: Color = Color.rgba(85, 180, 240, 32)
    static let SHOT_GLOW: Color = Color.rgba(30, 235, 255, 65)
    static let SHOT: Color = Color.rgb(170, 252, 255)
    static let FOE_GLOW: Color = Color.rgba(255, 54, 100, 42)
    static let FOE: Color = Color.rgb(132, 36, 64)
    static let FOE_WING: Color = Color.rgb(220, 55, 86)
    static let FOE_CORE: Color = Color.rgb(255, 176, 72)
    static let FOE_LINE: Color = Color.rgba(255, 216, 184, 125)
    static let SHIP_WING: Color = Color.rgb(25, 105, 150)
    static let SHIP: Color = Color.rgb(56, 182, 214)
    static let COCKPIT: Color = Color.rgb(178, 247, 255)
    static let SHIP_LINE: Color = Color.rgb(113, 239, 255)
    static let FLAME: Color = Color.rgba(255, 154, 58, 180)
    static let FLAME_HOT: Color = Color.rgba(255, 238, 132, 210)
    static let SPARK: Color = Color.rgb(255, 188, 72)
    static let HUD: Color = Color.rgba(8, 18, 34, 180)
    static let HUD_EDGE: Color = Color.rgba(102, 230, 255, 135)
    static let SCORE: Color = Color.rgb(176, 247, 255)
    static let LIFE: Color = Color.rgb(255, 206, 126)
    static let SHADE: Color = Color.rgba(5, 8, 18, 220)
    static let WARN: Color = Color.rgb(255, 82, 126)
    static let WARN_TEXT: Color = Color.rgb(255, 118, 150)
    static let HINT: Color = Color.rgb(172, 240, 255)
}
