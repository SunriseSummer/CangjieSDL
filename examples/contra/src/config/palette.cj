package contra.config

import sdl.Color

/*
 * 原创丛林像素科幻调色板。整套画面只用这一组具名颜色,新增场景元素时优先
 * 复用已有色,保证风格统一;换肤只需改这一个文件。
 */
protected struct Pal {
    protected static let SKY_TOP: Color = Color.rgb(10, 18, 43)
    protected static let WATER: Color = Color.rgb(25, 91, 113)
    protected static let WATER_LIGHT: Color = Color.rgba(113, 221, 210, 155)
    protected static let WATER_DARK: Color = Color.rgb(14, 54, 78)
    protected static let SOIL: Color = Color.rgb(62, 58, 43)
    protected static let SOIL_DARK: Color = Color.rgb(35, 39, 35)
    protected static let GRASS: Color = Color.rgb(77, 145, 73)
    protected static let GRASS_LIGHT: Color = Color.rgb(143, 210, 91)
    protected static let METAL: Color = Color.rgb(66, 82, 89)
    protected static let METAL_LIGHT: Color = Color.rgb(135, 163, 164)
    protected static let METAL_DARK: Color = Color.rgb(31, 43, 51)
    protected static let MUZZLE: Color = Color.rgb(255, 235, 130)
    protected static let SHOT: Color = Color.rgb(183, 255, 248)
    protected static let SHOT_GLOW: Color = Color.rgba(75, 244, 255, 82)
    protected static let FOE_LIGHT: Color = Color.rgb(255, 133, 92)
    protected static let FOE_DARK: Color = Color.rgb(86, 31, 51)
    protected static let FOE_SHOT: Color = Color.rgb(255, 103, 91)
    protected static let FOE_GLOW: Color = Color.rgba(255, 54, 76, 72)
    protected static let DRONE: Color = Color.rgb(177, 95, 212)
    protected static let DRONE_LIGHT: Color = Color.rgb(239, 178, 255)
    protected static let BOSS: Color = Color.rgb(66, 55, 85)
    protected static let BOSS_CORE: Color = Color.rgb(255, 74, 112)
    protected static let BOSS_CORE_HOT: Color = Color.rgb(255, 224, 151)
    protected static let PICKUP: Color = Color.rgb(86, 228, 124)
    protected static let PICKUP_GLOW: Color = Color.rgba(100, 255, 155, 72)
    protected static let SPARK: Color = Color.rgb(255, 183, 82)
    protected static let SMOKE: Color = Color.rgb(119, 129, 130)
    protected static let HUD: Color = Color.rgba(7, 17, 30, 222)
    protected static let HUD_EDGE: Color = Color.rgba(94, 234, 218, 155)
    protected static let HUD_TEXT: Color = Color.rgb(213, 255, 244)
    protected static let HUD_ACCENT: Color = Color.rgb(255, 213, 112)
    protected static let SHADE: Color = Color.rgba(4, 9, 18, 224)
    protected static let WIN: Color = Color.rgb(110, 255, 177)
    protected static let LOSE: Color = Color.rgb(255, 100, 116)
    protected static let WHITE: Color = Color.rgb(255, 255, 255)
}
