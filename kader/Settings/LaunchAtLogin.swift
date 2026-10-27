import Observation
import ServiceManagement
import os

/// Opstarten bij inloggen via `SMAppService`. De status zelf staat bij macOS, niet in `UserDefaults`,
/// zodat de schakelaar klopt als de gebruiker het in Systeeminstellingen uitzet.
@MainActor
@Observable
final class LaunchAtLogin {
    private(set) var status = SMAppService.mainApp.status

    @ObservationIgnored
    private let logger = Logger(subsystem: "nl.codebros.kader", category: "LaunchAtLogin")

    /// Aan, ook als macOS nog wacht op goedkeuring in Inlogonderdelen.
    var isEnabled: Bool {
        status == .enabled || status == .requiresApproval
    }

    var needsApproval: Bool {
        status == .requiresApproval
    }

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
        status = SMAppService.mainApp.status
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
