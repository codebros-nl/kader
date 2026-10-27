import CoreGraphics
import Testing
@testable import kader

struct FrameHistoryTests {
    private let original = CGRect(x: 100, y: 100, width: 600, height: 400)
    private let leftHalf = CGRect(x: 0, y: 25, width: 720, height: 800)
    private let maximized = CGRect(x: 0, y: 25, width: 1440, height: 800)

    @Test func restoresFrameFromBeforeFirstAction() {
        var history = FrameHistory<Int>()
        history.willMove(1, from: original)
        history.didMove(1, to: leftHalf)
        history.willMove(1, from: leftHalf)
        history.didMove(1, to: maximized)

        #expect(history.takeRestoreFrame(for: 1) == original)
    }

    @Test func restoreClearsHistory() {
        var history = FrameHistory<Int>()
        history.willMove(1, from: original)
        history.didMove(1, to: leftHalf)

        _ = history.takeRestoreFrame(for: 1)
        #expect(history.takeRestoreFrame(for: 1) == nil)
    }

    @Test func manualMoveBecomesNewOriginal() {
        var history = FrameHistory<Int>()
        history.willMove(1, from: original)
        history.didMove(1, to: leftHalf)

        // Gebruiker sleept het venster zelf naar een andere plek en gebruikt Kader opnieuw.
        let dragged = CGRect(x: 300, y: 300, width: 720, height: 800)
        history.willMove(1, from: dragged)
        history.didMove(1, to: maximized)

        #expect(history.takeRestoreFrame(for: 1) == dragged)
    }

    @Test func windowsAreTrackedSeparately() {
        var history = FrameHistory<Int>()
        history.willMove(1, from: original)
        history.didMove(1, to: leftHalf)

        #expect(history.takeRestoreFrame(for: 2) == nil)
        #expect(history.takeRestoreFrame(for: 1) == original)
    }
}
