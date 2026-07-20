package sdl

import sdl.text.boldCompanionCandidates

// 真粗体伴生文件名推导的纯函数测试；候选是否真实存在由渲染层探测决定，这里只钉住拼写与顺序。

@Test
func boldCompanionWindowsStems(): Unit {
    // msyh.ttc 经 "bd" 后缀命中 msyhbd.ttc；segoeui.ttf 经 "b" 后缀命中 segoeuib.ttf。
    let msyh = boldCompanionCandidates("C:\\Windows\\Fonts\\msyh.ttc")
    @Expect(msyh.size, 3)
    @Expect(msyh[0], "C:\\Windows\\Fonts\\msyhbd.ttc")
    @Expect(msyh[1], "C:\\Windows\\Fonts\\msyhb.ttc")
    @Expect(msyh[2], "C:\\Windows\\Fonts\\msyh-Bold.ttc")

    let segoe = boldCompanionCandidates("C:\\Windows\\Fonts\\segoeui.ttf")
    @Expect(segoe[1], "C:\\Windows\\Fonts\\segoeuib.ttf")
}

@Test
func boldCompanionRegularSuffix(): Unit {
    // 「-Regular → -Bold」惯例优先（Noto、霞鹜文楷等下载字体族）。
    let wenkai = boldCompanionCandidates("fonts/LXGWWenKai-Regular.ttf")
    @Expect(wenkai.size, 4)
    @Expect(wenkai[0], "fonts/LXGWWenKai-Bold.ttf")

    // 无连字符的 Regular 同样替换。
    let plain = boldCompanionCandidates("fonts/SomeFontRegular.otf")
    @Expect(plain[0], "fonts/SomeFontBold.otf")
}

@Test
func boldCompanionUnknownExtension(): Unit {
    // 识别不了的扩展名没有可推导的伴生文件名，回落合成粗体。
    @Expect(boldCompanionCandidates("fonts/webfont.woff2").size, 0)
    @Expect(boldCompanionCandidates("no-extension").size, 0)
}
