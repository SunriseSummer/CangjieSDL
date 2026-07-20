package calculator

import sdl.Key
import sdl.MouseButton
import sdl.SdlWindow
import sdl.UiEvent

func runCalculator(window: SdlWindow): Unit {
    let state = CalcState()

    while (state.isRunning) {
        var event = window.pollEvent()
        while (let Some(e) <- event) {
            handleEvent(state, e)
            event = window.pollEvent()
        }
        draw(window.renderer, state)
        window.delay(View.FRAME_DELAY_MS)
    }
}

func handleEvent(state: CalcState, event: UiEvent): Unit {
    match (event) {
        case UiEvent.Quit => state.isRunning = false
        case UiEvent.KeyDown(Key.Escape, _) => state.isRunning = false
        case UiEvent.KeyDown(Key.Enter, _) => press(state, "=")
        case UiEvent.KeyDown(Key.Backspace, _) => deleteLast(state)
        case UiEvent.TextInput(text) => pressText(state, text)
        case UiEvent.MouseDown(MouseButton.Left, x, y) => pressAt(state, x, y)
        // 其余事件（鼠标移动、窗口事件等）与计算器无关
        case _ => ()
    }
}

func pressAt(state: CalcState, x: Float32, y: Float32): Unit {
    for (button in state.buttons) {
        if (button.rect.contains(x, y)) {
            press(state, button.label)
            return
        }
    }
}

/* 键盘输入走 TextInput 事件：系统已处理修饰键与布局，这里只需映射字符。 */
func pressText(state: CalcState, text: String): Unit {
    for (ch in text.runes()) {
        if (let Some(label) <- labelForRune(ch)) {
            press(state, label)
        }
    }
}

func labelForRune(ch: Rune): ?String {
    if (ch >= r'0' && ch <= r'9') {
        return Some(ch.toString())
    }
    match (ch) {
        case r'.' => Some(".")
        case r'+' => Some("+")
        case r'-' => Some("-")
        case r'*' | r'x' | r'X' | r'×' => Some("×")
        case r'/' | r'÷' => Some("÷")
        case r'%' => Some("%")
        case r'=' => Some("=")
        // 其他字符不是计算器按键，忽略
        case _ => None
    }
}
