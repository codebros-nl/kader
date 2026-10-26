import CoreGraphics

/// Pure rekenlogica: actie + schermframe → doelframe.
///
/// Tenzij anders vermeld rekent alles in Accessibility-coördinaten:
/// oorsprong linksboven op het hoofdscherm, y loopt omlaag.
nonisolated enum ScreenGeometry {
    nonisolated struct Screen: Equatable, Sendable {
        /// Volledig schermframe, gebruikt om te bepalen op welk scherm een venster staat.
        var frame: CGRect
        /// Frame zonder menubalk en Dock, gebruikt als ruimte voor de acties.
        var visibleFrame: CGRect
    }

    /// Zet een rechthoek om tussen Cocoa-coördinaten (oorsprong linksonder, y omhoog)
    /// en Accessibility-coördinaten (oorsprong linksboven, y omlaag).
    /// De omzetting is symmetrisch, dus dezelfde functie werkt in beide richtingen.
    static func convert(_ rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Zet schermen uit `NSScreen.screens` (Cocoa-coördinaten) om naar Accessibility-coördinaten.
    /// Het eerste scherm is het hoofdscherm met de menubalk, net als bij `NSScreen.screens`.
    static func accessibilityScreens(fromCocoa screens: [Screen]) -> [Screen] {
        guard let primary = screens.first else { return [] }
        let height = primary.frame.height
        return screens.map {
            Screen(
                frame: convert($0.frame, primaryScreenHeight: height),
                visibleFrame: convert($0.visibleFrame, primaryScreenHeight: height)
            )
        }
    }

    /// Het scherm met de grootste overlap met het venster.
    /// Overlapt het venster geen enkel scherm, dan het scherm waarvan het midden het dichtst bij ligt.
    static func screen(for windowFrame: CGRect, in screens: [Screen]) -> Screen? {
        let overlapping = screens
            .map { (screen: $0, area: overlapArea(windowFrame, $0.frame)) }
            .filter { $0.area > 0 }

        if let best = overlapping.max(by: { $0.area < $1.area }) {
            return best.screen
        }

        return screens.min {
            distance($0.frame.center, windowFrame.center) < distance($1.frame.center, windowFrame.center)
        }
    }

    /// Het doelframe van een venster voor een actie binnen het zichtbare deel van een scherm.
    static func targetFrame(for action: WindowAction, currentFrame: CGRect, visibleFrame area: CGRect) -> CGRect {
        let halfWidth = area.width / 2
        let halfHeight = area.height / 2

        switch action {
        case .leftHalf:
            return CGRect(x: area.minX, y: area.minY, width: halfWidth, height: area.height)
        case .rightHalf:
            return CGRect(x: area.minX + halfWidth, y: area.minY, width: halfWidth, height: area.height)
        case .topHalf:
            return CGRect(x: area.minX, y: area.minY, width: area.width, height: halfHeight)
        case .bottomHalf:
            return CGRect(x: area.minX, y: area.minY + halfHeight, width: area.width, height: halfHeight)
        case .topLeft:
            return CGRect(x: area.minX, y: area.minY, width: halfWidth, height: halfHeight)
        case .topRight:
            return CGRect(x: area.minX + halfWidth, y: area.minY, width: halfWidth, height: halfHeight)
        case .bottomLeft:
            return CGRect(x: area.minX, y: area.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .bottomRight:
            return CGRect(x: area.minX + halfWidth, y: area.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .maximize:
            return area
        case .center:
            // Grootte behouden, maar nooit groter dan het scherm.
            let width = min(currentFrame.width, area.width)
            let height = min(currentFrame.height, area.height)
            return CGRect(x: area.midX - width / 2, y: area.midY - height / 2, width: width, height: height)
        }
    }

    private static func overlapArea(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull else { return 0 }
        return intersection.width * intersection.height
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}

private extension CGRect {
    nonisolated var center: CGPoint { CGPoint(x: midX, y: midY) }
}
