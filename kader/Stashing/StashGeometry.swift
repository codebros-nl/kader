import CoreGraphics

/// Rand waartegen een venster wordt geparkeerd.
nonisolated enum StashEdge: Sendable {
    case left
    case right
}

/// Pure rekenlogica voor geparkeerde vensters. Alles in Accessibility-coördinaten.
nonisolated enum StashGeometry {
    /// Breedte van de strook die zichtbaar blijft van een geparkeerd venster.
    static let peekWidth: CGFloat = 12
    /// Afstand tot de rand waarbinnen de cursor een geparkeerd venster laat uitschuiven.
    static let revealThreshold: CGFloat = 2
    /// Marge rond een uitgeschoven venster voordat het weer terugschuift.
    static let hideMargin: CGFloat = 24

    /// Het buitenste scherm aan deze kant van de opstelling. Parkeren aan een binnenrand
    /// zou het venster op het naastgelegen scherm laten verschijnen.
    static func screen(for edge: StashEdge, in screens: [ScreenGeometry.Screen]) -> ScreenGeometry.Screen? {
        switch edge {
        case .left: screens.min { $0.frame.minX < $1.frame.minX }
        case .right: screens.max { $0.frame.maxX < $1.frame.maxX }
        }
    }

    /// Het venster tegen de rand van het scherm met alleen een smalle strook in beeld.
    static func stashedFrame(for windowFrame: CGRect, edge: StashEdge, on screen: ScreenGeometry.Screen) -> CGRect {
        let revealed = revealedFrame(for: windowFrame, edge: edge, on: screen)
        let x = switch edge {
        case .left: screen.frame.minX - revealed.width + peekWidth
        case .right: screen.frame.maxX - peekWidth
        }
        return CGRect(x: x, y: revealed.minY, width: revealed.width, height: revealed.height)
    }

    /// Het venster volledig in beeld tegen dezelfde rand, zoals bij uitschuiven.
    static func revealedFrame(for windowFrame: CGRect, edge: StashEdge, on screen: ScreenGeometry.Screen) -> CGRect {
        let area = screen.visibleFrame
        let width = min(windowFrame.width, area.width)
        let height = min(windowFrame.height, area.height)
        let x = switch edge {
        case .left: area.minX
        case .right: area.maxX - width
        }
        let y = min(max(windowFrame.minY, area.minY), area.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// Of de cursor tegen de rand staat, ter hoogte van het geparkeerde venster.
    static func shouldReveal(
        cursor: CGPoint,
        stashedFrame: CGRect,
        edge: StashEdge,
        on screen: ScreenGeometry.Screen
    ) -> Bool {
        guard cursor.y >= stashedFrame.minY, cursor.y <= stashedFrame.maxY else { return false }
        return switch edge {
        case .left: cursor.x <= screen.frame.minX + revealThreshold
        case .right: cursor.x >= screen.frame.maxX - revealThreshold
        }
    }

    /// Of de cursor ver genoeg van het uitgeschoven venster is om het weer te parkeren.
    static func shouldHide(cursor: CGPoint, revealedFrame: CGRect) -> Bool {
        let area = revealedFrame.insetBy(dx: -hideMargin, dy: -hideMargin)
        return !(cursor.x >= area.minX && cursor.x <= area.maxX && cursor.y >= area.minY && cursor.y <= area.maxY)
    }
}
