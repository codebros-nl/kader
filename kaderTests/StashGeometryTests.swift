import CoreGraphics
import Testing
@testable import kader

struct StashGeometryTests {
    // Hoofdscherm met links nog een scherm (zelfde schaal als de andere geometrietests).
    private let primary = ScreenGeometry.Screen(
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 800)
    )
    private let left = ScreenGeometry.Screen(
        frame: CGRect(x: -1920, y: -180, width: 1920, height: 1080),
        visibleFrame: CGRect(x: -1920, y: -180, width: 1920, height: 1080)
    )
    private let window = CGRect(x: 300, y: 200, width: 600, height: 400)

    @Test func usesOutermostScreenForEachEdge() {
        #expect(StashGeometry.screen(for: .left, in: [primary, left]) == left)
        #expect(StashGeometry.screen(for: .right, in: [primary, left]) == primary)
        #expect(StashGeometry.screen(for: .left, in: []) == nil)
    }

    @Test func stashedFrameLeavesOnlyAStripVisible() {
        let leftStash = StashGeometry.stashedFrame(for: window, edge: .left, on: primary)
        #expect(leftStash == CGRect(x: -588, y: 200, width: 600, height: 400))
        #expect(leftStash.maxX - primary.frame.minX == StashGeometry.peekWidth)

        let rightStash = StashGeometry.stashedFrame(for: window, edge: .right, on: primary)
        #expect(rightStash == CGRect(x: 1428, y: 200, width: 600, height: 400))
        #expect(primary.frame.maxX - rightStash.minX == StashGeometry.peekWidth)
    }

    @Test func revealedFrameIsFullyVisibleAgainstTheEdge() {
        #expect(
            StashGeometry.revealedFrame(for: window, edge: .left, on: primary)
                == CGRect(x: 0, y: 200, width: 600, height: 400)
        )
        #expect(
            StashGeometry.revealedFrame(for: window, edge: .right, on: primary)
                == CGRect(x: 840, y: 200, width: 600, height: 400)
        )
    }

    @Test func windowIsKeptInsideVisibleArea() {
        // Te hoog en te groot venster wordt ingekort en binnen menubalk en Dock gehouden.
        let tall = CGRect(x: 0, y: 700, width: 2000, height: 1000)
        #expect(
            StashGeometry.revealedFrame(for: tall, edge: .left, on: primary)
                == CGRect(x: 0, y: 25, width: 1440, height: 800)
        )

        let low = CGRect(x: 0, y: 700, width: 600, height: 400)
        #expect(StashGeometry.revealedFrame(for: low, edge: .right, on: primary).minY == 425)
    }

    @Test func revealOnlyAtTheEdgeNextToTheWindow() {
        let stashed = StashGeometry.stashedFrame(for: window, edge: .left, on: primary)

        #expect(StashGeometry.shouldReveal(cursor: CGPoint(x: 0, y: 300), stashedFrame: stashed, edge: .left, on: primary))
        // Te ver van de rand.
        #expect(!StashGeometry.shouldReveal(cursor: CGPoint(x: 20, y: 300), stashedFrame: stashed, edge: .left, on: primary))
        // Wel tegen de rand, maar onder het venster.
        #expect(!StashGeometry.shouldReveal(cursor: CGPoint(x: 0, y: 700), stashedFrame: stashed, edge: .left, on: primary))

        let rightStashed = StashGeometry.stashedFrame(for: window, edge: .right, on: primary)
        #expect(StashGeometry.shouldReveal(cursor: CGPoint(x: 1440, y: 300), stashedFrame: rightStashed, edge: .right, on: primary))
    }

    @Test func hideOnlyWhenCursorLeavesWindowWithMargin() {
        let revealed = CGRect(x: 0, y: 200, width: 600, height: 400)

        #expect(!StashGeometry.shouldHide(cursor: CGPoint(x: 300, y: 300), revealedFrame: revealed))
        #expect(!StashGeometry.shouldHide(cursor: CGPoint(x: 610, y: 300), revealedFrame: revealed))
        #expect(StashGeometry.shouldHide(cursor: CGPoint(x: 700, y: 300), revealedFrame: revealed))
        #expect(StashGeometry.shouldHide(cursor: CGPoint(x: 300, y: 650), revealedFrame: revealed))
    }
}
