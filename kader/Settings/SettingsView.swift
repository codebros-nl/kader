import SwiftUI

struct SettingsView: View {
    let excludedApps: ExcludedApps

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Algemeen", systemImage: "gearshape") }

            ShortcutSettingsView()
                .tabItem { Label("Sneltoetsen", systemImage: "keyboard") }

            ExclusionSettingsView(excludedApps: excludedApps)
                .tabItem { Label("Uitzonderingen", systemImage: "nosign") }
        }
        .frame(width: 460, height: 520)
    }
}
