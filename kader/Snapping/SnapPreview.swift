import AppKit

/// Semi-transparante rechthoek die tijdens het slepen laat zien waar het venster terechtkomt.
@MainActor
final class SnapPreview {
    private lazy var panel = NSPanel.makeOverlay(contentView: makeContentView())

    /// Toont de preview op een frame in Accessibility-coördinaten.
    func show(_ frame: CGRect) {
        // Alleen animeren als de preview al zichtbaar is, anders vliegt hij vanaf de vorige plek in.
        let isVisible = panel.isVisible
        panel.setFrame(inAccessibilityCoordinates: frame, animated: isVisible)
        if !isVisible {
            // Naar voren zonder Kader te activeren, zodat het gesleepte venster de focus houdt.
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func makeContentView() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        if let layer = view.layer {
            layer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
            layer.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
            layer.borderWidth = 2
            layer.cornerRadius = 10
        }
        return view
    }
}
