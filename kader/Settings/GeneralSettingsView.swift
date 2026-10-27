import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(SettingsKey.windowGap) private var windowGap: Double = 0
    @AppStorage(SettingsKey.dragToSnap) private var dragToSnap = true
    @State private var launchAtLogin = LaunchAtLogin()

    var body: some View {
        Form {
            Toggle("Opstarten bij inloggen", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            Toggle("Vensters snappen door naar een schermrand te slepen", isOn: $dragToSnap)

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
