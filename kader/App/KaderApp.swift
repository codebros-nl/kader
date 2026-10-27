import SwiftUI

@main
struct KaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Kader", systemImage: "rectangle.split.2x2") {
            MenuContent(
                permission: appDelegate.permission,
                excludedApps: appDelegate.excludedApps,
                frontmostApp: appDelegate.frontmostApp,
                layouts: appDelegate.layouts,
                perform: appDelegate.perform,
                openSettings: appDelegate.openSettings
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
