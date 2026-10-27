import AppKit
import SwiftUI

/// Beheert het instellingenvenster zelf. De SwiftUI `Settings`-scene opent niet betrouwbaar
/// vanuit een menubalk-app zonder Dock-icoon.
@MainActor
final class SettingsWindowController {
    private let excludedApps: ExcludedApps
    private var window: NSWindow?

    init(excludedApps: ExcludedApps) {
        self.excludedApps = excludedApps
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
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(excludedApps: excludedApps)))
        window.title = "Kader-instellingen"
        window.styleMask = [.titled, .closable]
        // Hergebruiken na sluiten, zodat er nooit twee instellingenvensters zijn.
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
