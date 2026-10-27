import AppKit

extension NSPanel {
    /// Doorzichtig paneel boven alle vensters dat geen klikken opvangt en Kader niet activeert.
    /// Gebruikt voor de snap-preview en de zone-overlay.
    static func makeOverlay(contentView: NSView) -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = contentView
        return panel
    }

    /// Zet het paneel op een frame in Accessibility-coördinaten.
    func setFrame(inAccessibilityCoordinates frame: CGRect) {
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return }
        setFrame(ScreenGeometry.convert(frame, primaryScreenHeight: primaryHeight), display: true)
    }
}
