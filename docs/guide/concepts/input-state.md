# 输入事件与持续状态

## 先用一句话说明

按下、抬起、点击和滚轮是一次性事件；移动、拖拽和连射需要把这些事件转换为跨帧保存的状态，并在每次更新中读取。

## 为什么重要

本页沿用[窗口与事件循环](window-events-lifecycle.md)的每帧顺序，把事件收集阶段与持续更新阶段明确分开。

桌面按钮通常在一次 MouseDown 或 MouseUp 上触发一次动作，而游戏角色需要在按住方向键期间持续移动。若直接在 `KeyDown` 中移动固定距离，速度取决于操作系统键盘重复设置；若只处理按下不处理抬起，角色会永远移动；若把文本字符当扫描码解析，键盘布局、Shift 和输入法会产生错误。

`UiEvent.KeyDown` 给出 `Key` 和 repeat 标志，`KeyUp` 表示释放；`TextInput` 已由系统处理键盘布局和组合输入，适合文本与计算器字符；鼠标事件坐标属于逻辑空间，滚轮是增量；拖放按 Begin、File/Text/Position、Complete 组成序列。`Keyboard.modifiers()` 与 `Mouse.state(scale)` 是当前状态快照，不取代事件边沿。

## 工作模型

事件层负责“翻译”，状态层负责“记住”，更新层负责“持续作用”。例如 `KeyDown Left` 把 `leftHeld` 设为 true，`KeyUp Left` 设回 false，`updatePlayer(dt)` 每帧根据布尔值积分位移。单次动作可过滤 `repeat = true`，持续状态通常接受重复事件也无害，因为只是再次赋同一个值。

下面的反例把每次按键事件直接变成位移，操作系统重复频率会影响速度。

```cangjie role=contrast
case UiEvent.KeyDown(Key.Right, _) => playerX += 12.0
case UiEvent.KeyDown(Key.Left, _) => playerX -= 12.0
```

稳定结构保存状态，并在统一更新阶段使用时间步长。

```cangjie role=trace
case UiEvent.KeyDown(Key.Right, _) => input.rightHeld = true
case UiEvent.KeyUp(Key.Right) => input.rightHeld = false

if (input.rightHeld) {
    playerX += playerSpeed * dt
}
```

## 选择与取舍

按钮“点击”应选择 MouseUp 还是 MouseDown，取决于交互语义；需要允许按下后拖出取消时，用 Down 记录候选、Up 再确认。文本编辑用 `TextInput`，导航与快捷键用 `KeyDown`，不要混在一套字符映射里。需要全局鼠标捕获或相对模式时明确开启并在结束后恢复，否则光标行为会影响整个应用。

轮询快照适合启动时同步或恢复焦点后的修正，事件适合保留顺序和边沿。两者同时使用时要定义优先级，避免一帧中互相覆盖。Cursor 是资源，SystemCursor 枚举只是种类；创建、激活和关闭仍遵循资源边界。

## 应用这个模型

计算器的鼠标命中与 `TextInput` 最终都调用 `press(state, label)`，因此逻辑不关心设备。雷霆战机把方向键和空格转换成 `InputState`，系统每帧读取。拖放应用应在 DropBegin 清空本次收集，逐个接收 DropFile/DropText，在 DropComplete 后一次处理，避免文件还没收齐就开始耗时加载。

测试输入时记录事件种类、坐标、repeat 和当前状态，但不要把每帧所有 MouseMove 永久写日志。近迁移练习是为计算器增加鼠标按下反馈：Down 记录标签，Move 可更新是否仍在按钮内，Up 触发并清除；同一逻辑可迁移到游戏菜单。

## 常见误解

repeat 不是“按键当前仍按住”的权威状态；它只是重复的 KeyDown。`TextInput` 也不等于每次只有一个 ASCII 字符，字符串可能包含多个 Unicode 字符。鼠标全局状态的坐标缩放参数必须与应用逻辑空间一致。最后，捕获鼠标、隐藏光标或启用相对模式属于有副作用的运行状态，退出相关操作时要恢复。

## 相关 API

- [`UiEvent`](../../api/sdl/UiEvent.md)：事件种类与载荷。
- [`Key`](../../api/sdl/Key.md) 与 [`MouseButton`](../../api/sdl/MouseButton.md)：输入枚举。
- [`Keyboard`](../../api/sdl/input/Keyboard.md)：修饰键快照。
- [`Mouse`](../../api/sdl/input/Mouse.md) 与 [`Cursor`](../../api/sdl/input/Cursor.md)：鼠标状态、捕获和光标。

## 下一步

继续[时间步长与游戏循环](game-loop-timing.md)，把持续输入状态接入稳定的每帧更新。
