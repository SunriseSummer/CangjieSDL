package calculator

import sdl.Color
import sdl.FontSizes
import sdl.Pen
import sdl.Rect
import sdl.Renderer

let BUTTON_SHADOW_FEATHER: Float32 = 6.0

func draw(renderer: Renderer, state: CalcState): Unit {
    renderer.beginScene(View.WIDTH_F, View.HEIGHT_F, Pal.BG)
    drawBackground(renderer)
    drawDisplay(renderer, state)
    for (button in state.buttons) {
        drawButton(renderer, button)
    }
    renderer.endScene()
    renderer.present()
}

func drawBackground(r: Renderer): Unit {
    var y: Float32 = 0.0
    while (y < View.HEIGHT_F) {
        r.fill(Rect(0.0, y, View.WIDTH_F, View.STRIPE_STEP), stripeColor(y / View.HEIGHT_F))
        y += View.STRIPE_STEP
    }
    drawAccents(r)
}

/* 背景从上到下由深到浅的渐变，按条带近似绘制。 */
func stripeColor(t: Float32): Color {
    Color.rgba(Int64(10.0 + 22.0 * t), Int64(15.0 + 12.0 * t), Int64(30.0 + 35.0 * t), 255)
}

func drawAccents(r: Renderer): Unit {
    r.circle(340.0, 88.0, 92.0, Pal.BLUE)
    r.circle(74.0, 612.0, 140.0, Pal.GOLD)
    r.line(36.0, 188.0, 384.0, 188.0, Pal.LINE)
}

func drawDisplay(r: Renderer, state: CalcState): Unit {
    r.fillRoundedRect(Panel.BOX, Panel.RADIUS, Pal.PANEL)
    r.strokeRoundedRect(Panel.BOX, Panel.RADIUS, Pen(width: 1.5, color: Pal.PANEL_EDGE))
    r.fillRoundedRect(Panel.SHEEN, Panel.SHEEN_RADIUS, Pal.SHEEN)
    r.text("CANGJIE SDL", Panel.TITLE_X, Panel.TITLE_Y, Pal.TITLE, pointSize: FontSizes.CAPTION)

    if (let Some(op) <- state.pending) {
        drawTextRight(r, opSymbol(op), Panel.OP_RIGHT, Panel.OP_Y, Pal.OP, FontSizes.TITLE)
    }

    drawReadout(r, state)
}

/* 读数右对齐；位数多到超出面板宽度时换用较小字号。 */
func drawReadout(r: Renderer, state: CalcState): Unit {
    if (r.textWidth(state.display, pointSize: Panel.DISPLAY_SIZE) <= Panel.TEXT_MAX_WIDTH) {
        drawTextRight(r, state.display, Panel.TEXT_RIGHT, Panel.TEXT_Y, Pal.TEXT, Panel.DISPLAY_SIZE)
    } else {
        drawTextRight(r, state.display, Panel.TEXT_RIGHT, Panel.TEXT_Y_COMPACT, Pal.TEXT, Panel.COMPACT_SIZE)
    }
}

func drawButton(r: Renderer, button: Button): Unit {
    let box = button.rect
    r.fillRoundedRectSoft(box.shift(2.0, 5.0), Pad.RADIUS, Pal.SHADOW, feather: BUTTON_SHADOW_FEATHER)
    r.fillRoundedRect(box, Pad.RADIUS, buttonBaseColor(button.role))
    r.strokeRoundedRect(box, Pad.RADIUS, Pen(width: 1.0, color: Pal.EDGE))
    r.fillRoundedRect(Rect(box.x + 8.0, box.y + 7.0, box.w - 16.0, 3.0), 1.5, Pal.SHINE)
    r.textCenter(button.label, box, buttonTextColor(button.role), pointSize: Pad.LABEL_SIZE)
}

func buttonBaseColor(role: ButtonRole): Color {
    match (role) {
        case ButtonRole.Operator => Pal.ACCENT
        case ButtonRole.Equals => Pal.EQUAL
        case ButtonRole.Utility => Pal.UTIL
        case ButtonRole.Number => Pal.NUM
    }
}

func buttonTextColor(role: ButtonRole): Color {
    match (role) {
        case ButtonRole.Operator => Pal.DARK
        // 深色底的数字、功能与等号按键统一用浅色文字
        case _ => Pal.LIGHT
    }
}

/* 新版渲染器没有右对齐接口，用 textWidth 度量后手动左移。 */
func drawTextRight(r: Renderer, text: String, right: Float32, y: Float32, color: Color, size: Float32): Unit {
    r.text(text, right - r.textWidth(text, pointSize: size), y, color, pointSize: size)
}
