[sdl](../../index.md) › [sdl.system](index.md) › FileSystem

# FileSystem

`sdl.system` 包中的 public class

SDL 文件系统操作的入口：建目录、删除、改名、复制、查询，以及按通配模式列出目录。全部方法先拒绝空路径；写操作和目录枚举会把 SDL 失败转换为 `CuiException`。`pathInfo` 无法区分“路径不存在”和底层查询失败，两者都返回 `None`；`exists` 相应返回 `false`。

## 声明

```cangjie
public class FileSystem
```

## 示例

```cangjie verify
package docexample

import sdl.system.FileSystem

main(): Unit {
    let dir = "docexample_fs_demo"
    FileSystem.createDirectory(dir)
    println(FileSystem.exists(dir))
    FileSystem.remove(dir)
    println(FileSystem.exists(dir))
    // 输出:
    // true
    // false
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `FileSystem` 对象；文件系统操作由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static createDirectory(path: String)`](#createdirectory) | 创建目录，父目录一并补齐；目录已存在时成功返回。 |
| [`static remove(path: String)`](#remove) | 删除文件或空目录。 |
| [`static rename(oldPath: String, newPath: String)`](#rename) | 改名/移动文件或目录。 |
| [`static copyFile(source: String, destination: String)`](#copyfile) | 复制文件。 |
| [`static pathInfo(path: String)`](#pathinfo) | 查询路径元信息；路径不存在或 SDL 查询失败时为 `None`。 |
| [`static exists(path: String)`](#exists) | 判断 `pathInfo` 是否返回值；路径不存在和 SDL 查询失败都得到 `false`。 |
| [`static globDirectory(path: String, pattern!: ?String, caseInsensitive!: Bool)`](#globdirectory) | 枚举目录内容，可选通配模式过滤（SDL 通配语法，`*` 与 `?`）。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `FileSystem` 对象；文件系统操作由静态方法提供。

```cangjie
public init()
```

## 方法

### createDirectory

创建目录，父目录一并补齐；目录已存在时成功返回。

```cangjie
public static func createDirectory(path: String): Unit
```

**参数**

- `path`: `String` — 目录路径；须非空。

**异常**

- `CuiException` — 路径为空，或 SDL 无法创建目录树时。

### remove

删除文件或空目录。

```cangjie
public static func remove(path: String): Unit
```

**参数**

- `path`: `String` — 目标路径；须非空。

**异常**

- `CuiException` — 路径为空，或 SDL 无法删除（如目录非空）时。

### rename

改名/移动文件或目录。

```cangjie
public static func rename(oldPath: String, newPath: String): Unit
```

**参数**

- `oldPath`: `String` — 现路径；须非空。
- `newPath`: `String` — 新路径；须非空。

**异常**

- `CuiException` — 任一路径为空，或 SDL 无法改名时。

### copyFile

复制文件。

```cangjie
public static func copyFile(source: String, destination: String): Unit
```

**参数**

- `source`: `String` — 源文件；须非空。
- `destination`: `String` — 目标文件；须非空，已存在时被覆盖。

**异常**

- `CuiException` — 任一路径为空，或 SDL 无法复制时。

### pathInfo

查询路径元信息；路径不存在或 SDL 查询失败时为 `None`。

```cangjie
public static func pathInfo(path: String): ?PathInfo
```

**参数**

- `path`: `String` — 查询路径；须非空。

**返回值** `?PathInfo` — 元信息；路径不存在或 SDL 查询失败时为 `None`。

**异常**

- `CuiException` — 路径为空时。

### exists

判断 [`pathInfo`](#pathinfo) 是否返回值；路径不存在和 SDL 查询失败都得到 `false`。

```cangjie
public static func exists(path: String): Bool
```

**参数**

- `path`: `String` — 查询路径；须非空。

**返回值** `Bool` — `pathInfo` 返回值时为 `true`，返回 `None` 时为 `false`。

**异常**

- `CuiException` — 路径为空时。

### globDirectory

枚举目录内容，可选通配模式过滤（SDL 通配语法，`*` 与 `?`）。

```cangjie
public static func globDirectory(path: String, pattern!: ?String = None, caseInsensitive!: Bool = false): Array<String>
```

**参数**

- `path`: `String` — 目录路径；须非空。
- `pattern!`: `?String` — 通配模式；默认 `None`（全部条目）。
- `caseInsensitive!`: `Bool` — 匹配是否忽略大小写；默认 `false`。

**返回值** `Array<String>` — 相对于 `path` 的条目名数组。

**异常**

- `CuiException` — 路径为空，或 SDL 无法枚举目录时。

## 另请参阅

- [PathInfo](PathInfo.md) · [FileSystemEntryType](FileSystemEntryType.md)
- [ApplicationPaths](ApplicationPaths.md) — 标准目录的定位。
