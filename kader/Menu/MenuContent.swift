import KeyboardShortcuts
import SwiftUI

struct MenuContent: View {
    let permission: AccessibilityPermission
    let perform: (WindowAction) -> Void

    @Environment(\.openSettings) private var openSettings

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

        Button("Instellingen…") {
            // Kader heeft geen Dock-icoon, dus zonder activeren opent het venster achter andere apps.
            NSApplication.shared.activate()
            openSettings()
        }
        .keyboardShortcut(",")

        Button("Stop Kader") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
