import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ExclusionSettingsView: View {
    let excludedApps: ExcludedApps

    var body: some View {
        Form {
            Section {
                if excludedApps.bundleIdentifiers.isEmpty {
                    Text("Geen apps genegeerd")
                        .foregroundStyle(.secondary)
                }
                ForEach(excludedApps.bundleIdentifiers.sorted(), id: \.self) { bundleIdentifier in
                    HStack {
                        AppLabel(bundleIdentifier: bundleIdentifier)
                        Spacer()
                        Button {
                            excludedApps.setExcluded(false, bundleIdentifier: bundleIdentifier)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Niet meer negeren")
                    }
                }
            } header: {
                Text("Genegeerde apps")
            } footer: {
                Text("In deze apps gaan de sneltoetsen naar de app zelf en snappen vensters niet bij slepen.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("App toevoegen…") {
                    chooseApp()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.prompt = "Negeer"

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            if let bundleIdentifier = Bundle(url: url)?.bundleIdentifier {
                excludedApps.setExcluded(true, bundleIdentifier: bundleIdentifier)
            }
        }
    }
}

/// Icoon en naam van een app op basis van de bundle-ID; de ID zelf als de app niet (meer) is geïnstalleerd.
private struct AppLabel: View {
    let bundleIdentifier: String

    var body: some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            Label {
                Text(FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: ""))
            } icon: {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        } else {
            Label(bundleIdentifier, systemImage: "questionmark.app")
        }
    }
}
