import CoreGraphics
import Testing
@testable import kader

struct SnapAreaTests {
    // Hoofdscherm, met rechts een hoger tweede scherm (zelfde opstelling als in ScreenGeometryTests).
    private let primary = ScreenGeometry.Screen(
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 800)
    )
    private let right = ScreenGeometry.Screen(
        frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1440, y: -180, width: 1920, height: 1055)
    )
    private var screens: [ScreenGeometry.Screen] { [primary, right] }

    @Test(arguments: [
        (CGPoint(x: 0, y: 450), WindowAction.leftHalf),
        (CGPoint(x: 720, y: 0), .maximize),
        (CGPoint(x: 0, y: 10), .topLeft),
        (CGPoint(x: 30, y: 0), .topLeft),
        (CGPoint(x: 0, y: 880), .bottomLeft),
        (CGPoint(x: 1420, y: 0), .topRight),
        (CGPoint(x: 100, y: 900), .firstThird),
        (CGPoint(x: 720, y: 900), .centerThird),
        (CGPoint(x: 1420, y: 900), .bottomRight),
        (CGPoint(x: 1100, y: 900), .lastThird),
    ])
    func edgesAndCornersOfPrimaryScreen(point: CGPoint, expected: WindowAction) {
        #expect(SnapArea.snap(at: point, in: screens) == SnapArea.Snap(action: expected, screen: primary))
    }

    @Test(arguments: [
        (CGPoint(x: 3360, y: 300), WindowAction.rightHalf),
        (CGPoint(x: 2400, y: -180), .maximize),
        (CGPoint(x: 3360, y: 900), .bottomRight),
        // Linkerrand van het tweede scherm boven het hoofdscherm grenst nergens aan.
        (CGPoint(x: 1440, y: -100), .leftHalf),
    ])
    func edgesOfSecondScreen(point: CGPoint, expected: WindowAction) {
        #expect(SnapArea.snap(at: point, in: screens) == SnapArea.Snap(action: expected, screen: right))
    }

    @Test(arguments: [
        // Midden van het scherm.
        CGPoint(x: 720, y: 450),
        // Grens tussen de schermen: de cursor gaat hier naar het andere scherm.
        CGPoint(x: 1440, y: 450),
        CGPoint(x: 1439, y: 450),
        // Buiten alle schermen.
        CGPoint(x: -50, y: 450),
    ])
    func noSnap(point: CGPoint) {
        #expect(SnapArea.snap(at: point, in: screens) == nil)
    }

    @Test func noScreensMeansNoSnap() {
        #expect(SnapArea.snap(at: CGPoint(x: 0, y: 0), in: []) == nil)
    }

    @Test func convertPointBetweenCoordinateSystems() {
        // Cursor bovenaan het hoofdscherm in Cocoa-coördinaten is y = 0 in Accessibility-coördinaten.
        #expect(ScreenGeometry.convert(CGPoint(x: 100, y: 900), primaryScreenHeight: 900) == CGPoint(x: 100, y: 0))
        #expect(ScreenGeometry.convert(CGPoint(x: 100, y: 0), primaryScreenHeight: 900) == CGPoint(x: 100, y: 900))
    }
}
