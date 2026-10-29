import SwiftUI

/// Onderdelen van het instellingenvenster, in de volgorde van de zijbalk.
enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case drag
    case zones
    case shortcuts
    case layouts
    case exclusions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .drag: String(localized: "Drag")
        case .zones: String(localized: "Zones")
        case .shortcuts: String(localized: "Shortcuts")
        case .layouts: String(localized: "Layouts")
        case .exclusions: String(localized: "Exclusions")
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape.fill"
        case .drag: "hand.draw.fill"
        case .zones: "square.grid.3x2.fill"
        case .shortcuts: "command"
        case .layouts: "rectangle.3.group.fill"
        case .exclusions: "nosign"
        }
    }

    var color: Color {
        switch self {
        case .general: .gray
        case .drag: .blue
        case .zones: .purple
        case .shortcuts: .orange
        case .layouts: .green
        case .exclusions: .red
        }
    }
}

struct SettingsView: View {
    let excludedApps: ExcludedApps
    let layouts: LayoutService

    @State private var selection: SettingsPane = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $selection) { pane in
                Label {
                    Text(pane.title)
                } icon: {
                    SettingsIcon(systemImage: pane.systemImage, color: pane.color)
                }
                .tag(pane)
            }
            .navigationSplitViewColumnWidth(190)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail(for: selection)
                .navigationTitle(selection.title)
        }
        .frame(width: 720, height: 540)
    }

    @ViewBuilder
    private func detail(for pane: SettingsPane) -> some View {
        switch pane {
        case .general: GeneralSettingsView()
        case .drag: DragSettingsView()
        case .zones: ZoneSettingsView()
        case .shortcuts: ShortcutSettingsView()
        case .layouts: LayoutSettingsView(layouts: layouts)
        case .exclusions: ExclusionSettingsView(excludedApps: excludedApps)
        }
    }
}

/// Wit symbool op een gekleurd vierkantje, zoals in Systeeminstellingen.
private struct SettingsIcon: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}
