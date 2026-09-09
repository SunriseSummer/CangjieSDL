package sdl.text

@Test
func emojiCandidateCacheHandlesPlainTextSelectorsAndRotation(): Unit {
    let fallback = EmojiFallback()
    for (text in ["abc 中文", "", "123", "AV office"]) { @Expect(!fallback.needed(text)) }
    for (text in ["🎉", "👩🏽‍💻", "🇨🇳", "❤\u{FE0F}", "1\u{FE0F}⃣", "☀\u{FE0F}", "✈\u{FE0F}"]) { @Expect(fallback.needed(text)) }
    for (i in 0..600) { @Expect(fallback.needed("${i}🎉")); @Expect(!fallback.needed("plain ${i}")) }
    fallback.reset()
    @Expect(!fallback.needed("ordinary"))
    @Expect(fallback.needed("🎉"))
}
