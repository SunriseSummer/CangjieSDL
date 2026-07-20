[sdl](../../index.md) › [sdl.system](index.md) › FileSystemEntryType

# FileSystemEntryType

`sdl.system` 包中的 public enum

文件系统条目的种类，出现在 [`PathInfo.entryType`](PathInfo.md#entrytype) 中。SDL 报告未知种类时映射为 `Missing`。

## 声明

```cangjie
public enum FileSystemEntryType
```

## 示例

```cangjie verify
package docexample

import sdl.system.{FileSystem, FileSystemEntryType}

main(): Unit {
    match (FileSystem.pathInfo("C:/Windows")) {
        case Some(info) => match (info.entryType) {
            case FileSystemEntryType.Directory => println("是目录")
            case FileSystemEntryType.File => println("是文件")
            case _ => println("其他")
        }
        case None => println("不存在")
    }
    // 输出: 是目录
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Missing` | 路径不存在（或种类未知）。 |
| `File` | 普通文件。 |
| `Directory` | 目录。 |
| `Other` | 其他条目（设备、管道等）。 |

## 另请参阅

- [PathInfo](PathInfo.md) · [FileSystem.pathInfo](FileSystem.md#pathinfo)
