import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Algemeen", systemImage: "gearshape") }

            ShortcutSettingsView()
                .tabItem { Label("Sneltoetsen", systemImage: "keyboard") }
        }
        .frame(width: 460, height: 520)
    }
}
