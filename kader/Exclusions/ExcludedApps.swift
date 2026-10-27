import Foundation
import Observation

/// Apps waarin Kader niets doet: de sneltoetsen gaan naar de app zelf
/// en vensters van die app snappen niet bij slepen.
@MainActor
@Observable
final class ExcludedApps {
    private(set) var bundleIdentifiers: Set<String>

    /// Wordt aangeroepen na elke wijziging, zodat de sneltoetsen direct worden bijgewerkt.
    @ObservationIgnored
    var onChange: () -> Void = {}

    @ObservationIgnored
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bundleIdentifiers = Set(defaults.stringArray(forKey: SettingsKey.excludedApps) ?? [])
    }

    func contains(_ bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return bundleIdentifiers.contains(bundleIdentifier)
    }

    func setExcluded(_ excluded: Bool, bundleIdentifier: String) {
        if excluded {
            bundleIdentifiers.insert(bundleIdentifier)
        } else {
            bundleIdentifiers.remove(bundleIdentifier)
        }
        defaults.set(bundleIdentifiers.sorted(), forKey: SettingsKey.excludedApps)
        onChange()
    }
}
