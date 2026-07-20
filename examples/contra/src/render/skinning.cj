package contra.render

import contra.geom.*
import std.collection.ArrayList
import sdl.Point
import sdl.Rect

/*
 * 四肢蒙皮(2D 线性混合蒙皮 + 关节交叉淡化)。
 *
 * 大腿/小腿、大臂/小臂不再作为两块刚体贴图各自旋转,而是沿"根关节→中间关节→
 * 末端"骨链铺三角条带:关节混合区内,顶点位置与切向按 smoothstep 权重在两根
 * 骨骼的刚体变换之间混合,并共享同一宽度剖面,于是肘/膝呈连续圆角弯曲。
 *
 * 两段美术图在接缝处明暗不一定连续,所以再做交叉淡化:
 *  - 膝/肘:两段各向对方延伸 KNEE_OVERLAP 弧长(纹理轻微拉伸),上段作不透明底、
 *    下段在交叠带内 smoothstep 渐入盖住,把色调缝混掉,也不会漏出背景。
 *  - 髋部(drawHipBlend):腰带盖住大腿顶端后,把大腿顶端沿腰带下沿向上渐隐叠回,
 *    让摆动的大腿以柔边自然探入固定腰带下方。
 */
let LIMB_SKIN_SLICES: Int64 = 16
let LIMB_BLEND_RATIO: Float32 = 0.36
let LIMB_KNEE_OVERLAP: Float32 = 5.5

/* 髋部融合:大腿顶端沿骨轴向下的采样范围与向上渐隐窗口(相对髋关节的弧长)。 */
let HIP_BLEND_TOP: Float32 = -4.0
let HIP_BLEND_BOTTOM: Float32 = 18.0
let HIP_BLEND_FADE_START: Float32 = 4.0
let HIP_BLEND_FADE_FULL: Float32 = 15.0

/* 蒙皮部件参数:图集区域、关节所在的源图纵向行、绘制缩放。 */
type LimbPartSpec = (Rect, Float32, Float32)

/* 一条肢体的脊骨:两段方向、上段长度与关节混合半径,供沿弧长采样。 */
class LimbSpine {
    let rootX: Float32
    let rootY: Float32
    let midX: Float32
    let midY: Float32
    let upperDirX: Float32
    let upperDirY: Float32
    let lowerDirX: Float32
    let lowerDirY: Float32
    let upperLength: Float32
    let blendRadius: Float32

    init(root: RigPoint, mid: RigPoint, end: RigPoint) {
        rootX = root.x
        rootY = root.y
        midX = mid.x
        midY = mid.y
        upperLength = pointDistance(root, mid)
        let lowerLength = pointDistance(mid, end)
        let (d1x, d1y) = normalized(mid.x - root.x, mid.y - root.y)
        let (d2x, d2y) = normalized(end.x - mid.x, end.y - mid.y)
        upperDirX = d1x
        upperDirY = d1y
        lowerDirX = d2x
        lowerDirY = d2y
        let radius = min(upperLength, lowerLength) * LIMB_BLEND_RATIO
        blendRadius = if (radius < 2.0) {
            2.0
        } else {
            radius
        }
    }
}

func limbSpine(chain: RigChain): LimbSpine {
    LimbSpine(chain.upper.joint, chain.lower.joint, chain.terminal.joint)
}

func drawLimbSkin(context: RigDrawContext, chain: RigChain, upper: LimbPartSpec, lower: LimbPartSpec): Unit {
    let spine = limbSpine(chain)
    drawSkinnedPart(context, spine, upper, lower, isLower: false)
    drawSkinnedPart(context, spine, upper, lower, isLower: true)
}

/*
 * 把上段或下段贴图铺到共享脊骨上。两段都需要对方的宽度参与同一宽度剖面,因此
 * 始终成对传入;isLower 选择本次绘制的段。靠膝一端延伸 overlap,纹理 v 均匀映射
 * 到该范围(轻微拉伸);上段整段不透明,下段在交叠带 [knee±overlap] 内 smoothstep 渐入。
 */
func drawSkinnedPart(
    context: RigDrawContext,
    spine: LimbSpine,
    upper: LimbPartSpec,
    lower: LimbPartSpec,
    isLower!: Bool
): Unit {
    let (upperSource, upperRow, upperScale) = upper
    let (lowerSource, lowerRow, lowerScale) = lower
    let upperHalf = upperSource.w * upperScale / 2.0
    let lowerHalf = lowerSource.w * lowerScale / 2.0
    let knee = spine.upperLength
    let overlap = LIMB_KNEE_OVERLAP

    let picked: (Rect, Float32, Float32) = if (isLower) {
        (lowerSource, lowerRow, lowerScale)
    } else {
        (upperSource, upperRow, upperScale)
    }
    let (source, jointRow, scale) = picked
    /* 该段自身近端关节的弧长:上段=髋/肩(0),下段=膝/肘。 */
    let anchorS: Float32 = if (isLower) {
        knee
    } else {
        0.0
    }
    /* 几何铺设范围:靠膝一端延伸 overlap,纹理 v 均匀映射到该范围(轻微拉伸)。 */
    let geoStart = if (isLower) {
        knee - overlap
    } else {
        anchorS - jointRow * scale
    }
    let geoEnd = if (isLower) {
        anchorS + (source.h - jointRow) * scale
    } else {
        knee + overlap
    }
    let span = geoEnd - geoStart
    let shake = shakeY(context.state)
    let uNear: Float32 = if (context.facing < 0.0) {
        source.right()
    } else {
        source.x
    }
    let uFar: Float32 = if (context.facing < 0.0) {
        source.x
    } else {
        source.right()
    }
    let points = ArrayList<Point>()
    let texPoints = ArrayList<Point>()
    let alphas = ArrayList<Float32>()
    for (i in 0..=LIMB_SKIN_SLICES) {
        let t = Float32(i) / Float32(LIMB_SKIN_SLICES)
        let s = geoStart + span * t
        let blend = limbBlendWeight(spine, s)
        let (x, y, dirX, dirY) = sampleLimbSpine(spine, s, blend)
        let halfWidth = lerp(upperHalf, lowerHalf, blend)
        /* 下段在膝/肘交叠带内 smoothstep 渐入盖住上段;上段整段不透明作底。 */
        let alpha: Float32 = if (isLower) {
            smoothStep((s - (knee - overlap)) / (2.0 * overlap))
        } else {
            1.0
        }
        let perpX = dirY
        let perpY = -dirX
        let v = source.y + source.h * t
        points.add(Point(worldX(context.state, x - perpX * halfWidth), y - perpY * halfWidth + shake))
        points.add(Point(worldX(context.state, x + perpX * halfWidth), y + perpY * halfWidth + shake))
        texPoints.add(Point(uNear, v))
        texPoints.add(Point(uFar, v))
        alphas.add(alpha)
        alphas.add(alpha)
    }
    context.renderer.texturedStrip(context.texture, points, texPoints, alphas: Some(alphas))
}

/* 弧长 s 处的混合权重:关节前后 blendRadius 内从上段(0)平滑过渡到下段(1)。 */
func limbBlendWeight(spine: LimbSpine, s: Float32): Float32 {
    smoothStep((s - spine.upperLength + spine.blendRadius) / (2.0 * spine.blendRadius))
}

/*
 * 在腰带绘制之后,沿大腿骨轴把大腿顶部一小段重绘在腰带上层,透明度从腰带下沿
 * 处(不透明)向上渐隐为 0。等效于让摆动的大腿以柔边探入固定腰带下方,把两块
 * 牛仔布之间随姿态倾斜的硬接缝混合掉。贴图沿骨轴自然映射,无拉伸。
 */
func drawHipBlend(context: RigDrawContext, chain: RigChain, thigh: LimbPartSpec): Unit {
    let spine = limbSpine(chain)
    let (source, jointRow, scale) = thigh
    let halfWidth = source.w * scale / 2.0
    let shake = shakeY(context.state)
    let uNear: Float32 = if (context.facing < 0.0) {
        source.right()
    } else {
        source.x
    }
    let uFar: Float32 = if (context.facing < 0.0) {
        source.x
    } else {
        source.right()
    }
    let points = ArrayList<Point>()
    let texPoints = ArrayList<Point>()
    let alphas = ArrayList<Float32>()
    for (i in 0..=LIMB_SKIN_SLICES) {
        let s = lerp(HIP_BLEND_TOP, HIP_BLEND_BOTTOM, Float32(i) / Float32(LIMB_SKIN_SLICES))
        let (x, y, dirX, dirY) = sampleLimbSpine(spine, s, 0.0)
        let perpX = dirY
        let perpY = -dirX
        /* 源图行随骨轴弧长线性推进,和主大腿条带一致,保证纹理接续。 */
        let v = source.y + jointRow + s / scale
        let alpha = smoothStep((s - HIP_BLEND_FADE_START) / (HIP_BLEND_FADE_FULL - HIP_BLEND_FADE_START))
        points.add(Point(worldX(context.state, x - perpX * halfWidth), y - perpY * halfWidth + shake))
        points.add(Point(worldX(context.state, x + perpX * halfWidth), y + perpY * halfWidth + shake))
        texPoints.add(Point(uNear, v))
        texPoints.add(Point(uFar, v))
        alphas.add(alpha)
        alphas.add(alpha)
    }
    context.renderer.texturedStrip(context.texture, points, texPoints, alphas: Some(alphas))
}

/* 线性混合蒙皮采样:返回弧长 s 处混合后的位置与单位切向。 */
func sampleLimbSpine(spine: LimbSpine, s: Float32, blend: Float32): (Float32, Float32, Float32, Float32) {
    let upperX = spine.rootX + spine.upperDirX * s
    let upperY = spine.rootY + spine.upperDirY * s
    let overshoot = s - spine.upperLength
    let lowerX = spine.midX + spine.lowerDirX * overshoot
    let lowerY = spine.midY + spine.lowerDirY * overshoot
    let (dirX, dirY) = normalized(
        lerp(spine.upperDirX, spine.lowerDirX, blend),
        lerp(spine.upperDirY, spine.lowerDirY, blend)
    )
    (lerp(upperX, lowerX, blend), lerp(upperY, lowerY, blend), dirX, dirY)
}
