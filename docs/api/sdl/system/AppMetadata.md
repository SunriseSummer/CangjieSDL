[sdl](../../index.md) › [sdl.system](index.md) › AppMetadata

# AppMetadata

`sdl.system` 包中的 public struct

一组应用元数据：名称、版本、标识符、开发者、版权、主页与类别，全部可选。交给 [`ApplicationMetadata.apply`](ApplicationMetadata.md#apply) 一次性应用。

## 声明

```cangjie
public struct AppMetadata
```

## 示例

```cangjie verify
package docexample

import sdl.system.{AppMetadata, ApplicationMetadata}

main(): Unit {
    var meta = AppMetadata(
        name: Some("绘图板"),
        version: Some("0.2.0"),
        identifier: Some("com.example.plot")
    )
    meta.creator = Some("示例工作室")
    ApplicationMetadata.apply(meta)
    println("已应用 ${meta.name ?? "?"}")
    // 输出: 已应用 绘图板
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(name!: ?String, version!: ?String, identifier!: ?String)`](#init) | 由名称/版本/标识符构造；其余字段初始为 `None`，构造后直接赋值。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`name`](#name) | 应用名；`None` 不设置。 |
| [`version`](#version) | 版本号；`None` 不设置。 |
| [`identifier`](#identifier) | 反域名标识；`None` 不设置。 |
| [`creator`](#creator) | 开发者/公司名；`None` 不设置。 |
| [`copyright`](#copyright) | 版权声明；`None` 不设置。 |
| [`url`](#url) | 应用主页；`None` 不设置。 |
| [`appType`](#apptype) | 应用类别；`None` 不设置。 |

## 构造函数

### init

由名称/版本/标识符构造；其余字段初始为 `None`，构造后直接赋值。

```cangjie
public init(name!: ?String = None, version!: ?String = None, identifier!: ?String = None)
```

**参数**

- `name!`: `?String` — 应用名；默认 `None`。
- `version!`: `?String` — 版本号；默认 `None`。
- `identifier!`: `?String` — 反域名标识；默认 `None`。

## 字段

### name

应用名；`None` 不设置。

```cangjie
public var name: ?String
```

### version

版本号；`None` 不设置。

```cangjie
public var version: ?String
```

### identifier

反域名标识；`None` 不设置。

```cangjie
public var identifier: ?String
```

### creator

开发者/公司名；`None` 不设置。

```cangjie
public var creator: ?String
```

### copyright

版权声明；`None` 不设置。

```cangjie
public var copyright: ?String
```

### url

应用主页；`None` 不设置。

```cangjie
public var url: ?String
```

### appType

应用类别；`None` 不设置。

```cangjie
public var appType: ?AppMetadataType
```

## 另请参阅

- [ApplicationMetadata](ApplicationMetadata.md) — 应用与逐项读写。
- [AppMetadataType](AppMetadataType.md) — 类别取值。
