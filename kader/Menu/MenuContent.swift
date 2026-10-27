import SwiftUI

struct MenuContent: View {
    let permission: AccessibilityPermission
    let perform: (WindowAction) -> Void

    @Environment(\.openSettings) private var openSettings

    private static let sections: [[WindowAction]] = [
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.firstThird, .centerThird, .lastThird, .firstTwoThirds, .lastTwoThirds],
        [.maximize, .center, .restore],
        [.nextScreen, .previousScreen],
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
