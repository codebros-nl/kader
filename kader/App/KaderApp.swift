import SwiftUI

@main
struct KaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Kader", systemImage: "rectangle.split.2x2") {
            MenuContent(permission: appDelegate.permission, perform: appDelegate.perform)
        }
        .menuBarExtraStyle(.menu)
    }
}
