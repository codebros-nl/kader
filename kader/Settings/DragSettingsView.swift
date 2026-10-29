import SwiftUI

struct DragSettingsView: View {
    @AppStorage(SettingsKey.dragToSnap) private var dragToSnap = true

    var body: some View {
        Form {
            Toggle("Snap windows by dragging them to a screen edge", isOn: $dragToSnap)

            Section {
                ForEach(SnapPosition.allCases) { position in
                    SnapPositionPicker(position: position)
                }
            } header: {
                Text("Edges and Corners")
            } footer: {
                Button("Restore Defaults") {
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
