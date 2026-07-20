[sdl](../../index.md) › [sdl.input](index.md) › Cursor

# Cursor

`sdl.input` 包中的 public class

一个原生鼠标光标对象，加上光标显隐的静态控制。经 [`system`](#system) 从系统形状创建，[`setActive`](#setactive) 生效；[`close`](#close) 会先切回默认光标再销毁，避免活动光标指向已释放的对象。SDL 无法创建、切换或显示/隐藏光标时，方法把失败状态转换为 `CuiException`。

## 声明

```cangjie
public class Cursor <: Resource
```

## 继承

- `Resource`（标准库 `std.core`）——支持 `try (…)` 资源语法；[`close`](#close) 幂等。

## 示例

```cangjie verify
package docexample

import sdl.{SdlWindow, WindowSpec}
import sdl.input.{Cursor, SystemCursor}

main(): Unit {
    // 光标需要视频子系统，本示例仅作编译验证；
    // 运行时把指针换成“禁止”形状，离开 try 块后自动恢复默认。
    try (window = SdlWindow(WindowSpec("拖放目标", 320, 240))) {
        try (denied = Cursor.system(SystemCursor.NotAllowed)) {
            denied.setActive()
            println(Cursor.isVisible())
            window.delay(1)
        }
    }
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`static system(kind: SystemCursor)`](#system) | 创建一个系统形状的原生光标。 |
| [`setActive()`](#setactive) | 把本光标设为当前指针形状。 |
| [`isClosed()`](#isclosed) | 判断光标是否已关闭。 |
| [`close()`](#close) | 切回默认光标并销毁本光标；幂等，重复调用为空操作。 |
| [`static show()`](#show) | 显示操作系统光标。 |
| [`static hide()`](#hide) | 隐藏操作系统光标。 |
| [`static isVisible()`](#isvisible) | 判断操作系统光标是否可见。 |

## 方法

### system

创建一个系统形状的原生光标。

```cangjie
public static func system(kind: SystemCursor): Cursor
```

**参数**

- `kind`: `SystemCursor` — 系统光标形状。

**返回值** `Cursor` — 新建的光标对象。

**异常**

- `CuiException` — SDL 无法创建该原生光标时。

### setActive

把本光标设为当前指针形状。

```cangjie
public func setActive(): Unit
```

**异常**

- `CuiException` — 光标已关闭，或 SDL 无法激活时。

### isClosed

判断光标是否已关闭。

```cangjie
public func isClosed(): Bool
```

**返回值** `Bool` — [`close`](#close) 调用之后为 `true`。

### close

切回默认光标并销毁本光标；幂等，重复调用为空操作。

```cangjie
public func close(): Unit
```

### show

显示操作系统光标。

```cangjie
public static func show(): Unit
```

**异常**

- `CuiException` — SDL 无法显示光标时。

### hide

隐藏操作系统光标。

```cangjie
public static func hide(): Unit
```

**异常**

- `CuiException` — SDL 无法隐藏光标时。

### isVisible

判断操作系统光标是否可见。

```cangjie
public static func isVisible(): Bool
```

**返回值** `Bool` — 可见时为 `true`。

## 另请参阅

- [SystemCursor](SystemCursor.md) — 可选的系统形状。
- [SdlWindow.setRelativeMouseMode](../SdlWindow.md#setrelativemousemode) — 隐藏光标并报告相对位移的输入形态。
