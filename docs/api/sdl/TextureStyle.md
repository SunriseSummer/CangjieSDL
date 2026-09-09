# TextureStyle

每次绘制的样式值。tint 默认白色；opacity 默认 1，取值 0..1；radius 为逻辑像素且默认 0；sampling 默认 Linear；flip 默认 None。圆角抗锯齿范围在目标矩形内部。样式完整记录在命令缓冲中，不修改共享纹理的颜色或透明度，使用独立的标准 Alpha 合成，原有混合模式和采样状态绘制后均恢复；这也保证 RGB/JPEG 等不透明来源的 opacity 有效。

```cangjie
public struct TextureStyle
```

## 字段

`tint: Color`、`opacity: Float32`、`radius: Float32`、`sampling: TextureScaleMode`、`flip: TextureFlip`。

### init

透明度或半径非有限、透明度不在 0..1 内，或半径为负时，抛出 `IllegalArgumentException`。

```cangjie
public init(tint!: Color = Color.rgb(255, 255, 255), opacity!: Float32 = 1.0,
        radius!: Float32 = 0.0, sampling!: TextureScaleMode = TextureScaleMode.Linear,
        flip!: TextureFlip = TextureFlip.None)
```
