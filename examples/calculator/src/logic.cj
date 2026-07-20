package calculator

import std.convert.Parsable
import std.math.abs

/* 数值边界：显示位数上限、除零判定阈值与整数显示阈值。 */
struct Limit {
    static let DIGITS: Int64 = 15
    static let PERCENT: Float64 = 100.0
    static let DIVIDE_EPSILON: Float64 = 0.0000001
    static let INTEGER_EPSILON: Float64 = 0.000001
    static let INTEGER_RANGE: Float64 = 1.0e15
}

struct Dot {
    static let TEXT: String = "."
    static let BYTE: UInt8 = 46
}

func press(state: CalcState, label: String): Unit {
    if (label == "AC") {
        clear(state)
    } else if (label == "±") {
        toggleSign(state)
    } else if (label == "%") {
        percent(state)
    } else if (label == "=") {
        finishOperation(state)
    } else if (label == Dot.TEXT) {
        appendDot(state)
    } else {
        pressValue(state, label)
    }
}

func pressValue(state: CalcState, label: String): Unit {
    match (opFrom(label)) {
        case Some(op) => chooseOperation(state, op)
        case None => appendDigit(state, label)
    }
}

func opFrom(label: String): ?CalcOp {
    if (label == "+") {
        Some(CalcOp.Add)
    } else if (label == "-") {
        Some(CalcOp.Subtract)
    } else if (label == "×") {
        Some(CalcOp.Multiply)
    } else if (label == "÷") {
        Some(CalcOp.Divide)
    } else {
        None
    }
}

func opSymbol(op: CalcOp): String {
    match (op) {
        case CalcOp.Add => "+"
        case CalcOp.Subtract => "-"
        case CalcOp.Multiply => "×"
        case CalcOp.Divide => "÷"
    }
}

func clear(state: CalcState): Unit {
    state.display = DisplayText.ZERO
    state.stored = 0.0
    state.pending = None
    state.shouldResetDisplay = true
    state.hasError = false
}

func currentValue(state: CalcState): Float64 {
    match (Float64.tryParse(state.display)) {
        case Some(v) => v
        case None => 0.0
    }
}

func appendDigit(state: CalcState, digit: String): Unit {
    if (state.hasError) {
        clear(state)
    }
    if (state.shouldResetDisplay || state.display == DisplayText.ZERO) {
        state.display = digit
        state.shouldResetDisplay = false
    } else if (state.display.size < Limit.DIGITS) {
        state.display = state.display + digit
    }
}

func appendDot(state: CalcState): Unit {
    if (state.hasError) {
        clear(state)
    }
    if (state.shouldResetDisplay) {
        state.display = "${DisplayText.ZERO}${Dot.TEXT}"
        state.shouldResetDisplay = false
    } else if (!containsDot(state.display) && state.display.size < Limit.DIGITS) {
        state.display = state.display + Dot.TEXT
    }
}

/* 键盘 Backspace：逐位删除当前输入；显示内容只含 ASCII，按字节截断是安全的。 */
func deleteLast(state: CalcState): Unit {
    if (state.hasError) {
        clear(state)
        return
    }
    if (state.shouldResetDisplay) {
        return
    }
    if (state.display.size <= 1) {
        state.display = DisplayText.ZERO
        return
    }
    let trimmed = state.display[0..state.display.size - 1]
    state.display = if (trimmed == "-") {
        DisplayText.ZERO
    } else {
        trimmed
    }
}

func toggleSign(state: CalcState): Unit {
    if (state.hasError) {
        clear(state)
        return
    }
    state.display = formatValue(-currentValue(state))
    state.shouldResetDisplay = false
}

func percent(state: CalcState): Unit {
    if (state.hasError) {
        clear(state)
        return
    }
    state.display = formatValue(currentValue(state) / Limit.PERCENT)
    state.shouldResetDisplay = false
}

func chooseOperation(state: CalcState, op: CalcOp): Unit {
    if (state.hasError) {
        clear(state)
    }
    if (hasPending(state) && !state.shouldResetDisplay) {
        compute(state)
    } else {
        state.stored = currentValue(state)
    }
    state.pending = Some(op)
    state.shouldResetDisplay = true
}

func finishOperation(state: CalcState): Unit {
    if (state.hasError || !hasPending(state)) {
        return
    }
    compute(state)
    state.pending = None
    state.shouldResetDisplay = true
}

func compute(state: CalcState): Unit {
    if (let Some(op) <- state.pending) {
        computeWith(state, op)
    }
}

func computeWith(state: CalcState, op: CalcOp): Unit {
    let rhs = currentValue(state)
    var result: Float64 = 0.0

    match (op) {
        case CalcOp.Add => result = state.stored + rhs
        case CalcOp.Subtract => result = state.stored - rhs
        case CalcOp.Multiply => result = state.stored * rhs
        case CalcOp.Divide =>
            if (abs(rhs) < Limit.DIVIDE_EPSILON) {
                fail(state)
                return
            }
            result = state.stored / rhs
    }

    state.stored = result
    state.display = formatValue(result)
}

func fail(state: CalcState): Unit {
    state.display = DisplayText.ERROR
    state.hasError = true
    state.pending = None
    state.shouldResetDisplay = true
}

func hasPending(state: CalcState): Bool {
    match (state.pending) {
        case Some(_) => true
        case None => false
    }
}

/* 接近整数的结果按整数显示；超出 Int64 精确范围的值保持浮点形式，避免转换溢出。 */
func formatValue(value: Float64): String {
    if (abs(value) < Limit.INTEGER_RANGE) {
        let rounded = Int64(value)
        if (abs(value - Float64(rounded)) < Limit.INTEGER_EPSILON) {
            return "${rounded}"
        }
    }
    "${value}"
}

func containsDot(text: String): Bool {
    for (byte in text) {
        if (byte == Dot.BYTE) {
            return true
        }
    }
    false
}
