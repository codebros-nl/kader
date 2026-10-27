import AppKit

/// Eigenaar van de services die zo lang leven als de app.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permission = AccessibilityPermission()
    private let windowManager = WindowManager()
    private let settingsWindow = SettingsWindowController()
    private lazy var hotkeys = HotkeyService { [weak self] action in
        self?.perform(action)
    }
    private lazy var snapDetector = SnapDetector(windowManager: windowManager) { [weak self] in
        guard let self else { return false }
        return permission.isGranted && UserDefaults.standard.bool(forKey: SettingsKey.dragToSnap)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [SettingsKey.dragToSnap: true])
        hotkeys.registerAll()
        snapDetector.start()
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
}
