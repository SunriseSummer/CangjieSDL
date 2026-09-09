# ImageLoadOptions

尺寸单位为解码像素，width、height 默认 0（不约束），maxPixels 默认 67108864。保持比例，位图只缩小，SVG 可按指定大小栅格化。预算在解码完成后、位图缩小前检查，不限制第三方解码器内部的临时内存。

```cangjie
public struct ImageLoadOptions
```

## 字段

`width: Int32`、`height: Int32`、`maxPixels: Int64`。

### init

宽高为负、像素预算非正，或两项非零请求尺寸的乘积超过预算时，抛出 `IllegalArgumentException`。原图解码后超过预算时，加载入口抛出 `SdlException`，即使请求的缩略图尺寸很小也不例外。

```cangjie
public init(width!: Int32 = 0, height!: Int32 = 0, maxPixels!: Int64 = 67108864)
```
