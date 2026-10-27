import CoreGraphics
import Testing
@testable import kader

struct ActionCycleTests {
    private let frame = CGRect(x: 0, y: 25, width: 720, height: 800)
    private let otherFrame = CGRect(x: 0, y: 25, width: 480, height: 800)

    @Test func firstPressStartsAtStepZero() {
        let cycle = ActionCycle<Int>()
        #expect(cycle.step(for: .leftHalf, window: 1, currentFrame: frame) == 0)
    }

    @Test func repeatedPressCyclesAndWraps() {
        var cycle = ActionCycle<Int>()
        var current = frame
        var steps: [Int] = []

        for _ in 0..<4 {
            let step = cycle.step(for: .leftHalf, window: 1, currentFrame: current)
            steps.append(step)
            current = CGRect(x: 0, y: 25, width: CGFloat(100 + step), height: 800)
            cycle.record(.leftHalf, step: step, window: 1, resultingFrame: current)
        }

        #expect(steps == [0, 1, 2, 0])
    }

    @Test func otherActionResetsCycle() {
        var cycle = ActionCycle<Int>()
        cycle.record(.leftHalf, step: 1, window: 1, resultingFrame: frame)
        #expect(cycle.step(for: .rightHalf, window: 1, currentFrame: frame) == 0)
    }

    @Test func otherWindowResetsCycle() {
        var cycle = ActionCycle<Int>()
        cycle.record(.leftHalf, step: 1, window: 1, resultingFrame: frame)
        #expect(cycle.step(for: .leftHalf, window: 2, currentFrame: frame) == 0)
    }

    @Test func movedWindowResetsCycle() {
        var cycle = ActionCycle<Int>()
        cycle.record(.leftHalf, step: 1, window: 1, resultingFrame: frame)
        #expect(cycle.step(for: .leftHalf, window: 1, currentFrame: otherFrame) == 0)
    }

    @Test func actionsWithoutCycleStayAtZero() {
        var cycle = ActionCycle<Int>()
        cycle.record(.maximize, step: 0, window: 1, resultingFrame: frame)
        #expect(cycle.step(for: .maximize, window: 1, currentFrame: frame) == 0)
    }
}
