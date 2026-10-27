import Observation
import ServiceManagement
import os

/// Opstarten bij inloggen via `SMAppService`. De status zelf staat bij macOS, niet in `UserDefaults`,
/// zodat de schakelaar klopt als de gebruiker het in Systeeminstellingen uitzet.
@MainActor
@Observable
final class LaunchAtLogin {
    private(set) var isEnabled = SMAppService.mainApp.status == .enabled

    @ObservationIgnored
    private let logger = Logger(subsystem: "nl.codebros.kader", category: "LaunchAtLogin")

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Opstarten bij inloggen wijzigen mislukt: \(error.localizedDescription, privacy: .public)")
        }
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
