[sdl](../../index.md) › [sdl.system](index.md) › PathInfo

# PathInfo

`sdl.system` 包中的 public struct

一个路径的元信息：条目种类、字节大小与创建/修改/访问三组时间戳（SDL 时间，纳秒）。由 [`FileSystem.pathInfo`](FileSystem.md#pathinfo) 返回。

## 声明

```cangjie
public struct PathInfo
```

## 示例

```cangjie verify
package docexample

import sdl.system.{FileSystem, PathInfo}

main(): Unit {
    let found: ?PathInfo = FileSystem.pathInfo("C:/Windows/notepad.exe")
    match (found) {
        case Some(info) => println("大小 ${info.size} 字节")
        case None => println("不存在")
    }
    // 运行时打印文件大小或"不存在"。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(entryType: FileSystemEntryType, size: UInt64, createTime: Int64, modifyTime: Int64, accessTime: Int64)`](#init) | 逐项构造。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`entryType`](#entrytype) | 条目种类。 |
| [`size`](#size) | 大小，字节；目录为 0。 |
| [`createTime`](#createtime) | 创建时间，SDL 纳秒时间戳。 |
| [`modifyTime`](#modifytime) | 最后修改时间，SDL 纳秒时间戳。 |
| [`accessTime`](#accesstime) | 最后访问时间，SDL 纳秒时间戳。 |

## 构造函数

### init

逐项构造。

```cangjie
public init(entryType: FileSystemEntryType, size: UInt64, createTime: Int64, modifyTime: Int64, accessTime: Int64)
```

**参数**

- `entryType`: `FileSystemEntryType` — 条目种类。
- `size`: `UInt64` — 字节大小。
- `createTime`、`modifyTime`、`accessTime`: `Int64` — 纳秒时间戳，可交给 [`Time.toDateTime`](Time.md#todatetime) 转日历字段。

## 字段

### entryType

条目种类。

```cangjie
public let entryType: FileSystemEntryType
```

### size

大小，字节；目录为 0。

```cangjie
public let size: UInt64
```

### createTime

创建时间，SDL 纳秒时间戳。

```cangjie
public let createTime: Int64
```

### modifyTime

最后修改时间，SDL 纳秒时间戳。

```cangjie
public let modifyTime: Int64
```

### accessTime

最后访问时间，SDL 纳秒时间戳。

```cangjie
public let accessTime: Int64
```

## 另请参阅

- [FileSystem.pathInfo](FileSystem.md#pathinfo) — 查询入口。
- [Time.toDateTime](Time.md#todatetime) — 时间戳转日历字段。
