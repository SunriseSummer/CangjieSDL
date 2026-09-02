package sdl

@Test
func automaticSupersampleTracksPhysicalDensityWhileExplicitFactorsStayFixed(): Unit {
    let automatic = Renderer(CPointer<Unit>(), contentScale: 1.0, supersample: 0)
    @Expect(automatic.supersampleFactor(), Int32(2))
    automatic.updateContentScale(1.99)
    @Expect(automatic.supersampleFactor(), Int32(2))
    let oldDensityCommands = automatic.recordCommands {
        automatic.fill(Rect(0.0, 0.0, 1.0, 1.0), Color.rgb(0, 0, 0))
    }
    automatic.updateContentScale(2.0)
    @Expect(automatic.supersampleFactor(), Int32(1))
    @Expect(!oldDensityCommands.replay(automatic))
    automatic.updateContentScale(1.5)
    @Expect(automatic.supersampleFactor(), Int32(2))

    let explicit = Renderer(CPointer<Unit>(), contentScale: 1.0, supersample: 2)
    explicit.updateContentScale(3.0)
    @Expect(explicit.supersampleFactor(), Int32(2))
    let legacyNegative = Renderer(CPointer<Unit>(), contentScale: 1.0, supersample: -1)
    @Expect(legacyNegative.supersampleFactor(), Int32(1))
}

@Test
func automaticSupersampleBudgetPreserves4kButCaps5kTargets(): Unit {
    let fourK = planSupersampleTarget(0, 1.0, 3840, 2160, 16384)
    @Expect(fourK.factor, Int32(2))
    @Expect(fourK.targetWidth, Int32(7680))
    @Expect(fourK.targetHeight, Int32(4320))
    @Expect(!fourK.automaticBudgetLimited)

    let fiveK = planSupersampleTarget(0, 1.0, 5120, 2880, 16384)
    @Expect(fiveK.factor, Int32(1))
    @Expect(fiveK.targetWidth, Int32(0))
    @Expect(fiveK.targetHeight, Int32(0))
    @Expect(fiveK.automaticBudgetLimited)

    let explicit = planSupersampleTarget(2, 1.0, 5120, 2880, 16384)
    @Expect(explicit.factor, Int32(2))
    @Expect(explicit.targetWidth, Int32(10240))
    @Expect(explicit.targetHeight, Int32(5760))
    @Expect(!explicit.automaticBudgetLimited)
}

@Test
func supersamplePlanningRejectsTextureOverflowBeforeNativeAllocation(): Unit {
    let dimensionLimit = planSupersampleTarget(2, 1.0, 9000, 4000, 16384)
    @Expect(dimensionLimit.factor, Int32(1))
    @Expect(dimensionLimit.textureSizeLimited)

    let arithmeticLimit = planSupersampleTarget(Int32.Max, 1.0, 2, 1, Int32.Max)
    @Expect(arithmeticLimit.factor, Int32(1))
    @Expect(arithmeticLimit.textureSizeLimited)

    let invalidOutput = planSupersampleTarget(2, 1.0, 0, 2160, 16384)
    @Expect(invalidOutput.factor, Int32(1))
    @Expect(invalidOutput.outputUnavailable)
}

@Test
func automaticSamplingTransitionsInvalidateCommandsAndExposeResourceCost(): Unit {
    let renderer = Renderer(CPointer<Unit>(), contentScale: 1.0, supersample: 0)
    let fourKCommands = renderer.recordCommands {
        renderer.fill(Rect(0.0, 0.0, 1.0, 1.0), Color.rgb(0, 0, 0))
    }

    renderer.updateOutputSampling(5120, 2880, maxTextureSizeOverride: 16384)
    @Expect(renderer.supersampleFactor(), Int32(1))
    @Expect(!fourKCommands.replay(renderer))
    let limited = renderer.renderSamplingStats()
    @Expect(limited.requestedFactor, Int32(0))
    @Expect(limited.targetWidth, Int32(0))
    @Expect(limited.estimatedTargetBytes, UInt64(0))
    match (limited.status) {
        case RenderSamplingStatus.AutomaticPixelBudget => ()
        case _ => @Fail("5K Auto should report its pixel-budget fallback")
    }

    let limitedCommands = renderer.recordCommands {
        renderer.fill(Rect(0.0, 0.0, 1.0, 1.0), Color.rgb(0, 0, 0))
    }
    renderer.updateOutputSampling(3840, 2160, maxTextureSizeOverride: 16384)
    @Expect(renderer.supersampleFactor(), Int32(2))
    @Expect(!limitedCommands.replay(renderer))
    let restored = renderer.renderSamplingStats()
    @Expect(restored.targetWidth, Int32(7680))
    @Expect(restored.targetHeight, Int32(4320))
    @Expect(restored.estimatedTargetBytes, UInt64(132710400))
    match (restored.status) {
        case RenderSamplingStatus.Supersampled => ()
        case _ => @Fail("4K Auto should retain its 2x target")
    }
}
