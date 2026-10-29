import SwiftUI

struct ZoneSettingsView: View {
    @AppStorage(SettingsKey.zonesEnabled) private var zonesEnabled = true
    @AppStorage(SettingsKey.zoneColumns) private var columns = ZoneGrid.defaultPreset.columns
    @AppStorage(SettingsKey.zoneRows) private var rows = ZoneGrid.defaultPreset.rows

    private var grid: ZoneGrid? { ZoneGrid(columns: columns, rows: rows) }

    var body: some View {
        Form {
            Toggle("Show custom zones by holding Shift while dragging", isOn: $zonesEnabled)

            Section {
                Picker("Preset", selection: Binding(
                    get: { ZoneGrid.presets.first { $0.columns == columns && $0.rows == rows }?.id ?? "" },
                    set: { id in
                        guard let preset = ZoneGrid.presets.first(where: { $0.id == id }) else { return }
                        columns = preset.columns
                        rows = preset.rows
                    }
                )) {
                    Text("Custom").tag("")
                    ForEach(ZoneGrid.presets) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                }

                TextField("Columns (%)", text: $columns, prompt: Text(verbatim: "25, 50, 25"))
                TextField("Rows (%)", text: $rows, prompt: Text(verbatim: "100"))

                if let grid {
                    ZonePreview(grid: grid)
                        .frame(height: 160)
                        .padding(.vertical, 4)
                } else {
                    Text("Use numbers separated by commas, for example 25, 50, 25.")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Zones")
            } footer: {
                Text("Ratios don't need to add up to 100; they're scaled to the screen. The gap from General also applies to zones.")
                    .foregroundStyle(.secondary)
            }
            .disabled(!zonesEnabled)
        }
        .formStyle(.grouped)
    }
}

/// Verkleind voorbeeld van de zones op een scherm van 16:10.
private struct ZonePreview: View {
    let grid: ZoneGrid

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height * 1.6)
            let size = CGSize(width: width, height: width / 1.6)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)

                ForEach(Array(grid.unitRects.enumerated()), id: \.offset) { index, unit in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.15))
                        .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                        .overlay {
                            Text(verbatim: "\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: unit.width * size.width - 6, height: unit.height * size.height - 6)
                        .offset(x: unit.minX * size.width + 3, y: unit.minY * size.height + 3)
                }
            }
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: .infinity)
        }
    }
}
