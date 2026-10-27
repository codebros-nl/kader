import SwiftUI

struct DragSettingsView: View {
    @AppStorage(SettingsKey.dragToSnap) private var dragToSnap = true

    var body: some View {
        Form {
            Toggle("Vensters snappen door naar een schermrand te slepen", isOn: $dragToSnap)

            Section {
                ForEach(SnapPosition.allCases) { position in
                    SnapPositionPicker(position: position)
                }
            } header: {
                Text("Randen en hoeken")
            } footer: {
                Button("Standaardwaarden herstellen") {
                    for position in SnapPosition.allCases {
                        UserDefaults.standard.removeObject(forKey: position.settingsKey)
                    }
                }
            }
            .disabled(!dragToSnap)
        }
        .formStyle(.grouped)
    }
}

private struct SnapPositionPicker: View {
    let position: SnapPosition
    @AppStorage private var behavior: SnapBehavior

    init(position: SnapPosition) {
        self.position = position
        _behavior = AppStorage(wrappedValue: position.defaultBehavior, position.settingsKey)
    }

    var body: some View {
        Picker(position.title, selection: $behavior) {
            ForEach(SnapBehavior.options(for: position), id: \.self) { option in
                Text(option.title).tag(option)
            }
        }
    }
}
