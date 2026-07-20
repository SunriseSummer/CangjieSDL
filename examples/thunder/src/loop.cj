package game

import sdl.Key
import sdl.SdlWindow
import sdl.UiEvent
import sdl.clampF32

func runGame(window: SdlWindow): Unit {
    let state = GameState()
    var lastTicks = window.ticks()

    while (state.isRunning) {
        let now = window.ticks()
        // 拖动窗口等停顿会产生超大帧间隔，截断以免实体瞬移
        let dt = clampF32(Float32(now - lastTicks) / Stage.MS_PER_SECOND, 0.0, Stage.MAX_DELTA)
        lastTicks = now

        handleEvents(window, state)
        update(state, dt)
        draw(window.renderer, state)
        window.delay(Stage.FRAME_DELAY_MS)
    }
}

func handleEvents(window: SdlWindow, state: GameState): Unit {
    var event = window.pollEvent()
    while (let Some(e) <- event) {
        match (e) {
            case UiEvent.Quit => state.isRunning = false
            case UiEvent.KeyDown(key, _) => setKey(state, key, true)
            case UiEvent.KeyUp(key) => setKey(state, key, false)
            // 其余事件（鼠标、文本输入等）与这款键盘游戏无关
            case _ => ()
        }
        event = window.pollEvent()
    }
}

func setKey(state: GameState, key: Key, isDown: Bool): Unit {
    match (key) {
        case Key.Escape =>
            if (isDown) {
                state.isRunning = false
            }
        case Key.Left => state.input.isLeftHeld = isDown
        case Key.Right => state.input.isRightHeld = isDown
        case Key.Up => state.input.isUpHeld = isDown
        case Key.Down => state.input.isDownHeld = isDown
        case Key.Space =>
            state.input.isFireHeld = isDown
            if (isDown && state.isOver) {
                resetGame(state)
            }
        // 其余按键不参与操作
        case _ => ()
    }
}
