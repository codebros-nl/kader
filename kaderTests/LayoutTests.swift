import CoreGraphics
import Foundation
import Testing
@testable import kader

struct LayoutMatcherTests {
    private func placement(_ title: String, x: CGFloat) -> WindowPlacement {
        WindowPlacement(bundleIdentifier: "com.apple.Safari", title: title, frame: CGRect(x: x, y: 0, width: 100, height: 100))
    }

    @Test func matchesOnTitleFirst() {
        let placements = [placement("Mail", x: 0), placement("Agenda", x: 100)]
        let windows = [(window: 1, title: "Agenda"), (window: 2, title: "Mail")]

        let result = LayoutMatcher.match(placements, to: windows)
        #expect(result.map(\.window) == [2, 1])
        #expect(result.map(\.frame.minX) == [0, 100])
    }

    @Test func fallsBackToOrderForUnknownTitles() {
        let placements = [placement("Oud document", x: 0), placement("Mail", x: 100), placement("", x: 200)]
        let windows = [(window: 1, title: "Mail"), (window: 2, title: "Nieuw document"), (window: 3, title: "Iets anders")]

        let result = LayoutMatcher.match(placements, to: windows)
        #expect(result.map(\.window) == [2, 1, 3])
        #expect(result.map(\.frame.minX) == [0, 100, 200])
    }

    @Test func extraPlacementsAreSkipped() {
        let placements = [placement("A", x: 0), placement("B", x: 100), placement("C", x: 200)]
        let windows = [(window: 1, title: "B")]

        let result = LayoutMatcher.match(placements, to: windows)
        #expect(result.map(\.window) == [1])
        #expect(result.map(\.frame.minX) == [100])
    }

    @Test func extraWindowsAreLeftAlone() {
        let placements = [placement("A", x: 0)]
        let windows = [(window: 1, title: "X"), (window: 2, title: "Y")]

        #expect(LayoutMatcher.match(placements, to: windows).map(\.window) == [1])
    }

    @Test func duplicateTitlesUseEachWindowOnce() {
        let placements = [placement("Terminal", x: 0), placement("Terminal", x: 100)]
        let windows = [(window: 1, title: "Terminal"), (window: 2, title: "Terminal")]

        #expect(LayoutMatcher.match(placements, to: windows).map(\.window) == [1, 2])
    }
}

struct ScreenSetupTests {
    private let primary = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let right = CGRect(x: 1440, y: -180, width: 1920, height: 1080)

    @Test func orderOfScreensDoesNotMatter() {
        #expect(ScreenSetup(screenFrames: [right, primary]) == ScreenSetup(screenFrames: [primary, right]))
    }

    @Test func differentArrangementIsDifferentSetup() {
        let left = CGRect(x: -1920, y: -180, width: 1920, height: 1080)
        #expect(ScreenSetup(screenFrames: [primary, right]) != ScreenSetup(screenFrames: [primary, left]))
    }

    @Test func summaryListsScreensLeftToRight() {
        #expect(ScreenSetup(screenFrames: [right, primary]).summary == "1440×900 + 1920×1080")
    }
}

@MainActor
struct LayoutStoreTests {
    private let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "kader-tests-\(UUID().uuidString)")
        .appending(path: "layouts.json")
    private let setup = ScreenSetup(screenFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)])
    private let otherSetup = ScreenSetup(screenFrames: [CGRect(x: 0, y: 0, width: 1920, height: 1080)])

    private func layout(_ name: String, setup: ScreenSetup) -> Layout {
        Layout(
            name: name,
            screenSetup: setup,
            windows: [WindowPlacement(bundleIdentifier: "com.apple.Safari", title: "Mail", frame: CGRect(x: 0, y: 25, width: 720, height: 800))]
        )
    }

    @Test func persistsAcrossInstances() {
        let original = layout("Werk", setup: setup)
        LayoutStore(fileURL: fileURL).add(original)

        #expect(LayoutStore(fileURL: fileURL).layouts == [original])
    }

    @Test func renameAndRemove() {
        let store = LayoutStore(fileURL: fileURL)
        let original = layout("Werk", setup: setup)
        store.add(original)

        store.rename(original.id, to: "Thuis")
        #expect(LayoutStore(fileURL: fileURL).layouts.map(\.name) == ["Thuis"])

        store.remove(original.id)
        #expect(LayoutStore(fileURL: fileURL).layouts.isEmpty)
    }

    @Test func onlyOneAutomaticLayoutPerSetup() {
        let store = LayoutStore(fileURL: fileURL)
        let first = layout("Eerste", setup: setup)
        let second = layout("Tweede", setup: setup)
        let elsewhere = layout("Elders", setup: otherSetup)
        store.add(first)
        store.add(second)
        store.add(elsewhere)

        store.setAppliesAutomatically(true, for: first.id)
        store.setAppliesAutomatically(true, for: elsewhere.id)
        store.setAppliesAutomatically(true, for: second.id)

        #expect(store.automaticLayout(for: setup)?.id == second.id)
        #expect(store.automaticLayout(for: otherSetup)?.id == elsewhere.id)
        #expect(store.layouts.filter(\.appliesAutomatically).count == 2)
    }

    @Test func missingFileStartsEmpty() {
        #expect(LayoutStore(fileURL: fileURL).layouts.isEmpty)
    }
}
