import SwiftUI

struct SettingsView: View {
    let excludedApps: ExcludedApps
    let layouts: LayoutService

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Algemeen", systemImage: "gearshape") }

            ShortcutSettingsView()
                .tabItem { Label("Sneltoetsen", systemImage: "keyboard") }

            LayoutSettingsView(layouts: layouts)
                .tabItem { Label("Layouts", systemImage: "rectangle.3.group") }

            ExclusionSettingsView(excludedApps: excludedApps)
                .tabItem { Label("Uitzonderingen", systemImage: "nosign") }
        }
        .frame(width: 460, height: 520)
    }
}
