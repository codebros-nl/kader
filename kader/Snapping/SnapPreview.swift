import AppKit

/// Semi-transparante rechthoek die tijdens het slepen laat zien waar het venster terechtkomt.
@MainActor
final class SnapPreview {
    private lazy var panel = makePanel()

    /// Toont de preview op een frame in Accessibility-coördinaten.
    func show(_ frame: CGRect) {
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return }
        let cocoaFrame = ScreenGeometry.convert(frame, primaryScreenHeight: primaryHeight)

        if panel.isVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().setFrame(cocoaFrame, display: true)
            }
        } else {
            panel.setFrame(cocoaFrame, display: true)
            // Naar voren zonder Kader te activeren, zodat het gesleepte venster de focus houdt.
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
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

        let view = NSView()
        view.wantsLayer = true
        if let layer = view.layer {
            layer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
            layer.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
            layer.borderWidth = 2
            layer.cornerRadius = 10
        }
        panel.contentView = view
        return panel
    }
}
