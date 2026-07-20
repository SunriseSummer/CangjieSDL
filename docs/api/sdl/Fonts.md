[sdl](../index.md) › [sdl](index.md) › Fonts

# Fonts

`sdl` 包中的 public class

进程级注册表，把应用字体名映射到字体文件路径，类似 CSS 的 `@font-face` 表。启动时注册一次名字，之后在 [`Renderer.text`](Renderer.md#text) 的 `font` 参数中按名引用；渲染器在首次使用时懒加载并缓存字体文件。

## 声明

```cangjie
public class Fonts
```

## 说明

解析是宽容的：未注册的名字，或注册路径无法作为字体打开时，回退到平台 UI 字体而不是失败。注册只记录映射、不访问文件系统，因此可在任何窗口创建之前调用。注册表为全局且未加锁，与单线程 UI 模型一致；请在主线程、开始渲染之前注册字体。

## 示例

```cangjie verify
package docexample

import sdl.Fonts

main(): Unit {
    Fonts.register("正文", "C:/Windows/Fonts/msyh.ttc")
    println(Fonts.isRegistered("正文"))
    match (Fonts.pathFor("正文")) {
        case Some(path) => println(path)
        case None => println("未注册")
    }
    Fonts.unregister("正文")
    println(Fonts.names().size)
    // 输出:
    // true
    // C:/Windows/Fonts/msyh.ttc
    // 0
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`static register(name: String, path: String)`](#register) | 把名字映射到字体文件路径（`.ttf`、`.ttc` 或 `.otf`），重复注册同名即替换。 |
| [`static pathFor(name: String)`](#pathfor) | 返回名字对应的注册路径，未注册时为 `None`。 |
| [`static isRegistered(name: String)`](#isregistered) | 判断名字是否已注册。 |
| [`static unregister(name: String)`](#unregister) | 移除注册；从未注册时为空操作。 |
| [`static clear()`](#clear) | 清空全部注册，主要用于测试隔离。 |
| [`static names()`](#names) | 返回全部已注册名字，顺序不定。 |

## 方法

### register

把名字映射到字体文件路径（`.ttf`、`.ttc` 或 `.otf`），重复注册同名即替换。只记录映射，不访问文件系统。

```cangjie
public static func register(name: String, path: String): Unit
```

**参数**

- `name`: `String` — 应用内使用的字体名。
- `path`: `String` — 字体文件路径。

### pathFor

返回名字对应的注册路径，未注册时为 `None`。

```cangjie
public static func pathFor(name: String): ?String
```

**参数**

- `name`: `String` — 要查询的字体名。

**返回值** `?String` — 注册的路径；名字未知时为 `None`。

### isRegistered

判断名字是否已注册。

```cangjie
public static func isRegistered(name: String): Bool
```

**参数**

- `name`: `String` — 要查询的字体名。

**返回值** `Bool` — 已注册时为 `true`。

### unregister

移除注册；从未注册时为空操作。

```cangjie
public static func unregister(name: String): Unit
```

**参数**

- `name`: `String` — 要移除的字体名。

### clear

清空全部注册，主要用于测试隔离。

```cangjie
public static func clear(): Unit
```

### names

返回全部已注册名字，顺序不定。

```cangjie
public static func names(): Array<String>
```

**返回值** `Array<String>` — 已注册名字的数组。

## 另请参阅

- [Renderer.text](Renderer.md#text) — 按注册名选择字体绘制文本。
- [FontStyle](FontStyle.md) — 字重与修饰样式。
