[API 参考](../../index.md) › [sdl.system](index.md) › AppMetadataProperty

# AppMetadataProperty

可单独读写的应用元数据属性名。

```cangjie
public enum AppMetadataProperty {
    | Name
    | Version
    | Identifier
    | Creator
    | Copyright
    | Url
    | ApplicationType
    | CustomMetadataProperty(String)
}
```

| 值 | 含义 |
|---|---|
| `Name` | 应用显示名。 |
| `Version` | 应用版本。 |
| `Identifier` | 稳定的反向域名标识。 |
| `Creator` | 开发者或组织名称。 |
| `Copyright` | 版权声明。 |
| `Url` | 应用主页。 |
| `ApplicationType` | [`AppMetadataType`](AppMetadataType.md) 对应的字符串值。 |
| `CustomMetadataProperty(String)` | 完整的自定义 SDL 属性名；空名会被拒绝。 |

通过 [`ApplicationMetadata`](ApplicationMetadata.md) 设置、读取或移除属性。
