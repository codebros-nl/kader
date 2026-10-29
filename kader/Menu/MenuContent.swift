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
            Text("Kader is active")
        } else {
            Text("Accessibility access not granted")
            Button("Grant Access…") {
                permission.request()
            }
            Button("Open System Settings") {
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
            Button("Save Current Layout") {
                layouts.saveCurrentLayout()
            }
        }
        .disabled(!permission.isGranted)

        if let bundleIdentifier = frontmostApp.bundleIdentifier, let name = frontmostApp.name {
            Toggle("Ignore \(name)", isOn: Binding(
                get: { excludedApps.contains(bundleIdentifier) },
                set: { excludedApps.setExcluded($0, bundleIdentifier: bundleIdentifier) }
            ))
        }

        Button("Settings…") {
            openSettings()
        }
        .keyboardShortcut(",")

        Button("Quit Kader") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
