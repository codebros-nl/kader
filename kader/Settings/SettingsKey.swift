/// Sleutels voor voorkeuren in `UserDefaults` / `@AppStorage`.
nonisolated enum SettingsKey {
    /// Marge in punten tussen vensters en tussen venster en schermrand.
    static let windowGap = "windowGap"
    /// Vensters snappen door ze naar een schermrand of hoek te slepen. Standaard aan.
    static let dragToSnap = "dragToSnap"
    /// Bundle-ID's van apps die Kader negeert.
    static let excludedApps = "excludedApps"
}
