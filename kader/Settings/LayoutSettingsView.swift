import SwiftUI

struct LayoutSettingsView: View {
    let layouts: LayoutService

    var body: some View {
        Form {
            Section {
                if layouts.store.layouts.isEmpty {
                    Text("No layouts saved yet")
                        .foregroundStyle(.secondary)
                }
                ForEach(layouts.store.layouts) { layout in
                    LayoutRow(layout: layout, layouts: layouts)
                }
            } header: {
                Text("Layouts")
            } footer: {
                Text("A layout remembers where the windows of all open apps are. Applying automatically happens when its display arrangement becomes active, for example when you connect a monitor.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Save Current Layout") {
                    layouts.saveCurrentLayout()
                }
                LabeledContent("Current displays", value: layouts.currentSetup.summary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct LayoutRow: View {
    let layout: Layout
    let layouts: LayoutService

    /// Lokale kopie tijdens typen; pas opslaan bij Enter of als het veld de focus verliest.
    @State private var name: String
    @FocusState private var isEditingName: Bool

    init(layout: Layout, layouts: LayoutService) {
        self.layout = layout
        self.layouts = layouts
        _name = State(initialValue: layout.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Name", text: $name)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .focused($isEditingName)
                    .onSubmit(commitName)
                    .onChange(of: isEditingName) {
                        if !isEditingName { commitName() }
                    }

                Button("Apply") {
                    layouts.apply(layout)
                }
                .disabled(!layouts.canApply(layout))
                .help(layouts.canApply(layout) ? "" : "Made for other displays")

                Button {
                    layouts.store.remove(layout.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete")
            }

            Text("\(layout.windows.count) windows · \(layout.screenSetup.summary)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Apply automatically on these displays", isOn: Binding(
                get: { layout.appliesAutomatically },
                set: { layouts.store.setAppliesAutomatically($0, for: layout.id) }
            ))
            .controlSize(.small)
        }
        .padding(.vertical, 2)
    }

    private func commitName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            name = layout.name
            return
        }
        if trimmed != layout.name {
            layouts.store.rename(layout.id, to: trimmed)
        }
    }
}
