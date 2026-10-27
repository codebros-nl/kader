import KeyboardShortcuts
import SwiftUI

struct MenuContent: View {
    let permission: AccessibilityPermission
    let excludedApps: ExcludedApps
    let frontmostApp: FrontmostApp
    let layouts: LayoutService
    let perform: (WindowAction) -> Void
    let openSettings: () -> Void

    var body: some View {
        if permission.isGranted {
            Text("Kader is actief")
        } else {
            Text("Toegankelijkheid nog niet toegestaan")
            Button("Toestemming geven…") {
                permission.request()
            }
            Button("Open Systeeminstellingen") {
                permission.openSystemSettings()
            }
        }

        ForEach(WindowAction.groups, id: \.self) { group in
            Divider()
            ForEach(group) { action in
                Button(action.title) {
                    perform(action)
                }
                .globalKeyboardShortcut(action.shortcutName)
                .disabled(!permission.isGranted)
            }
        }

        Divider()

        Menu("Layouts") {
            ForEach(layouts.store.layouts) { layout in
                Button(layout.name) {
                    layouts.apply(layout)
                }
                .disabled(!layouts.canApply(layout))
            }
            if !layouts.store.layouts.isEmpty {
                Divider()
            }
            Button("Huidige indeling opslaan") {
                layouts.saveCurrentLayout()
            }
        }
        .disabled(!permission.isGranted)

        if let bundleIdentifier = frontmostApp.bundleIdentifier, let name = frontmostApp.name {
            Toggle("Negeer \(name)", isOn: Binding(
                get: { excludedApps.contains(bundleIdentifier) },
                set: { excludedApps.setExcluded($0, bundleIdentifier: bundleIdentifier) }
            ))
        }

        Button("Instellingen…") {
            openSettings()
        }
        .keyboardShortcut(",")

        Button("Stop Kader") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
