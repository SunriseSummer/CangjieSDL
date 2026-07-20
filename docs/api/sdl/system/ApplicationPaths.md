[sdl](../../index.md) › [sdl.system](index.md) › ApplicationPaths

# ApplicationPaths

`sdl.system` 包中的 public class

应用相关目录的查询入口：可执行文件所在目录、当前目录、按组织/应用名生成的首选项目录，以及标准用户目录。返回 `String` 的 `currentDirectory` / `preferencePath` 在 SDL 无法解析目录时抛出 `CuiException`；返回 `?String` 的 `basePath` / `userFolder` 以 `None` 表示不可用。

## 声明

```cangjie
public class ApplicationPaths
```

## 示例

```cangjie verify
package docexample

import sdl.system.ApplicationPaths

main(): Unit {
    let prefs = ApplicationPaths.preferencePath("示例工作室", "绘图板")
    println("首选项目录非空：${prefs.size > 0}")
    match (ApplicationPaths.basePath()) {
        case Some(base) => println("可执行目录非空：${base.size > 0}")
        case None => println("basePath 不可用")
    }
    // 输出:
    // 首选项目录非空：true
    // 可执行目录非空：true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `ApplicationPaths` 对象；目录查询由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static basePath()`](#basepath) | 可执行文件所在目录；平台不提供时为 `None`。 |
| [`static currentDirectory()`](#currentdirectory) | 进程当前工作目录。 |
| [`static preferencePath(org: String, app: String)`](#preferencepath) | 按组织/应用名生成（并确保存在）可写的首选项目录——配置与存档的标准去处。 |
| [`static userFolder(folder: UserFolder)`](#userfolder) | 标准用户目录路径；平台不提供时为 `None`。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `ApplicationPaths` 对象；目录查询由静态方法提供。

```cangjie
public init()
```

## 方法

### basePath

可执行文件所在目录；平台不提供时为 `None`。适合定位随应用分发的资源文件。

```cangjie
public static func basePath(): ?String
```

**返回值** `?String` — 目录路径（带结尾分隔符），或 `None`。

### currentDirectory

进程当前工作目录。

```cangjie
public static func currentDirectory(): String
```

**返回值** `String` — 当前目录路径。

**异常**

- `CuiException` — SDL 无法解析当前目录时。

### preferencePath

按组织/应用名生成（并确保存在）可写的首选项目录——配置与存档的标准去处。

```cangjie
public static func preferencePath(org: String, app: String): String
```

**参数**

- `org`: `String` — 组织名；须非空。
- `app`: `String` — 应用名；须非空。

**返回值** `String` — 可写目录路径（带结尾分隔符）。

**异常**

- `CuiException` — 组织或应用名为空，或 SDL 无法创建目录时。

### userFolder

标准用户目录路径；平台不提供时为 `None`。

```cangjie
public static func userFolder(folder: UserFolder): ?String
```

**参数**

- `folder`: `UserFolder` — 目录类别。

**返回值** `?String` — 目录路径，或 `None`。

## 另请参阅

- [UserFolder](UserFolder.md) — 目录类别。
- [FileSystem](FileSystem.md) — 文件操作。
