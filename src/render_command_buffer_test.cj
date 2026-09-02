package sdl

import std.collection.ArrayList

@Test
func renderCommandBufferRecordsWithoutDrawingAndReplaysInOrder(): Unit {
    let renderer = Renderer.headless()
    renderer.resetTextMeasureCount()

    let buffer = renderer.recordCommands {
        renderer.pushClip(Rect(0.0, 0.0, 80.0, 60.0))
        renderer.fill(Rect(2.0, 3.0, 20.0, 10.0), Color.rgb(10, 20, 30))
        renderer.text("recorded", 4.0, 5.0, Color.rgb(40, 50, 60))
        renderer.popClip()
    }

    let recorded = buffer.stats()
    @Expect(recorded.commandCount, 4)
    @Expect(recorded.clipCommandCount, 2)
    @Expect(recorded.resourceCount, 0)
    @Expect(recorded.estimatedBytes > UInt64(0))
    @Expect(recorded.replayCount, UInt64(0))
    @Expect(recorded.batchSubmissionCount, UInt64(0))
    @Expect(recorded.batchedCommandCount, UInt64(0))
    @Expect(renderer.textDrawCount(), UInt64(0))

    @Expect(buffer.replay(renderer))
    @Expect(renderer.textDrawCount(), UInt64(1))
    @Expect(buffer.stats().replayCount, UInt64(1))
}

@Test
func commandReplayBatchesOnlyContiguousSameColorPrimitives(): Unit {
    let renderer = Renderer.headless()
    let red = Color.rgb(200, 20, 20)
    let blue = Color.rgb(20, 20, 200)
    let buffer = renderer.recordCommands {
        for (index in 0..5) {
            renderer.fill(Rect(Float32(index), 0.0, 1.0, 1.0), red)
        }
        // A colour change is a hard batch boundary and remains an individual draw.
        renderer.fill(Rect(10.0, 0.0, 1.0, 1.0), blue)
        for (index in 0..4) {
            renderer.point(Float32(index), 2.0, red)
        }
    }
    @Expect(buffer.stats().compiledBatchCount, 2)
    @Expect(buffer.replay(renderer))
    let stats = buffer.stats()
    @Expect(stats.batchSubmissionCount, UInt64(2))
    @Expect(stats.batchedCommandCount, UInt64(9))
    @Expect(stats.commandCount, 10)
}

@Test
func renderCommandBoundsAreClippedAndConservative(): Unit {
    let renderer = Renderer.headless()
    let buffer = renderer.recordCommands {
        renderer.pushClip(Rect(0.0, 0.0, 50.0, 50.0))
        renderer.fill(Rect(10.0, 10.0, 10.0, 10.0), Color.rgb(10, 20, 30))
        renderer.fill(Rect(45.0, 45.0, 20.0, 20.0), Color.rgb(30, 20, 10))
        renderer.popClip()
    }

    match (buffer.paintBounds()) {
        case Some(bounds) => expectRect(bounds, 10.0, 10.0, 40.0, 40.0)
        case None => @Fail("painted commands should expose bounds")
    }
}

@Test
func nativeCommandReplayAcceptsPrimitiveBatches(): Unit {
    let window = SdlWindow(WindowSpec("Primitive batch test", 160, 120))
    try {
        let renderer = window.renderer
        let buffer = renderer.recordCommands {
            for (index in 0..32) {
                renderer.fill(Rect(Float32(index % 8) * 10.0, Float32(index / 8) * 10.0, 8.0, 8.0),
                    Color.rgb(40, 120, 220))
            }
        }
        renderer.beginScene(160.0, 120.0, Color.rgb(255, 255, 255))
        @Expect(buffer.replay(renderer))
        renderer.endScene()
        @Expect(buffer.stats().batchSubmissionCount, UInt64(1))
        @Expect(buffer.stats().batchedCommandCount, UInt64(32))
    } finally {
        window.close()
    }
}

@Test
func renderCommandReplayAdaptsToAndRestoresCallerClip(): Unit {
    let renderer = Renderer.headless()
    renderer.pushClip(Rect(0.0, 0.0, 100.0, 100.0))
    let buffer = renderer.recordCommands {
        renderer.pushClip(Rect(20.0, 10.0, 100.0, 50.0))
        expectRect(renderer.currentClip().getOrThrow(), 20.0, 10.0, 80.0, 50.0)
        renderer.fill(Rect(20.0, 10.0, 10.0, 10.0), Color.rgb(1, 2, 3))
        renderer.popClip()
    }
    expectRect(renderer.currentClip().getOrThrow(), 0.0, 0.0, 100.0, 100.0)

    renderer.popClip()
    renderer.pushClip(Rect(30.0, 20.0, 25.0, 25.0))
    @Expect(buffer.replay(renderer))
    expectRect(renderer.currentClip().getOrThrow(), 30.0, 20.0, 25.0, 25.0)
}

@Test
func renderCommandRecordingRejectsUnbalancedClipAndFrameControl(): Unit {
    let renderer = Renderer.headless()
    expectRecordingFailure({=> let _ = renderer.recordCommands {renderer.popClip()}})
    expectRecordingFailure({=> let _ = renderer.recordCommands {renderer.pushClip(Rect.zero())}})
    expectRecordingFailure({=> let _ = renderer.recordCommands {
        renderer.beginScene(10.0, 10.0, Color.rgb(0, 0, 0))
    }})

    // Every failure clears the active recorder; a fresh balanced recording still succeeds.
    let recovered = renderer.recordCommands {renderer.fill(Rect.zero(), Color.rgb(0, 0, 0))}
    @Expect(recovered.stats().commandCount, 1)
}

@Test
func nestedRenderCommandBufferReplaysIntoParentRecording(): Unit {
    let renderer = Renderer.headless()
    let outer = renderer.recordCommands {
        let inner = renderer.recordCommands {
            renderer.fill(Rect(1.0, 2.0, 3.0, 4.0), Color.rgb(5, 6, 7))
        }
        @Expect(inner.stats().commandCount, 1)
        @Expect(inner.replay(renderer))
    }
    @Expect(outer.stats().commandCount, 1)
    @Expect(outer.replay(renderer))
}

@Test
func renderCommandSlotReplacesChildWithoutFlatteningParent(): Unit {
    let renderer = Renderer.headless()
    let slot = RenderCommandSlot()
    let first = renderer.recordCommands {
        renderer.text("first", 1.0, 2.0, Color.rgb(1, 2, 3))
    }
    slot.replace(first)
    let parent = renderer.recordCommands {
        @Expect(slot.replay(renderer))
    }
    @Expect(parent.stats().commandCount, 1)
    @Expect(parent.hasSceneReferences())
    @Expect(!first.hasSceneReferences())

    let second = renderer.recordCommands {
        renderer.text("second-a", 20.0, 30.0, Color.rgb(4, 5, 6))
        renderer.text("second-b", 40.0, 50.0, Color.rgb(7, 8, 9))
    }
    slot.replace(second)
    @Expect(parent.replay(renderer))
    @Expect(renderer.textDrawCount(), UInt64(2))
    match (parent.paintBounds()) {
        case Some(bounds) => @Expect(bounds.x >= 20.0)
        case None => @Fail("parent slot bounds should resolve through the replacement")
    }
}

@Test
func clearedRenderCommandSlotInvalidatesParentBeforeDrawing(): Unit {
    let renderer = Renderer.headless()
    let slot = RenderCommandSlot()
    slot.replace(renderer.recordCommands {
        renderer.text("child", 0.0, 0.0, Color.rgb(1, 2, 3))
    })
    let parent = renderer.recordCommands {
        @Expect(slot.replay(renderer))
    }

    slot.clear()
    @Expect(!parent.replay(renderer))
    @Expect(renderer.textDrawCount(), UInt64(0))
}

@Test
func renderCommandSlotRejectsTransitiveCycle(): Unit {
    let renderer = Renderer.headless()
    let first = RenderCommandSlot()
    let second = RenderCommandSlot()
    second.replace(renderer.recordCommands {
        renderer.fill(Rect(0.0, 0.0, 1.0, 1.0), Color.rgb(1, 2, 3))
    })
    first.replace(renderer.recordCommands {
        @Expect(second.replay(renderer))
    })
    let cycle = renderer.recordCommands {
        @Expect(first.replay(renderer))
    }

    var rejected = false
    try {
        second.replace(cycle)
    } catch (_: IllegalArgumentException) {
        rejected = true
    }
    @Expect(rejected)
}

@Test
func renderCommandSlotRejectsWrongThreadAndRendererWithoutMutation(): Unit {
    let renderer = Renderer.headless()
    let slot = RenderCommandSlot()
    slot.replace(renderer.recordCommands {
        renderer.fill(Rect.zero(), Color.rgb(1, 2, 3))
    })
    let worker = spawn {
        => var rejected = false
        try {
            slot.clear()
        } catch (_: IllegalStateException) {
            rejected = true
        }
        rejected
    }
    @Expect(worker.get())
    @Expect(slot.hasCommands())

    let other = Renderer.headless()
    var wrongRendererRejected = false
    try {
        slot.replace(other.recordCommands {
            other.fill(Rect.zero(), Color.rgb(4, 5, 6))
        })
    } catch (_: IllegalArgumentException) {
        wrongRendererRejected = true
    }
    @Expect(wrongRendererRejected)
    @Expect(slot.isReplayable(renderer))
}

@Test
func renderCommandGraphRejectsEveryPublicOperationFromAnotherThread(): Unit {
    let renderer = Renderer.headless()
    let leaf = renderer.recordCommands {
        renderer.fill(Rect(0.0, 0.0, 8.0, 8.0), Color.rgb(1, 2, 3))
    }
    let slot = RenderCommandSlot()
    let stableBounds = Rect(0.0, 0.0, 8.0, 8.0)
    slot.setReplayBounds(stableBounds)
    slot.replace(leaf)
    let parent = renderer.recordCommands {
        @Expect(slot.replay(renderer))
    }
    let revision = slot.contentRevision()
    let damage = Rect(0.0, 0.0, 4.0, 4.0)

    let worker = spawn {
        => var rejected: Int64 = 0
        if (rejectsWrongThread({=> let _ = parent.stats()})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = parent.hasSceneReferences()})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = parent.paintBounds()})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = parent.isReplayable(renderer)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = parent.isReplayableIntersecting(renderer, damage)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = parent.replay(renderer)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = parent.replayIntersecting(renderer, damage)})) { rejected += 1 }
        if (rejectsWrongThread({=> slot.replace(leaf)})) { rejected += 1 }
        if (rejectsWrongThread({=> slot.clear()})) { rejected += 1 }
        if (rejectsWrongThread({=> slot.setReplayBounds(stableBounds)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = slot.isReplayable(renderer)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = slot.isReplayableIntersecting(renderer, damage)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = slot.replay(renderer)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = slot.replayIntersecting(renderer, damage)})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = slot.paintBounds()})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = slot.contentRevision()})) { rejected += 1 }
        if (rejectsWrongThread({=> let _ = slot.hasCommands()})) { rejected += 1 }
        rejected
    }

    @Expect(worker.get(), Int64(17))
    @Expect(slot.contentRevision(), revision)
    @Expect(parent.stats().replayCount, UInt64(0))
}

@Test
func hierarchicalCommandReplayCullsSlotsUsingCurrentReplacementBounds(): Unit {
    let renderer = Renderer.headless()
    let left = RenderCommandSlot()
    let right = RenderCommandSlot()
    left.replace(renderer.recordCommands {
        renderer.text("left", 0.0, 0.0, Color.rgb(1, 2, 3))
    })
    right.replace(renderer.recordCommands {
        renderer.text("right", 100.0, 0.0, Color.rgb(4, 5, 6))
    })
    let parent = renderer.recordCommands {
        @Expect(left.replay(renderer))
        @Expect(right.replay(renderer))
    }

    @Expect(parent.replayIntersecting(renderer, Rect(0.0, 0.0, 40.0, 40.0)))
    @Expect(renderer.textDrawCount(), UInt64(1))

    right.replace(renderer.recordCommands {
        renderer.text("right moved", 10.0, 0.0, Color.rgb(7, 8, 9))
    })
    @Expect(parent.replayIntersecting(renderer, Rect(0.0, 0.0, 40.0, 40.0)))
    @Expect(renderer.textDrawCount(), UInt64(3))
}

@Test
func indexedSlotRunCullsInOrderAndRejectsStaleBoundMutation(): Unit {
    let renderer = Renderer.headless()
    let slots = Array<RenderCommandSlot>(
        8,
        {
            index =>
                let x = Float32(index * 100)
                let slot = RenderCommandSlot()
                slot.setReplayBounds(Rect(x, 0.0, 40.0, 40.0))
                slot.replace(renderer.recordCommands {
                    renderer.text("child ${index}", x, 0.0, Color.rgb(index, index, index))
                })
                slot
        }
    )
    let parent = renderer.recordCommands {
        for (slot in slots) {
            @Expect(slot.replay(renderer))
        }
    }

    @Expect(parent.replayIntersecting(renderer, Rect(700.0, 0.0, 40.0, 40.0)))
    @Expect(renderer.textDrawCount(), UInt64(1))

    // Repeating the exact contract is harmless, but changing it would stale the parent's BVH.
    slots[7].setReplayBounds(Rect(700.0, 0.0, 40.0, 40.0))
    var rejected = false
    try {
        slots[7].setReplayBounds(Rect(0.0, 0.0, 40.0, 40.0))
    } catch (_: IllegalStateException) {
        rejected = true
    }
    @Expect(rejected)
    @Expect(parent.replayIntersecting(renderer, Rect(700.0, 0.0, 40.0, 40.0)))
    @Expect(renderer.textDrawCount(), UInt64(2))

    // Damage replay validates only the intersecting frontier; full replay still rejects the graph.
    slots[0].clear()
    @Expect(parent.replayIntersecting(renderer, Rect(700.0, 0.0, 40.0, 40.0)))
    @Expect(renderer.textDrawCount(), UInt64(3))
    @Expect(!parent.replay(renderer))
    @Expect(renderer.textDrawCount(), UInt64(3))
}

@Test
func renderCommandBufferRejectsOtherRendererAndChangedEpochBeforeDrawing(): Unit {
    let renderer = Renderer.headless()
    let other = Renderer.headless()
    let buffer = renderer.recordCommands {
        renderer.text("epoch", 0.0, 0.0, Color.rgb(0, 0, 0))
    }

    @Expect(!buffer.replay(other))
    @Expect(other.textDrawCount(), UInt64(0))
    renderer.setScale(2.0)
    @Expect(!buffer.replay(renderer))
    @Expect(renderer.textDrawCount(), UInt64(0))

    let refreshed = renderer.recordCommands {
        renderer.text("epoch", 0.0, 0.0, Color.rgb(0, 0, 0))
    }
    @Expect(refreshed.replay(renderer))
    @Expect(renderer.textDrawCount(), UInt64(1))
}

@Test
func renderCommandBufferCopiesMutableGeometryPayloads(): Unit {
    let renderer = Renderer.headless()
    let points = ArrayList<Point>()
    points.add(Point(0.0, 0.0))
    points.add(Point(10.0, 0.0))
    points.add(Point(0.0, 10.0))
    let buffer = renderer.recordCommands {
        renderer.fillConvexPolygon(points, Color.rgb(20, 30, 40))
    }
    let bytes = buffer.stats().estimatedBytes

    points.add(Point(1000.0, 1000.0))
    @Expect(buffer.stats().estimatedBytes, bytes)
    @Expect(buffer.replay(renderer))
}

@Test
func renderCommandRecordingRejectsTextureOwnedByAnotherRenderer(): Unit {
    let first = SdlWindow(WindowSpec("Command owner first", 120, 80, supersample: 1))
    let second = SdlWindow(WindowSpec("Command owner second", 120, 80, supersample: 1))
    try {
        try (surface = Surface.create(2, 2)) {
            try (texture = second.renderer.textureFromSurface(surface)) {
                var rejected = false
                try {
                    let _ = first.renderer.recordCommands {
                        first.renderer.texture(texture, Rect(0.0, 0.0, 2.0, 2.0))
                    }
                } catch (_: IllegalStateException) {
                    rejected = true
                }
                @Expect(rejected)
            }
        }
    } finally {
        first.close()
        second.close()
    }
}

private func expectRecordingFailure(action: () -> Unit): Unit {
    var failed = false
    try {
        action()
    } catch (_: IllegalStateException) {
        failed = true
    }
    @Expect(failed)
}

func rejectsWrongThread(action: () -> Unit): Bool {
    try {
        action()
        false
    } catch (_: IllegalStateException) {
        true
    }
}

private func expectRect(rect: Rect, x: Float32, y: Float32, width: Float32, height: Float32): Unit {
    @Expect(rect.x, x)
    @Expect(rect.y, y)
    @Expect(rect.w, width)
    @Expect(rect.h, height)
}
