import AppKit

/// Eigenaar van de services die zo lang leven als de app.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permission = AccessibilityPermission()
    let excludedApps = ExcludedApps()
    let frontmostApp = FrontmostApp()
    private let windowManager = WindowManager()
    private lazy var settingsWindow = SettingsWindowController(excludedApps: excludedApps)
    private lazy var hotkeys = HotkeyService { [weak self] action in
        self?.perform(action)
    }
    private lazy var snapDetector = SnapDetector(
        windowManager: windowManager,
        isEnabled: { [weak self] in
            guard let self else { return false }
            return permission.isGranted && UserDefaults.standard.bool(forKey: SettingsKey.dragToSnap)
        },
        allowsWindow: { [weak self] window in
            guard let self else { return false }
            return !excludedApps.contains(windowManager.bundleIdentifier(of: window))
        }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [SettingsKey.dragToSnap: true])
        hotkeys.registerAll()
        snapDetector.start()

        frontmostApp.onChange = { [weak self] in self?.updateHotkeyAvailability() }
        excludedApps.onChange = { [weak self] in self?.updateHotkeyAvailability() }
        updateHotkeyAvailability()
    }

    /// Gedeeld startpunt voor sneltoetsen en het menu.
    func perform(_ action: WindowAction) {
        guard permission.isGranted else {
            permission.request()
            return
        }
        windowManager.perform(action)
    }

    func openSettings() {
        settingsWindow.show()
    }

    /// Sneltoetsen uit zolang een genegeerde app vooraan staat.
    private func updateHotkeyAvailability() {
        hotkeys.setEnabled(!excludedApps.contains(frontmostApp.bundleIdentifier))
    }
}
