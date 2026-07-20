[sdl](../index.md) › [sdl](index.md) › CuiException

# CuiException

`sdl` 包中的 public class

SDL 调用失败、参数非法或资源已关闭时，本模块会抛出 `CuiException`。异常消息说明失败的操作；SDL 调用失败时还会附带 `SDL_GetError` 返回的错误文本。

## 声明

```cangjie
public class CuiException <: Exception
```

## 继承

- `Exception`（标准库 `std.core`）

## 示例

```cangjie verify
package docexample

import sdl.{CuiException, Renderer}

main(): Unit {
    let r = Renderer.headless()
    try {
        r.setScale(0.0) // 非法缩放比例
    } catch (e: CuiException) {
        println("捕获：${e.message}")
    }
    // 输出: 捕获：Renderer scale must be greater than 0.
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(message: String)`](#init) | 以描述信息构造异常。 |

## 构造函数

### init

以描述信息构造异常。

```cangjie
public init(message: String)
```

**参数**

- `message`: `String` — 异常描述，之后可从 `message` 属性读取。
