[API 参考](../../index.md) › [sdl.system](index.md) › AppMetadataType

# AppMetadataType

应用类别元数据的取值。

```cangjie
public enum AppMetadataType {
    | Application
    | Game
    | MediaPlayer
    | CustomMetadataType(String)
}
```

| 值 | 含义 |
|---|---|
| `Application` | 普通应用。 |
| `Game` | 游戏。 |
| `MediaPlayer` | 媒体播放器。 |
| `CustomMetadataType(String)` | 直接传给 SDL 的自定义类别字符串。 |

该值用于 [`AppMetadata.appType`](AppMetadata.md)。
