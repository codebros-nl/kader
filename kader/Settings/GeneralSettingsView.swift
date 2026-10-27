import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(SettingsKey.windowGap) private var windowGap: Double = 0
    @State private var launchAtLogin = LaunchAtLogin()

    var body: some View {
        Form {
            Toggle("Opstarten bij inloggen", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            if launchAtLogin.needsApproval {
                LabeledContent {
                    Button("Open Inlogonderdelen") {
                        launchAtLogin.openLoginItemsSettings()
                    }
                } label: {
                    Text("Keur Kader goed in Systeeminstellingen om bij inloggen te starten.")
                        .foregroundStyle(.secondary)
                }
            }

            LabeledContent("Marge tussen vensters") {
                HStack {
                    Slider(value: $windowGap, in: 0...40, step: 1)
                    Text("\(Int(windowGap)) pt")
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin.refresh()
        }
    }
}
