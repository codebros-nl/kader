import CoreGraphics

/// Pure logica: welke actie hoort bij de muispositie tijdens het slepen van een venster.
///
/// - Linker- en rechterrand: helften.
/// - Bovenrand: maximaliseren.
/// - Onderrand: derden, afhankelijk van de horizontale positie.
/// - Hoeken: kwarten.
///
/// Randen die aan een ander scherm grenzen tellen niet mee, anders zou elke overgang naar
/// een tweede monitor een snap opleveren. Alles in Accessibility-coördinaten.
nonisolated enum SnapArea {
    nonisolated struct Snap: Equatable, Sendable {
        var action: WindowAction
        var screen: ScreenGeometry.Screen
    }

    /// Afstand tot de rand waarbinnen de cursor als "tegen de rand" geldt.
    static let edgeThreshold: CGFloat = 5
    /// Lengte van de hoekzone langs elke rand.
    static let cornerSize: CGFloat = 40

    static func snap(at point: CGPoint, in screens: [ScreenGeometry.Screen]) -> Snap? {
        guard let screen = screens.first(where: { containsInclusive($0.frame, point) }) else {
            return nil
        }
        let frame = screen.frame
        let others = screens.filter { $0 != screen }.map(\.frame)

        // Een rand telt alleen als er aan de andere kant geen scherm ligt.
        let nearLeft = point.x <= frame.minX + edgeThreshold
            && !others.contains { containsInclusive($0, CGPoint(x: frame.minX - 1, y: point.y)) }
        let nearRight = point.x >= frame.maxX - edgeThreshold
            && !others.contains { containsInclusive($0, CGPoint(x: frame.maxX + 1, y: point.y)) }
        let nearTop = point.y <= frame.minY + edgeThreshold
            && !others.contains { containsInclusive($0, CGPoint(x: point.x, y: frame.minY - 1)) }
        let nearBottom = point.y >= frame.maxY - edgeThreshold
            && !others.contains { containsInclusive($0, CGPoint(x: point.x, y: frame.maxY + 1)) }

        let inLeftBand = point.x <= frame.minX + cornerSize
        let inRightBand = point.x >= frame.maxX - cornerSize
        let inTopBand = point.y <= frame.minY + cornerSize
        let inBottomBand = point.y >= frame.maxY - cornerSize

        let action: WindowAction
        if (nearLeft && inTopBand) || (nearTop && inLeftBand) {
            action = .topLeft
        } else if (nearRight && inTopBand) || (nearTop && inRightBand) {
            action = .topRight
        } else if (nearLeft && inBottomBand) || (nearBottom && inLeftBand) {
            action = .bottomLeft
        } else if (nearRight && inBottomBand) || (nearBottom && inRightBand) {
            action = .bottomRight
        } else if nearLeft {
            action = .leftHalf
        } else if nearRight {
            action = .rightHalf
        } else if nearTop {
            action = .maximize
        } else if nearBottom {
            let relativeX = (point.x - frame.minX) / frame.width
            action = relativeX < 1.0 / 3 ? .firstThird : relativeX < 2.0 / 3 ? .centerThird : .lastThird
        } else {
            return nil
        }
        return Snap(action: action, screen: screen)
    }

    /// Zoals `CGRect.contains`, maar inclusief de rechter- en onderrand:
    /// de cursor kan precies op `maxX` of `maxY` staan.
    private static func containsInclusive(_ rect: CGRect, _ point: CGPoint) -> Bool {
        point.x >= rect.minX && point.x <= rect.maxX && point.y >= rect.minY && point.y <= rect.maxY
    }
}
