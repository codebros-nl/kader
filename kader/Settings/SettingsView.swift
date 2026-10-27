import SwiftUI

struct SettingsView: View {
    let excludedApps: ExcludedApps
    let layouts: LayoutService

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Algemeen", systemImage: "gearshape") }

            DragSettingsView()
                .tabItem { Label("Slepen", systemImage: "hand.draw") }

            ZoneSettingsView()
                .tabItem { Label("Zones", systemImage: "square.grid.3x2") }

            ShortcutSettingsView()
                .tabItem { Label("Sneltoetsen", systemImage: "keyboard") }

            LayoutSettingsView(layouts: layouts)
                .tabItem { Label("Layouts", systemImage: "rectangle.3.group") }

            ExclusionSettingsView(excludedApps: excludedApps)
                .tabItem { Label("Uitzonderingen", systemImage: "nosign") }
        }
        .frame(width: 580, height: 560)
    }
}
