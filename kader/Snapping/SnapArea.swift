import CoreGraphics

/// Pure logica: welke actie hoort bij de muispositie tijdens het slepen van een venster.
///
/// Eerst wordt de plek bepaald (rand of hoek), daarna via het ingestelde `SnapBehavior` de actie.
/// Standaard: helften links en rechts, maximaliseren boven, derden onder en kwarten in de hoeken.
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

    /// - Parameter behavior: Gedrag per plek; standaard de ingebouwde indeling.
    static func snap(
        at point: CGPoint,
        in screens: [ScreenGeometry.Screen],
        behavior: (SnapPosition) -> SnapBehavior = \.defaultBehavior
    ) -> Snap? {
        guard let screen = ScreenGeometry.screen(containing: point, in: screens) else {
            return nil
        }
        let frame = screen.frame
        let others = screens.filter { $0 != screen }.map(\.frame)

        // Een rand telt alleen als er aan de andere kant geen scherm ligt.
        let nearLeft = point.x <= frame.minX + edgeThreshold
            && !others.contains { ScreenGeometry.containsInclusive($0, CGPoint(x: frame.minX - 1, y: point.y)) }
        let nearRight = point.x >= frame.maxX - edgeThreshold
            && !others.contains { ScreenGeometry.containsInclusive($0, CGPoint(x: frame.maxX + 1, y: point.y)) }
        let nearTop = point.y <= frame.minY + edgeThreshold
            && !others.contains { ScreenGeometry.containsInclusive($0, CGPoint(x: point.x, y: frame.minY - 1)) }
        let nearBottom = point.y >= frame.maxY - edgeThreshold
            && !others.contains { ScreenGeometry.containsInclusive($0, CGPoint(x: point.x, y: frame.maxY + 1)) }

        let inLeftBand = point.x <= frame.minX + cornerSize
        let inRightBand = point.x >= frame.maxX - cornerSize
        let inTopBand = point.y <= frame.minY + cornerSize
        let inBottomBand = point.y >= frame.maxY - cornerSize

        let position: SnapPosition
        if (nearLeft && inTopBand) || (nearTop && inLeftBand) {
            position = .topLeft
        } else if (nearRight && inTopBand) || (nearTop && inRightBand) {
            position = .topRight
        } else if (nearLeft && inBottomBand) || (nearBottom && inLeftBand) {
            position = .bottomLeft
        } else if (nearRight && inBottomBand) || (nearBottom && inRightBand) {
            position = .bottomRight
        } else if nearLeft {
            position = .left
        } else if nearRight {
            position = .right
        } else if nearTop {
            position = .top
        } else if nearBottom {
            position = .bottom
        } else {
            return nil
        }

        let action: WindowAction
        switch behavior(position) {
        case .none:
            return nil
        case .action(let configured):
            action = configured
        case .thirds:
            // Langs de boven- en onderrand op x, langs de zijkanten op y.
            let relative = position.isHorizontalEdge
                ? (point.x - frame.minX) / frame.width
                : (point.y - frame.minY) / frame.height
            action = relative < 1.0 / 3 ? .firstThird : relative < 2.0 / 3 ? .centerThird : .lastThird
        }
        return Snap(action: action, screen: screen)
    }
}
