[sdl](../../index.md) › [sdl.system](index.md) › AppMetadataProperty

# AppMetadataProperty

`sdl.system` 包中的 public enum

可单独读写的应用元数据属性名；`CustomMetadataProperty` 携带任意 SDL 属性名。

## 声明

```cangjie
public enum AppMetadataProperty
```

## 示例

```cangjie verify
package docexample

import sdl.system.{AppMetadataProperty, ApplicationMetadata}

main(): Unit {
    ApplicationMetadata.set(AppMetadataProperty.Name, "绘图板")
    match (ApplicationMetadata.get(AppMetadataProperty.Name)) {
        case Some(name) => println(name)
        case None => println("未设置")
    }
    // 输出: 绘图板
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| [`Name`](#name) | 应用名。 |
| [`Version`](#version) | 版本号。 |
| [`Identifier`](#identifier) | 反域名标识（如 `com.example.plot`）。 |
| [`Creator`](#creator) | 开发者/公司名。 |
| [`Copyright`](#copyright) | 版权声明。 |
| [`Url`](#url) | 应用主页。 |
| [`ApplicationType`](#applicationtype) | 应用类别（对应 `AppMetadataType` 的字符串值）。 |
| [`CustomMetadataProperty(String)`](#custommetadataproperty) | 自定义属性，携带完整的 SDL 属性名；空名在读写时抛 `CuiException`。 |

## 枚举值

### Name

应用名。

```cangjie
Name
```

### Version

版本号。

```cangjie
Version
```

### Identifier

反域名标识（如 `com.example.plot`）。

```cangjie
Identifier
```

### Creator

开发者/公司名。

```cangjie
Creator
```

### Copyright

版权声明。

```cangjie
Copyright
```

### Url

应用主页。

```cangjie
Url
```

### ApplicationType

应用类别（对应 [`AppMetadataType`](AppMetadataType.md) 的字符串值）。

```cangjie
ApplicationType
```

### CustomMetadataProperty

自定义属性，携带完整的 SDL 属性名；空名在读写时抛 `CuiException`。

```cangjie
CustomMetadataProperty(String)
```

## 另请参阅

- [ApplicationMetadata](ApplicationMetadata.md) — 逐项读写入口。
