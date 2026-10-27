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
