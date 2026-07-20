package calculator

import std.collection.ArrayList
import sdl.FontSizes
import sdl.Rect

/* 窗口与整体布局。逻辑坐标即窗口坐标，窗口固定大小，不做运行时重排。 */
struct View {
    static let TITLE: String = "Cangjie SDL Calculator"
    static let WIDTH: Int32 = 420
    static let HEIGHT: Int32 = 640
    static let WIDTH_F: Float32 = 420.0
    static let HEIGHT_F: Float32 = 640.0
    static let FRAME_DELAY_MS: UInt32 = 8
    static let STRIPE_STEP: Float32 = 10.0
}

/* 显示面板：结果读数区域的框、高光条与文字位置。 */
struct Panel {
    static let BOX: Rect = Rect(24.0, 34.0, 372.0, 160.0)
    static let SHEEN: Rect = Rect(40.0, 50.0, 340.0, 38.0)
    static let RADIUS: Float32 = 14.0
    static let SHEEN_RADIUS: Float32 = 8.0
    static let TITLE_X: Float32 = 52.0
    static let TITLE_Y: Float32 = 60.0
    static let OP_RIGHT: Float32 = 370.0
    static let OP_Y: Float32 = 56.0
    static let TEXT_RIGHT: Float32 = 370.0
    static let TEXT_Y: Float32 = 118.0
    static let TEXT_Y_COMPACT: Float32 = 124.0
    static let TEXT_MAX_WIDTH: Float32 = 330.0
    static let DISPLAY_SIZE: Float32 = FontSizes.DISPLAY
    static let COMPACT_SIZE: Float32 = 24.0
}

/* 按键网格：4 列 5 行，由列/行号换算出每个按键的矩形。 */
struct Pad {
    static let X: Float32 = 28.0
    static let Y: Float32 = 232.0
    static let KEY_W: Float32 = 83.5
    static let KEY_H: Float32 = 68.0
    static let GAP: Float32 = 10.0
    static let RADIUS: Float32 = 12.0
    static let LABEL_SIZE: Float32 = FontSizes.TITLE
}

struct DisplayText {
    static let ZERO: String = "0"
    static let ERROR: String = "ERROR"
}

enum ButtonRole {
    | Number
    | Utility
    | Operator
    | Equals
}

enum CalcOp {
    | Add
    | Subtract
    | Multiply
    | Divide
}

class Button {
    let label: String
    let rect: Rect
    let role: ButtonRole

    init(label: String, rect: Rect, role: ButtonRole) {
        this.label = label
        this.rect = rect
        this.role = role
    }
}

class CalcState {
    var display = DisplayText.ZERO
    var stored: Float64 = 0.0
    var pending: ?CalcOp = None
    var shouldResetDisplay = true
    var hasError = false
    var isRunning = true
    let buttons = buildButtons()
}

func buildButtons(): ArrayList<Button> {
    let buttons = ArrayList<Button>()
    let num = ButtonRole.Number
    let util = ButtonRole.Utility
    let op = ButtonRole.Operator

    addButton(buttons, "AC", 0, 0, 1, util)
    addButton(buttons, "±", 1, 0, 1, util)
    addButton(buttons, "%", 2, 0, 1, util)
    addButton(buttons, "÷", 3, 0, 1, op)
    addButton(buttons, "7", 0, 1, 1, num)
    addButton(buttons, "8", 1, 1, 1, num)
    addButton(buttons, "9", 2, 1, 1, num)
    addButton(buttons, "×", 3, 1, 1, op)
    addButton(buttons, "4", 0, 2, 1, num)
    addButton(buttons, "5", 1, 2, 1, num)
    addButton(buttons, "6", 2, 2, 1, num)
    addButton(buttons, "-", 3, 2, 1, op)
    addButton(buttons, "1", 0, 3, 1, num)
    addButton(buttons, "2", 1, 3, 1, num)
    addButton(buttons, "3", 2, 3, 1, num)
    addButton(buttons, "+", 3, 3, 1, op)
    addButton(buttons, "0", 0, 4, 2, num)
    addButton(buttons, ".", 2, 4, 1, num)
    addButton(buttons, "=", 3, 4, 1, ButtonRole.Equals)
    buttons
}

func addButton(
    buttons: ArrayList<Button>,
    label: String,
    col: Int64,
    row: Int64,
    span: Int64,
    role: ButtonRole
): Unit {
    buttons.add(Button(label, buttonRect(col, row, span), role))
}

func buttonRect(col: Int64, row: Int64, span: Int64): Rect {
    let x = Pad.X + Float32(col) * (Pad.KEY_W + Pad.GAP)
    let y = Pad.Y + Float32(row) * (Pad.KEY_H + Pad.GAP)
    let w = Pad.KEY_W * Float32(span) + Pad.GAP * Float32(span - 1)
    Rect(x, y, w, Pad.KEY_H)
}
