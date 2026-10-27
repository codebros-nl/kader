import CoreGraphics
import Foundation
import Testing
@testable import kader

struct ZoneGridTests {
    private let area = CGRect(x: 0, y: 25, width: 1440, height: 800)

    @Test func parsesAndNormalizes() {
        #expect(ZoneGrid.parse("25, 50, 25") == [0.25, 0.5, 0.25])
        #expect(ZoneGrid.parse("1 1") == [0.5, 0.5])
        #expect(ZoneGrid.parse("60%;40%") == [0.6, 0.4])
        #expect(ZoneGrid.parse("100") == [1])
    }

    @Test(arguments: ["", "abc", "25, -5", "25, 0", "25,,x", String(repeating: "1,", count: 13)])
    func rejectsInvalidInput(text: String) {
        #expect(ZoneGrid.parse(text) == nil)
    }

    @Test func unitRectsAreRowByRow() throws {
        let grid = try #require(ZoneGrid(columns: "50, 50", rows: "50, 50"))
        #expect(grid.unitRects == [
            CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
            CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
            CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
            CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5),
        ])
    }

    @Test func framesFollowTheVisibleArea() throws {
        let grid = try #require(ZoneGrid(columns: "25, 50, 25", rows: "100"))
        #expect(grid.frames(in: area, gap: 0) == [
            CGRect(x: 0, y: 25, width: 360, height: 800),
            CGRect(x: 360, y: 25, width: 720, height: 800),
            CGRect(x: 1080, y: 25, width: 360, height: 800),
        ])
    }

    @Test func gapWorksLikeFixedActions() throws {
        let grid = try #require(ZoneGrid(columns: "50, 50", rows: "100"))
        let frames = grid.frames(in: area, gap: 10)
        // Zelfde frames als linker- en rechterhelft met dezelfde marge.
        #expect(frames[0] == ScreenGeometry.targetFrame(for: .leftHalf, currentFrame: .zero, visibleFrame: area, gap: 10))
        #expect(frames[1] == ScreenGeometry.targetFrame(for: .rightHalf, currentFrame: .zero, visibleFrame: area, gap: 10))
    }

    @Test func zoneUnderCursorHasNoDeadSpace() throws {
        let grid = try #require(ZoneGrid(columns: "25, 50, 25", rows: "100"))
        #expect(grid.zoneIndex(at: CGPoint(x: 100, y: 400), in: area) == 0)
        #expect(grid.zoneIndex(at: CGPoint(x: 720, y: 400), in: area) == 1)
        // Precies op de grens tussen twee zones: de eerste wint.
        #expect(grid.zoneIndex(at: CGPoint(x: 360, y: 400), in: area) == 0)
        #expect(grid.zoneIndex(at: CGPoint(x: 1439, y: 824), in: area) == 2)
        // In de menubalk, buiten het zichtbare gebied.
        #expect(grid.zoneIndex(at: CGPoint(x: 720, y: 10), in: area) == nil)
    }

    @Test func allPresetsAreValid() {
        for preset in ZoneGrid.presets {
            #expect(ZoneGrid(columns: preset.columns, rows: preset.rows) != nil, "Ongeldige preset \(preset.name)")
        }
    }

    @Test func currentFallsBackToDefaultPreset() throws {
        let defaults = try #require(UserDefaults(suiteName: "nl.codebros.kader.tests.\(UUID().uuidString)"))
        let fallback = ZoneGrid(columns: ZoneGrid.defaultPreset.columns, rows: ZoneGrid.defaultPreset.rows)
        #expect(ZoneGrid.current(defaults: defaults) == fallback)

        defaults.set("onzin", forKey: SettingsKey.zoneColumns)
        #expect(ZoneGrid.current(defaults: defaults) == fallback)

        defaults.set("50, 50", forKey: SettingsKey.zoneColumns)
        #expect(ZoneGrid.current(defaults: defaults).columns == [0.5, 0.5])
    }
}
