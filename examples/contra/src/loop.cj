package contra
import contra.config.*
import contra.model.*
import contra.sim.*
import contra.render.*

import sdl.Key
import sdl.MouseButton
import sdl.SdlWindow
import sdl.UiEvent
import sdl.clampF32

func runGame(window: SdlWindow, assets: GameAssets): Unit {
    let state = GameState()
    var lastTicks = window.ticks()

    while (state.isRunning) {
        let now = window.ticks()
        let dt = clampF32(Float32(now - lastTicks) / Stage.MS_PER_SECOND, 0.0, Stage.MAX_DELTA)
        lastTicks = now

        handleEvents(window, state)
        update(state, dt)
        draw(window.renderer, state, assets)
        window.delay(Stage.FRAME_DELAY_MS)
    }
}

func handleEvents(window: SdlWindow, state: GameState): Unit {
    var event = window.pollEvent()
    while (let Some(current) <- event) {
        match (current) {
            case UiEvent.Quit => state.isRunning = false
            case UiEvent.KeyDown(key, isRepeat) => setKey(state, key, true, isRepeat)
            case UiEvent.KeyUp(key) => setKey(state, key, false, false)
            case UiEvent.MouseMove(x, y) => setMousePosition(state, x, y)
            case UiEvent.MouseDown(MouseButton.Left, x, y) => setMouseFire(state, x, y, true)
            case UiEvent.MouseUp(MouseButton.Left, x, y) => setMouseFire(state, x, y, false)
            case _ => ()
        }
        event = window.pollEvent()
    }
}

func setKey(state: GameState, key: Key, isDown: Bool, isRepeat: Bool): Unit {
    match (key) {
        case Key.Escape =>
            if (isDown) {
                state.isRunning = false
            }
        case Key.Left => state.input.isLeftHeld = isDown
        case Key.Right => state.input.isRightHeld = isDown
        case Key.Up =>
            state.input.isUpHeld = isDown
            recaptureKeyboardAim(state, isDown, isRepeat)
        case Key.Down =>
            state.input.isDownHeld = isDown
            recaptureDownAim(state, isDown, isRepeat)
        case Key.Space => setJump(state, isDown, isRepeat)
        case Key.Enter =>
            if (isDown && !isPlaying(state.phase)) {
                resetGame(state)
            }
        case Key.Letter(code) => setLetterKey(state, code, isDown, isRepeat)
        case _ => ()
    }
}

func setLetterKey(state: GameState, code: UInt8, isDown: Bool, isRepeat: Bool): Unit {
    match (code) {
        case 65 => state.input.isLeftHeld = isDown // A
        case 68 => state.input.isRightHeld = isDown // D
        case 87 => // W
            state.input.isUpHeld = isDown
            recaptureKeyboardAim(state, isDown, isRepeat)
        case 83 => // S
            state.input.isDownHeld = isDown
            recaptureDownAim(state, isDown, isRepeat)
        case 75 => // K
            state.input.isFireHeld = isDown
            recaptureKeyboardAim(state, isDown, isRepeat)
        case 82 => // R
            if (isDown && !isPlaying(state.phase)) {
                resetGame(state)
            }
        case _ => ()
    }
}

/* 仅真实按下(非系统重复)时切回键盘瞄准,避免按住方向键时反复抢占鼠标模式。 */
func recaptureKeyboardAim(state: GameState, isDown: Bool, isRepeat: Bool): Unit {
    if (isDown && !isRepeat) {
        state.input.isUsingMouse = false
    }
}

/* 下键在地面上表示下蹲而非瞄准,此时保留鼠标瞄准,蹲下仍可用鼠标斜向射击。 */
func recaptureDownAim(state: GameState, isDown: Bool, isRepeat: Bool): Unit {
    if (!state.player.isOnGround) {
        recaptureKeyboardAim(state, isDown, isRepeat)
    }
}

func setJump(state: GameState, isDown: Bool, isRepeat: Bool): Unit {
    if (isDown && !isRepeat) {
        state.input.isJumpPressed = true
    }
}

func setMousePosition(state: GameState, x: Float32, y: Float32): Unit {
    state.input.mouseX = x
    state.input.mouseY = y
    state.input.isUsingMouse = true
}

func setMouseFire(state: GameState, x: Float32, y: Float32, isDown: Bool): Unit {
    setMousePosition(state, x, y)
    state.input.isMouseFireHeld = isDown
}
