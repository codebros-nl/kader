import KeyboardShortcuts
import SwiftUI

struct MenuContent: View {
    let permission: AccessibilityPermission
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
