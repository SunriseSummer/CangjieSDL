package sdl

@Test
func headlessDamageAcceptsValidRegionAndRejectsEmptyOrOutsideRegion(): Unit {
    let renderer = Renderer.headless()
    let clear = Color.rgb(10, 20, 30)

    @Expect(renderer.beginSceneDamage(100.0, 80.0, clear, Rect(4.0, 5.0, 20.0, 16.0)))
    @Expect(!renderer.beginSceneDamage(100.0, 80.0, clear, Rect.zero()))
    @Expect(!renderer.beginSceneDamage(100.0, 80.0, clear, Rect(200.0, 200.0, 10.0, 10.0)))
}
