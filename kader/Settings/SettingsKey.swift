/// Sleutels voor voorkeuren in `UserDefaults` / `@AppStorage`.
nonisolated enum SettingsKey {
    /// Marge in punten tussen vensters en tussen venster en schermrand.
    static let windowGap = "windowGap"
    /// Vensters snappen door ze naar een schermrand of hoek te slepen. Standaard aan.
    static let dragToSnap = "dragToSnap"
    /// Bundle-ID's van apps die Kader negeert.
    static let excludedApps = "excludedApps"
    /// Eigen zones tonen door tijdens het slepen Shift ingedrukt te houden. Standaard aan.
    static let zonesEnabled = "zonesEnabled"
    /// Kolombreedtes van de eigen zones, bijvoorbeeld "25, 50, 25".
    static let zoneColumns = "zoneColumns"
    /// Rijhoogtes van de eigen zones, bijvoorbeeld "100".
    static let zoneRows = "zoneRows"
}
