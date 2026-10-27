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

    /// Breuken waar helften bij herhaald drukken doorheen lopen: ½ → ⅓ → ⅔.
    private static let cycleFractions: [CGFloat] = [1.0 / 2, 1.0 / 3, 2.0 / 3]

    // MARK: - Coördinaten

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

    /// Zet een punt om tussen Cocoa- en Accessibility-coördinaten, bijvoorbeeld de muispositie.
    /// Ook deze omzetting is symmetrisch.
    static func convert(_ point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
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

    // MARK: - Schermkeuze

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

    /// Het scherm `offset` plaatsen verder dan `current`, met schermen gesorteerd van links naar rechts
    /// (bij gelijke x van boven naar onder). Loopt rond aan het eind. Nil bij minder dan twee schermen.
    static func screen(offsetBy offset: Int, from current: Screen, in screens: [Screen]) -> Screen? {
        let sorted = screens.sorted {
            ($0.frame.minX, $0.frame.minY) < ($1.frame.minX, $1.frame.minY)
        }
        guard sorted.count > 1, let index = sorted.firstIndex(of: current) else { return nil }

        let count = sorted.count
        return sorted[((index + offset) % count + count) % count]
    }

    // MARK: - Doelframes

    /// Het doelframe van een venster voor een actie binnen het zichtbare deel van een scherm.
    ///
    /// - Parameters:
    ///   - step: Hoe vaak de actie achter elkaar is herhaald, voor acties met `cycleLength > 1`.
    ///   - gap: Marge tussen vensters onderling en tussen venster en schermrand.
    /// - Returns: Nil voor acties zonder vaste indeling (ander scherm, herstellen).
    static func targetFrame(
        for action: WindowAction,
        step: Int = 0,
        currentFrame: CGRect,
        visibleFrame area: CGRect,
        gap: CGFloat = 0
    ) -> CGRect? {
        if action == .center {
            // Grootte behouden, maar nooit groter dan het scherm.
            let usable = area.insetBy(dx: gap, dy: gap)
            let width = min(currentFrame.width, usable.width)
            let height = min(currentFrame.height, usable.height)
            return rounded(CGRect(x: usable.midX - width / 2, y: usable.midY - height / 2, width: width, height: height))
        }

        guard let unit = unitRect(for: action, step: step, isLandscape: area.width >= area.height) else {
            return nil
        }
        return frame(for: unit, in: area, gap: gap)
    }

    /// Verplaatst een frame van het ene gebied naar het andere met behoud van relatieve positie en grootte,
    /// en houdt het binnen het nieuwe gebied.
    static func frame(_ frame: CGRect, movedFrom source: CGRect, to destination: CGRect) -> CGRect {
        guard source.width > 0, source.height > 0 else { return frame }

        let scaleX = destination.width / source.width
        let scaleY = destination.height / source.height
        let width = min(frame.width * scaleX, destination.width)
        let height = min(frame.height * scaleY, destination.height)
        let x = destination.minX + (frame.minX - source.minX) * scaleX
        let y = destination.minY + (frame.minY - source.minY) * scaleY

        return rounded(CGRect(
            x: min(max(x, destination.minX), destination.maxX - width),
            y: min(max(y, destination.minY), destination.maxY - height),
            width: width,
            height: height
        ))
    }

    // MARK: - Hulpfuncties

    /// Positie en grootte als fractie (0...1) van het zichtbare gebied.
    private static func unitRect(for action: WindowAction, step: Int, isLandscape: Bool) -> CGRect? {
        let fraction = cycleFractions[max(0, step) % cycleFractions.count]

        // Derden lopen over de lange kant: kolommen op een liggend scherm, rijen op een staand scherm.
        func span(_ start: CGFloat, _ length: CGFloat) -> CGRect {
            isLandscape
                ? CGRect(x: start, y: 0, width: length, height: 1)
                : CGRect(x: 0, y: start, width: 1, height: length)
        }

        switch action {
        case .leftHalf: return CGRect(x: 0, y: 0, width: fraction, height: 1)
        case .rightHalf: return CGRect(x: 1 - fraction, y: 0, width: fraction, height: 1)
        case .topHalf: return CGRect(x: 0, y: 0, width: 1, height: fraction)
        case .bottomHalf: return CGRect(x: 0, y: 1 - fraction, width: 1, height: fraction)
        case .topLeft: return CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        case .topRight: return CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)
        case .bottomLeft: return CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
        case .bottomRight: return CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        case .firstThird: return span(0, 1.0 / 3)
        case .centerThird: return span(1.0 / 3, 1.0 / 3)
        case .lastThird: return span(2.0 / 3, 1.0 / 3)
        case .firstTwoThirds: return span(0, 2.0 / 3)
        case .lastTwoThirds: return span(1.0 / 3, 2.0 / 3)
        case .maximize: return CGRect(x: 0, y: 0, width: 1, height: 1)
        case .center, .nextScreen, .previousScreen, .restore: return nil
        }
    }

    /// Zet een fractie om naar een frame. Randen aan de schermkant krijgen de volle marge,
    /// randen tussen twee vensters elk de halve, zodat de ruimte tussen vensters ook `gap` is.
    private static func frame(for unit: CGRect, in area: CGRect, gap: CGFloat) -> CGRect {
        let tolerance = 0.001
        let minXInset = unit.minX < tolerance ? gap : gap / 2
        let maxXInset = unit.maxX > 1 - tolerance ? gap : gap / 2
        let minYInset = unit.minY < tolerance ? gap : gap / 2
        let maxYInset = unit.maxY > 1 - tolerance ? gap : gap / 2

        let minX = area.minX + unit.minX * area.width + minXInset
        let maxX = area.minX + unit.maxX * area.width - maxXInset
        let minY = area.minY + unit.minY * area.height + minYInset
        let maxY = area.minY + unit.maxY * area.height - maxYInset

        return rounded(CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY))
    }

    /// Rondt randen af op hele punten, zodat aangrenzende vensters exact op elkaar aansluiten.
    private static func rounded(_ rect: CGRect) -> CGRect {
        let minX = rect.minX.rounded()
        let minY = rect.minY.rounded()
        return CGRect(x: minX, y: minY, width: rect.maxX.rounded() - minX, height: rect.maxY.rounded() - minY)
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
