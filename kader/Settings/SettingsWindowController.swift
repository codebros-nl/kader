import AppKit
import SwiftUI

/// Beheert het instellingenvenster zelf. De SwiftUI `Settings`-scene opent niet betrouwbaar
/// vanuit een menubalk-app zonder Dock-icoon.
@MainActor
final class SettingsWindowController {
    private let excludedApps: ExcludedApps
    private let layouts: LayoutService
    private var window: NSWindow?

    init(excludedApps: ExcludedApps, layouts: LayoutService) {
        self.excludedApps = excludedApps
        self.layouts = layouts
    }

    func show() {
        let window = self.window ?? makeWindow()
        self.window = window

        NSApplication.shared.activate()
        // Ook naar voren als macOS de activering van een agent-app negeert.
        window.orderFrontRegardless()
        window.makeKey()
    }

    private func makeWindow() -> NSWindow {
        let hostingController = NSHostingController(rootView: SettingsView(excludedApps: excludedApps, layouts: layouts))
        // Titel en werkbalk komen uit SwiftUI (navigationTitle per onderdeel).
        hostingController.sceneBridgingOptions = [.title, .toolbars]

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Kader-instellingen"
        // Inhoud onder de titelbalk door, zodat de zijbalk tot bovenaan loopt zoals in Systeeminstellingen.
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = true
        // Hergebruiken na sluiten, zodat er nooit twee instellingenvensters zijn.
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
