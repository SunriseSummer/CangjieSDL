package contra.render

import sdl.Renderer
import sdl.Texture
import sdl.TextureBlendMode

/*
 * contra.render —— 场景渲染层(纯读 GameState,不改逻辑)。
 *
 * 资源随渲染层走:GameAssets 在这里加载与释放,渲染各文件直接读它的纹理。
 * 采用 `Resource` 确定性生命周期,游戏重开也不会重复占用 GPU 资源。
 */
protected class GameAssets <: Resource {
    let background: Texture
    let commandoParts: Texture
    let commandoHands: Texture
    let rifle: Texture
    let enemyGrunt: Texture
    private var closed = false

    protected init(renderer: Renderer) {
        background = renderer.loadTexture("assets/jungle_backdrop.png")
        commandoParts = renderer.loadTexture("assets/commando_parts_v2.png")
        commandoHands = renderer.loadTexture("assets/commando_hands.png")
        rifle = renderer.loadTexture("assets/rifle.png")
        enemyGrunt = renderer.loadTexture("assets/enemy_grunt.png")
        commandoParts.setBlendMode(TextureBlendMode.Blend)
        commandoHands.setBlendMode(TextureBlendMode.Blend)
        rifle.setBlendMode(TextureBlendMode.Blend)
        enemyGrunt.setBlendMode(TextureBlendMode.Blend)
    }

    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        enemyGrunt.close()
        rifle.close()
        commandoHands.close()
        commandoParts.close()
        background.close()
    }

    public func isClosed(): Bool {
        closed
    }
}
