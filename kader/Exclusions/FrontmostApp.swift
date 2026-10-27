import AppKit
import Observation

/// Houdt bij welke andere app vooraan staat. Kader zelf telt niet mee, zodat het menu
/// en het instellingenvenster de app noemen waar de gebruiker net mee bezig was.
@MainActor
@Observable
final class FrontmostApp {
    private(set) var app: NSRunningApplication?

    /// Wordt aangeroepen als er een andere app vooraan komt.
    @ObservationIgnored
    var onChange: () -> Void = {}

    @ObservationIgnored
    private var observer: NSObjectProtocol?

    init() {
        update(NSWorkspace.shared.frontmostApplication)
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                self?.update(app)
            }
        }
    }

    var bundleIdentifier: String? { app?.bundleIdentifier }

    var name: String? { app?.localizedName }

    private func update(_ newApp: NSRunningApplication?) {
        guard let newApp, newApp.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        app = newApp
        onChange()
    }
}
