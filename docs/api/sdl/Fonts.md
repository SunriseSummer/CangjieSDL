[sdl](../index.md) › [sdl](index.md) › Fonts

# Fonts

位于 `sdl` 包的公开类。

进程级注册表，把应用字体名映射到有序字体链，类似 CSS 的 `font-family` / `@font-face`。启动时注册一次名字，之后在 [`Renderer.text`](Renderer.md#text) 的 `font` 参数中按名引用；渲染器在首次使用时懒加载并缓存字体文件。

## 声明

```cangjie
public class Fonts
```

## 说明

主字体缺少字形时，会按 `fallbackPaths` 的顺序尝试同字号、同样式的回退字体，最后使用平台 UI 字体。字体名称未注册或文件无法打开时也会回退。注册操作只保存映射，不访问文件，因此可以在创建窗口前完成。注册表是未加锁的进程级状态，应在主线程、首次渲染前修改。

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
| [`static registerFamily(name: String, primaryPath: String, fallbackPaths!: Array<String>)`](#registerfamily) | 注册主字体与有序缺字回退链。 |
| [`static fallbackPathsFor(name: String)`](#fallbackpathsfor) | 返回独立的回退字体路径数组。 |
| [`static pathFor(name: String)`](#pathfor) | 返回名字对应的注册路径，未注册时为 `None`。 |
| [`static isRegistered(name: String)`](#isregistered) | 判断名字是否已注册。 |
| [`static unregister(name: String)`](#unregister) | 移除注册；从未注册时为空操作。 |
| [`static clear()`](#clear) | 清空全部注册，主要用于测试隔离。 |
| [`static revision()`](#revision) | 返回注册表变化代数，供文本布局缓存安全失效。 |
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

### registerFamily

注册主字体和按顺序尝试的缺字回退字体。SDL_ttf 只在当前字体缺少字形时尝试下一项，每个字体使用相同字号和样式。更改注册会推进 `revision`，现有渲染器随后清空相关度量与旋转文字缓存。

```cangjie
public static func registerFamily(name: String, primaryPath: String,
    fallbackPaths!: Array<String> = []): Unit
```

### fallbackPathsFor

```cangjie
public static func fallbackPathsFor(name: String): Array<String>
```

返回注册顺序的独立数组；未知名字返回空数组。

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

### revision

返回注册表变化代数。`register`、`unregister` 或 `clear` 后都会变化；上层文本布局缓存可把它纳入键，避免同名字重新绑定字体后复用旧断行。

```cangjie
public static func revision(): UInt64
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
