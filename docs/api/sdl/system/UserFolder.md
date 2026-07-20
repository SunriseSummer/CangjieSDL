[sdl](../../index.md) › [sdl.system](index.md) › UserFolder

# UserFolder

`sdl.system` 包中的 public enum

操作系统的标准用户目录，交给 [`ApplicationPaths.userFolder`](ApplicationPaths.md#userfolder) 解析为具体路径。

## 声明

```cangjie
public enum UserFolder
```

## 示例

```cangjie verify
package docexample

import sdl.system.{ApplicationPaths, UserFolder}

main(): Unit {
    match (ApplicationPaths.userFolder(UserFolder.Documents)) {
        case Some(path) => println("文档目录存在：${path.size > 0}")
        case None => println("平台未提供文档目录")
    }
    // 输出: 文档目录存在：true
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Home` | 用户主目录。 |
| `Desktop` | 桌面。 |
| `Documents` | 文档。 |
| `Downloads` | 下载。 |
| `Music` | 音乐。 |
| `Pictures` | 图片。 |
| `PublicShare` | 公共共享。 |
| `SavedGames` | 游戏存档。 |
| `Screenshots` | 屏幕截图。 |
| `Templates` | 模板。 |
| `Videos` | 视频。 |

## 另请参阅

- [ApplicationPaths.userFolder](ApplicationPaths.md#userfolder) — 解析入口。
