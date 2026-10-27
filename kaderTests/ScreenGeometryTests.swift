import CoreGraphics
import Testing
@testable import kader

struct ScreenGeometryTests {
    // Zichtbaar gebied zoals na conversie naar Accessibility-coördinaten:
    // 25 punten menubalk bovenaan, Dock onderaan.
    private let area = CGRect(x: 0, y: 25, width: 1440, height: 800)
    private let window = CGRect(x: 100, y: 100, width: 600, height: 400)

    // MARK: - Acties

    @Test(arguments: [
        (WindowAction.leftHalf, CGRect(x: 0, y: 25, width: 720, height: 800)),
        (.rightHalf, CGRect(x: 720, y: 25, width: 720, height: 800)),
        (.topHalf, CGRect(x: 0, y: 25, width: 1440, height: 400)),
        (.bottomHalf, CGRect(x: 0, y: 425, width: 1440, height: 400)),
        (.topLeft, CGRect(x: 0, y: 25, width: 720, height: 400)),
        (.topRight, CGRect(x: 720, y: 25, width: 720, height: 400)),
        (.bottomLeft, CGRect(x: 0, y: 425, width: 720, height: 400)),
        (.bottomRight, CGRect(x: 720, y: 425, width: 720, height: 400)),
        (.maximize, CGRect(x: 0, y: 25, width: 1440, height: 800)),
        (.center, CGRect(x: 420, y: 225, width: 600, height: 400)),
    ])
    func targetFrame(action: WindowAction, expected: CGRect) {
        #expect(ScreenGeometry.targetFrame(for: action, currentFrame: window, visibleFrame: area) == expected)
    }

    @Test(arguments: [
        (WindowAction.firstThird, CGRect(x: 0, y: 25, width: 480, height: 800)),
        (.centerThird, CGRect(x: 480, y: 25, width: 480, height: 800)),
        (.lastThird, CGRect(x: 960, y: 25, width: 480, height: 800)),
        (.firstTwoThirds, CGRect(x: 0, y: 25, width: 960, height: 800)),
        (.lastTwoThirds, CGRect(x: 480, y: 25, width: 960, height: 800)),
    ])
    func thirdsOnLandscapeScreen(action: WindowAction, expected: CGRect) {
        #expect(ScreenGeometry.targetFrame(for: action, currentFrame: window, visibleFrame: area) == expected)
    }

    @Test func thirdsOnPortraitScreenAreRows() {
        let portrait = CGRect(x: 0, y: 0, width: 1080, height: 1920)
        #expect(
            ScreenGeometry.targetFrame(for: .firstThird, currentFrame: window, visibleFrame: portrait)
                == CGRect(x: 0, y: 0, width: 1080, height: 640)
        )
        #expect(
            ScreenGeometry.targetFrame(for: .lastTwoThirds, currentFrame: window, visibleFrame: portrait)
                == CGRect(x: 0, y: 640, width: 1080, height: 1280)
        )
    }

    @Test(arguments: [
        (WindowAction.leftHalf, 1, CGRect(x: 0, y: 25, width: 480, height: 800)),
        (.leftHalf, 2, CGRect(x: 0, y: 25, width: 960, height: 800)),
        (.leftHalf, 3, CGRect(x: 0, y: 25, width: 720, height: 800)),
        (.rightHalf, 1, CGRect(x: 960, y: 25, width: 480, height: 800)),
        (.rightHalf, 2, CGRect(x: 480, y: 25, width: 960, height: 800)),
        // Een derde van 800 is geen heel getal: randen worden afgerond.
        (.topHalf, 1, CGRect(x: 0, y: 25, width: 1440, height: 267)),
        (.bottomHalf, 2, CGRect(x: 0, y: 292, width: 1440, height: 533)),
    ])
    func cycleSteps(action: WindowAction, step: Int, expected: CGRect) {
        #expect(
            ScreenGeometry.targetFrame(for: action, step: step, currentFrame: window, visibleFrame: area) == expected
        )
    }

    @Test(arguments: [
        (WindowAction.leftHalf, CGRect(x: 10, y: 35, width: 705, height: 780)),
        (.rightHalf, CGRect(x: 725, y: 35, width: 705, height: 780)),
        (.bottomRight, CGRect(x: 725, y: 430, width: 705, height: 385)),
        (.maximize, CGRect(x: 10, y: 35, width: 1420, height: 780)),
    ])
    func gapAppliesToScreenEdgesAndBetweenWindows(action: WindowAction, expected: CGRect) {
        #expect(
            ScreenGeometry.targetFrame(for: action, currentFrame: window, visibleFrame: area, gap: 10) == expected
        )
    }

    @Test(arguments: [WindowAction.nextScreen, .previousScreen, .restore])
    func actionsWithoutLayoutHaveNoTargetFrame(action: WindowAction) {
        #expect(ScreenGeometry.targetFrame(for: action, currentFrame: window, visibleFrame: area) == nil)
    }

    @Test func actionsOnOffsetScreen() {
        // Tweede scherm rechts van en hoger dan het hoofdscherm.
        let offsetArea = CGRect(x: 1440, y: -180, width: 1920, height: 1080)
        #expect(
            ScreenGeometry.targetFrame(for: .rightHalf, currentFrame: window, visibleFrame: offsetArea)
                == CGRect(x: 2400, y: -180, width: 960, height: 1080)
        )
        #expect(
            ScreenGeometry.targetFrame(for: .bottomLeft, currentFrame: window, visibleFrame: offsetArea)
                == CGRect(x: 1440, y: 360, width: 960, height: 540)
        )
    }

    @Test func centerShrinksWindowLargerThanScreen() {
        let huge = CGRect(x: 0, y: 0, width: 3000, height: 2000)
        #expect(ScreenGeometry.targetFrame(for: .center, currentFrame: huge, visibleFrame: area) == area)
    }

    // MARK: - Coördinatenconversie

    private let primaryHeight: CGFloat = 900

    @Test func convertPrimaryScreen() {
        // Volledig hoofdscherm valt precies op zichzelf.
        let primary = CGRect(x: 0, y: 0, width: 1440, height: 900)
        #expect(ScreenGeometry.convert(primary, primaryScreenHeight: primaryHeight) == primary)

        // visibleFrame met 25 punten menubalk en 75 punten Dock.
        let visible = CGRect(x: 0, y: 75, width: 1440, height: 800)
        #expect(
            ScreenGeometry.convert(visible, primaryScreenHeight: primaryHeight)
                == CGRect(x: 0, y: 25, width: 1440, height: 800)
        )
    }

    @Test(arguments: [
        // Rechts, onderkanten gelijk.
        (CGRect(x: 1440, y: 0, width: 1920, height: 1080), CGRect(x: 1440, y: -180, width: 1920, height: 1080)),
        // Links, onderkanten gelijk.
        (CGRect(x: -1920, y: 0, width: 1920, height: 1080), CGRect(x: -1920, y: -180, width: 1920, height: 1080)),
        // Boven het hoofdscherm.
        (CGRect(x: 0, y: 900, width: 1920, height: 1080), CGRect(x: 0, y: -1080, width: 1920, height: 1080)),
        // Onder het hoofdscherm.
        (CGRect(x: 0, y: -1080, width: 1920, height: 1080), CGRect(x: 0, y: 900, width: 1920, height: 1080)),
    ])
    func convertSecondaryScreen(cocoa: CGRect, accessibility: CGRect) {
        #expect(ScreenGeometry.convert(cocoa, primaryScreenHeight: primaryHeight) == accessibility)
        // Terugrekenen levert het origineel op.
        #expect(ScreenGeometry.convert(accessibility, primaryScreenHeight: primaryHeight) == cocoa)
    }

    @Test func accessibilityScreensUsesFirstScreenAsPrimary() {
        let cocoa = [
            ScreenGeometry.Screen(
                frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                visibleFrame: CGRect(x: 0, y: 75, width: 1440, height: 800)
            ),
            ScreenGeometry.Screen(
                frame: CGRect(x: 0, y: 900, width: 1920, height: 1080),
                visibleFrame: CGRect(x: 0, y: 900, width: 1920, height: 1055)
            ),
        ]
        let converted = ScreenGeometry.accessibilityScreens(fromCocoa: cocoa)
        #expect(converted == [
            ScreenGeometry.Screen(
                frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 800)
            ),
            ScreenGeometry.Screen(
                frame: CGRect(x: 0, y: -1080, width: 1920, height: 1080),
                visibleFrame: CGRect(x: 0, y: -1055, width: 1920, height: 1055)
            ),
        ])
        #expect(ScreenGeometry.accessibilityScreens(fromCocoa: []).isEmpty)
    }

    // MARK: - Schermkeuze

    private let screens = [
        ScreenGeometry.Screen(frame: CGRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: .zero),
        ScreenGeometry.Screen(frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080), visibleFrame: .zero),
    ]

    @Test func screenWithLargestOverlapWins() {
        // Venster over de grens, grootste deel op het tweede scherm.
        let straddling = CGRect(x: 1240, y: 100, width: 800, height: 400)
        #expect(ScreenGeometry.screen(for: straddling, in: screens) == screens[1])

        let mostlyPrimary = CGRect(x: 1000, y: 100, width: 800, height: 400)
        #expect(ScreenGeometry.screen(for: mostlyPrimary, in: screens) == screens[0])
    }

    @Test func offscreenWindowFallsBackToNearestScreen() {
        let offscreen = CGRect(x: 4000, y: 100, width: 400, height: 300)
        #expect(ScreenGeometry.screen(for: offscreen, in: screens) == screens[1])
        #expect(ScreenGeometry.screen(for: offscreen, in: []) == nil)
    }

    // MARK: - Volgend en vorig scherm

    @Test func nextAndPreviousScreenGoLeftToRightAndWrap() {
        let left = ScreenGeometry.Screen(frame: CGRect(x: -1920, y: -180, width: 1920, height: 1080), visibleFrame: .zero)
        // Bewust niet op volgorde: NSScreen.screens begint altijd met het hoofdscherm.
        let all = [screens[0], screens[1], left]

        #expect(ScreenGeometry.screen(offsetBy: 1, from: screens[0], in: all) == screens[1])
        #expect(ScreenGeometry.screen(offsetBy: 1, from: screens[1], in: all) == left)
        #expect(ScreenGeometry.screen(offsetBy: -1, from: screens[0], in: all) == left)
        #expect(ScreenGeometry.screen(offsetBy: -1, from: left, in: all) == screens[1])
        #expect(ScreenGeometry.screen(offsetBy: 1, from: screens[0], in: [screens[0]]) == nil)
    }

    @Test func movingToAnotherScreenKeepsRelativePositionAndSize() {
        let leftHalf = CGRect(x: 0, y: 25, width: 720, height: 800)
        let destination = CGRect(x: 1440, y: -180, width: 1920, height: 1080)
        #expect(
            ScreenGeometry.frame(leftHalf, movedFrom: area, to: destination)
                == CGRect(x: 1440, y: -180, width: 960, height: 1080)
        )
    }

    @Test func movingToAnotherScreenStaysInsideDestination() {
        let source = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let destination = CGRect(x: 0, y: 0, width: 500, height: 500)
        let overhanging = CGRect(x: 900, y: 900, width: 200, height: 200)
        #expect(
            ScreenGeometry.frame(overhanging, movedFrom: source, to: destination)
                == CGRect(x: 400, y: 400, width: 100, height: 100)
        )
    }
}
