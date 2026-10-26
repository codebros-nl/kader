import SwiftUI

struct MenuContent: View {
    let permission: AccessibilityPermission
    let perform: (WindowAction) -> Void

    private static let sections: [[WindowAction]] = [
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.maximize, .center],
    ]

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

        ForEach(Self.sections, id: \.self) { section in
            Divider()
            ForEach(section) { action in
                Button(action.title) {
                    perform(action)
                }
                .keyboardShortcut(Hotkey.defaultShortcut(for: action))
                .disabled(!permission.isGranted)
            }
        }

        Divider()

        Button("Stop Kader") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
