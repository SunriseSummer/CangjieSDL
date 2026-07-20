[sdl](../../index.md) › [sdl.system](index.md) › ApplicationMetadata

# ApplicationMetadata

`sdl.system` 包中的 public class

应用元数据的写入与查询入口。元数据供操作系统在任务管理器、音量面板等处显示应用信息；在创建窗口之前设置。SDL 无法写入、更新或移除元数据时，方法把失败状态转换为 `CuiException`。

## 声明

```cangjie
public class ApplicationMetadata
```

## 示例

```cangjie verify
package docexample

import sdl.system.{AppMetadata, AppMetadataProperty, ApplicationMetadata}

main(): Unit {
    ApplicationMetadata.apply(AppMetadata(name: Some("绘图板"), version: Some("0.2.0")))
    ApplicationMetadata.set(AppMetadataProperty.Url, "https://example.com/plot")
    match (ApplicationMetadata.get(AppMetadataProperty.Version)) {
        case Some(version) => println("版本 ${version}")
        case None => println("未设置")
    }
    ApplicationMetadata.remove(AppMetadataProperty.Url)
    // 输出: 版本 0.2.0
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个不含实例状态的 `ApplicationMetadata` 对象；元数据操作由静态方法提供。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static apply(metadata: AppMetadata)`](#apply) | 一次性应用整套元数据；`None` 字段不写入。 |
| [`static set(property: AppMetadataProperty, value: String)`](#set) | 写入单项元数据。 |
| [`static remove(property: AppMetadataProperty)`](#remove) | 移除单项元数据。 |
| [`static get(property: AppMetadataProperty)`](#get) | 读取单项元数据；未设置时为 `None`。 |

## 构造函数

### init

**由编译器生成：** 依据仓颉默认构造规则生成的公开无参构造函数。

创建一个不含实例状态的 `ApplicationMetadata` 对象；元数据操作由静态方法提供。

```cangjie
public init()
```

## 方法

### apply

一次性应用整套元数据；`None` 字段不写入。名称/版本/标识符经 SDL_SetAppMetadata 设置，其余逐项设置。

```cangjie
public static func apply(metadata: AppMetadata): Unit
```

**参数**

- `metadata`: `AppMetadata` — 元数据集合。

**异常**

- `CuiException` — SDL 无法应用元数据时。

### set

写入单项元数据。

```cangjie
public static func set(property: AppMetadataProperty, value: String): Unit
```

**参数**

- `property`: `AppMetadataProperty` — 属性名；自定义属性名须非空。
- `value`: `String` — 属性值。

**异常**

- `CuiException` — 属性名为空，或 SDL 无法设置时。

### remove

移除单项元数据。

```cangjie
public static func remove(property: AppMetadataProperty): Unit
```

**参数**

- `property`: `AppMetadataProperty` — 属性名；自定义属性名须非空。

**异常**

- `CuiException` — 属性名为空，或 SDL 无法移除时。

### get

读取单项元数据；未设置时为 `None`。

```cangjie
public static func get(property: AppMetadataProperty): ?String
```

**参数**

- `property`: `AppMetadataProperty` — 属性名；自定义属性名须非空。

**返回值** `?String` — 属性值，或 `None`。

**异常**

- `CuiException` — 属性名为空时。

## 另请参阅

- [AppMetadata](AppMetadata.md) · [AppMetadataProperty](AppMetadataProperty.md)
