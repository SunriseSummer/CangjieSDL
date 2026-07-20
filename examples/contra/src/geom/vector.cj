package contra.geom

import std.math.sqrt
import sdl.Rect

/* 归一化 (x, y);零向量退化为 (1, 0) 以免除零。 */
protected func normalized(x: Float32, y: Float32): (Float32, Float32) {
    let length = Float32(sqrt(Float64(x * x + y * y)))
    if (length < 0.001) {
        return (1.0, 0.0)
    }
    (x / length, y / length)
}

/* 两个关节点之间的欧氏距离。 */
protected func pointDistance(a: RigPoint, b: RigPoint): Float32 {
    let dx = b.x - a.x
    let dy = b.y - a.y
    Float32(sqrt(Float64(dx * dx + dy * dy)))
}

/* 轴对齐包围盒相交测试(边界相接不算相交)。 */
protected func intersects(a: Rect, b: Rect): Bool {
    a.x < b.right() && a.right() > b.x && a.y < b.bottom() && a.bottom() > b.y
}

/* 以中心为基准把矩形四周各外扩 (dx, dy),常用于绘制外发光。 */
protected func grown(rect: Rect, dx: Float32, dy: Float32): Rect {
    Rect(rect.x - dx, rect.y - dy, rect.w + dx * 2.0, rect.h + dy * 2.0)
}
