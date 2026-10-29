import KeyboardShortcuts
import SwiftUI

struct ShortcutSettingsView: View {
    var body: some View {
        Form {
            ForEach(WindowAction.groups, id: \.self) { group in
                Section {
                    ForEach(group) { action in
                        KeyboardShortcuts.Recorder(action.title, name: action.shortcutName)
                    }
                }
            }

            Section {
                Button("Restore Default Shortcuts") {
                    KeyboardShortcuts.reset(WindowAction.allCases.map(\.shortcutName))
                }
            }
        }
        .formStyle(.grouped)
    }
}
