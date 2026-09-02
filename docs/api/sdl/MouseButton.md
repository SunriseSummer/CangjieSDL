[API 参考](../index.md) › [sdl](index.md) › MouseButton

# MouseButton

解码后的鼠标按键。

```cangjie
public enum MouseButton {
    | Left
    | Middle
    | Right
    | RawCode(UInt8)
}
```

## 示例

```cangjie verify role=complete
package docexample

import sdl.MouseButton

main(): Unit {
    let button = MouseButton.Left
    match (button) {
        case MouseButton.Left => println("左键")
        case MouseButton.RawCode(code) => println("附加键 ${code}")
        case _ => println("中键或右键")
    }
}
```

| 值 | 含义 |
|---|---|
| `Left` | 鼠标左键。 |
| `Middle` | 鼠标中键。 |
| `Right` | 鼠标右键。 |
| `RawCode(UInt8)` | 侧键等其他按键，保留 SDL 按键码。 |

事件式输入见 [`UiEvent`](UiEvent.md)，轮询式状态见 [`sdl.input.MouseState`](input/MouseState.md)。
