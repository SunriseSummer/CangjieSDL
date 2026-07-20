[sdl](../index.md) › [sdl](index.md) › MouseButton

# MouseButton

`sdl` 包中的 public enum

解码后的鼠标按键；左/中/右之外的按键以 `RawCode` 携带 SDL 的按键码到达。

## 声明

```cangjie
public enum MouseButton
```

## 示例

```cangjie verify
package docexample

import sdl.MouseButton

main(): Unit {
    let button = MouseButton.Left
    match (button) {
        case MouseButton.Left => println("左键")
        case MouseButton.RawCode(code) => println("附加键 ${code}")
        case _ => println("中键或右键")
    }
    // 输出: 左键
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`Left`](#left) | 鼠标左键。 |
| [`Middle`](#middle) | 鼠标中键。 |
| [`Right`](#right) | 鼠标右键。 |
| [`RawCode(UInt8)`](#rawcode) | 其余按键（侧键等），携带 SDL 按键码。 |

## 枚举值

### Left

鼠标左键。

```cangjie
Left
```

### Middle

鼠标中键。

```cangjie
Middle
```

### Right

鼠标右键。

```cangjie
Right
```

### RawCode

其余按键（侧键等），携带 SDL 按键码。

```cangjie
RawCode(UInt8)
```

## 另请参阅

- [UiEvent](UiEvent.md) — `MouseDown` / `MouseUp` 事件携带本类型。
- [sdl.input 的 MouseState](input/MouseState.md) — 轮询式鼠标状态。
