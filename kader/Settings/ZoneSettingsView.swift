import SwiftUI

struct ZoneSettingsView: View {
    @AppStorage(SettingsKey.zonesEnabled) private var zonesEnabled = true
    @AppStorage(SettingsKey.zoneColumns) private var columns = ZoneGrid.defaultPreset.columns
    @AppStorage(SettingsKey.zoneRows) private var rows = ZoneGrid.defaultPreset.rows

    private var grid: ZoneGrid? { ZoneGrid(columns: columns, rows: rows) }

    var body: some View {
        Form {
            Toggle("Eigen zones tonen door tijdens het slepen Shift ingedrukt te houden", isOn: $zonesEnabled)

            Section {
                Picker("Voorbeeldindeling", selection: Binding(
                    get: { ZoneGrid.presets.first { $0.columns == columns && $0.rows == rows }?.id ?? "" },
                    set: { id in
                        guard let preset = ZoneGrid.presets.first(where: { $0.id == id }) else { return }
                        columns = preset.columns
                        rows = preset.rows
                    }
                )) {
                    Text("Eigen indeling").tag("")
                    ForEach(ZoneGrid.presets) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                }

                TextField("Kolommen (%)", text: $columns, prompt: Text("25, 50, 25"))
                TextField("Rijen (%)", text: $rows, prompt: Text("100"))

                if let grid {
                    ZonePreview(grid: grid)
                        .frame(height: 160)
                        .padding(.vertical, 4)
                } else {
                    Text("Gebruik getallen gescheiden door komma's, bijvoorbeeld 25, 50, 25.")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Zones")
            } footer: {
                Text("Verhoudingen hoeven niet op te tellen tot 100; ze worden naar het scherm geschaald. De marge uit Algemeen geldt ook voor zones.")
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
                            Text("\(index + 1)")
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
