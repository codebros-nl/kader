import SwiftUI

struct LayoutSettingsView: View {
    let layouts: LayoutService

    var body: some View {
        Form {
            Section {
                if layouts.store.layouts.isEmpty {
                    Text("Nog geen layouts opgeslagen")
                        .foregroundStyle(.secondary)
                }
                ForEach(layouts.store.layouts) { layout in
                    LayoutRow(layout: layout, layouts: layouts)
                }
            } header: {
                Text("Layouts")
            } footer: {
                Text("Een layout onthoudt waar de vensters van alle open apps staan. Automatisch toepassen gebeurt als deze schermopstelling actief wordt, bijvoorbeeld bij het aansluiten van een monitor.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Huidige indeling opslaan") {
                    layouts.saveCurrentLayout()
                }
                LabeledContent("Huidige schermen", value: layouts.currentSetup.summary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct LayoutRow: View {
    let layout: Layout
    let layouts: LayoutService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Naam", text: Binding(
                    get: { layout.name },
                    set: { layouts.store.rename(layout.id, to: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.headline)

                Button("Toepassen") {
                    layouts.apply(layout)
                }
                .disabled(!layouts.canApply(layout))
                .help(layouts.canApply(layout) ? "" : "Gemaakt voor andere schermen")

                Button {
                    layouts.store.remove(layout.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Verwijderen")
            }

            Text("\(layout.windows.count) vensters · \(layout.screenSetup.summary)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Automatisch toepassen bij deze schermen", isOn: Binding(
                get: { layout.appliesAutomatically },
                set: { layouts.store.setAppliesAutomatically($0, for: layout.id) }
            ))
            .controlSize(.small)
        }
        .padding(.vertical, 2)
    }
}
