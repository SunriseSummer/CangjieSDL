[sdl](../../index.md) › [sdl.system](index.md) › AppMetadataType

# AppMetadataType

`sdl.system` 包中的 public enum

应用类别元数据的取值：普通应用、游戏、媒体播放器，或自定义字符串。

## 声明

```cangjie
public enum AppMetadataType
```

## 示例

```cangjie verify
package docexample

import sdl.system.{AppMetadata, AppMetadataType, ApplicationMetadata}

main(): Unit {
    var meta = AppMetadata(name: Some("绘图板"), version: Some("0.2.0"))
    meta.appType = Some(AppMetadataType.Application)
    ApplicationMetadata.apply(meta)
    println("元数据已应用")
    // 输出: 元数据已应用
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`Application`](#application) | 普通应用（SDL 值 `"application"`）。 |
| [`Game`](#game) | 游戏。 |
| [`MediaPlayer`](#mediaplayer) | 媒体播放器。 |
| [`CustomMetadataType(String)`](#custommetadatatype) | 自定义类别，携带传给 SDL 的字符串值。 |

## 枚举值

### Application

普通应用（SDL 值 `"application"`）。

```cangjie
Application
```

### Game

游戏。

```cangjie
Game
```

### MediaPlayer

媒体播放器。

```cangjie
MediaPlayer
```

### CustomMetadataType

自定义类别，携带传给 SDL 的字符串值。

```cangjie
CustomMetadataType(String)
```

## 另请参阅

- [AppMetadata](AppMetadata.md) — 经 `appType` 字段挂载。
