import AppKit

/// Toont tijdens slepen met Shift alle eigen zones van één scherm, met de zone onder de cursor uitgelicht.
@MainActor
final class ZoneOverlay {
    private let zonesView = ZonesView()
    private lazy var panel = NSPanel.makeOverlay(contentView: zonesView)

    /// - Parameters:
    ///   - zones: Zone-frames in Accessibility-coördinaten.
    ///   - area: Het zichtbare schermgebied waarover de overlay ligt.
    ///   - highlighted: Index van de zone onder de cursor.
    func show(zones: [CGRect], in area: CGRect, highlighted: Int?) {
        // De view is geflipt, dus lokale coördinaten lopen net als Accessibility-coördinaten omlaag.
        zonesView.zones = zones.map { $0.offsetBy(dx: -area.minX, dy: -area.minY) }
        zonesView.highlighted = highlighted
        zonesView.needsDisplay = true

        panel.setFrame(inAccessibilityCoordinates: area)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        panel.orderOut(nil)
    }
}

private final class ZonesView: NSView {
    var zones: [CGRect] = []
    var highlighted: Int?

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let accent = NSColor.controlAccentColor
        for (index, zone) in zones.enumerated() {
            let isHighlighted = index == highlighted
            let path = NSBezierPath(roundedRect: zone.insetBy(dx: 2, dy: 2), xRadius: 10, yRadius: 10)

            accent.withAlphaComponent(isHighlighted ? 0.3 : 0.08).setFill()
            path.fill()

            accent.withAlphaComponent(isHighlighted ? 0.9 : 0.4).setStroke()
            path.lineWidth = isHighlighted ? 3 : 1.5
            path.stroke()
        }
    }
}
