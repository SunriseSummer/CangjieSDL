[sdl](../index.md) › [sdl](index.md) › WindowAspectRatio

# WindowAspectRatio

`sdl` 包中的 public struct

窗口宽高比约束的上下界，由 [`SdlWindow.aspectRatio`](SdlWindow.md#aspectratio) 返回。0 表示对应方向不限制。

## 声明

```cangjie
public struct WindowAspectRatio
```

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowAspectRatio, WindowSpec}

main(): Unit {
    // 需要显示环境，本示例仅作编译验证；运行时把窗口锁定为 16:9 并读回约束。
    try (window = SdlWindow(WindowSpec("宽高比", 640, 360))) {
        window.setAspectRatio(16.0 / 9.0, 16.0 / 9.0)
        let ratio: WindowAspectRatio = window.aspectRatio()
        println("最小 ${ratio.minimum} 最大 ${ratio.maximum}")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(minimum: Float32, maximum: Float32)`](#init) | 由上下界构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`minimum`](#minimum) | 最小宽高比；0 为不限制。 |
| [`maximum`](#maximum) | 最大宽高比；0 为不限制。 |

## 构造函数

### init

由上下界构造。

```cangjie
public init(minimum: Float32, maximum: Float32)
```

**参数**

- `minimum`、`maximum`: `Float32` — 宽高比上下界；0 表示不限制。

## 字段

### minimum

最小宽高比；0 为不限制。

```cangjie
public let minimum: Float32
```

### maximum

最大宽高比；0 为不限制。

```cangjie
public let maximum: Float32
```

## 另请参阅

- [SdlWindow.setAspectRatio](SdlWindow.md#setaspectratio) — 设置约束并校验参数。
