import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(SettingsKey.windowGap) private var windowGap: Double = 0
    @State private var launchAtLogin = LaunchAtLogin()

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            if launchAtLogin.needsApproval {
                LabeledContent {
                    Button("Open Login Items") {
                        launchAtLogin.openLoginItemsSettings()
                    }
                } label: {
                    Text("Approve Kader in System Settings to launch it at login.")
                        .foregroundStyle(.secondary)
                }
            }

            LabeledContent("Gap between windows") {
                HStack {
                    Slider(value: $windowGap, in: 0...40, step: 1)
                    Text(verbatim: "\(Int(windowGap)) pt")
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
