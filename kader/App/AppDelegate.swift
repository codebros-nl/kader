import AppKit

/// Eigenaar van de services die zo lang leven als de app.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permission = AccessibilityPermission()
    private let windowManager = WindowManager()
    private lazy var hotkeys = HotkeyService { [weak self] action in
        self?.perform(action)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeys.register(Hotkey.defaults)
    }

    /// Gedeeld startpunt voor sneltoetsen en het menu.
    func perform(_ action: WindowAction) {
        guard permission.isGranted else {
            permission.request()
            return
        }
        windowManager.perform(action)
    }
}
