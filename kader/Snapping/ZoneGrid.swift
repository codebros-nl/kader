import CoreGraphics
import Foundation

/// Eigen zones als raster van kolommen en rijen, in verhoudingen van het zichtbare schermgebied.
/// Pure logica; alle frames in Accessibility-coördinaten.
nonisolated struct ZoneGrid: Equatable, Sendable {
    nonisolated struct Preset: Identifiable, Sendable {
        var name: String
        var columns: String
        var rows: String
        var id: String { name }
    }

    static let presets: [Preset] = [
        Preset(name: String(localized: "Focus in the Middle"), columns: "25, 50, 25", rows: "100"),
        Preset(name: String(localized: "Three Columns"), columns: "33, 34, 33", rows: "100"),
        Preset(name: String(localized: "Four Columns"), columns: "25, 25, 25, 25", rows: "100"),
        Preset(name: String(localized: "Main Window and Sidebar"), columns: "65, 35", rows: "100"),
        Preset(name: String(localized: "Grid 2 × 2"), columns: "50, 50", rows: "50, 50"),
        Preset(name: String(localized: "Grid 3 × 2"), columns: "33, 34, 33", rows: "50, 50"),
    ]

    static let defaultPreset = presets[0]

    /// Breedtes en hoogtes als fracties die samen 1 zijn.
    let columns: [CGFloat]
    let rows: [CGFloat]

    init?(columns: String, rows: String) {
        guard let columns = Self.parse(columns), let rows = Self.parse(rows) else { return nil }
        self.columns = columns
        self.rows = rows
    }

    /// Leest "25, 50, 25" (komma's, puntkomma's of spaties; een % mag) als verhoudingen.
    /// Nil bij een lege of ongeldige invoer, of meer dan 12 delen.
    static func parse(_ text: String) -> [CGFloat]? {
        let parts = text
            .split(whereSeparator: { ",; ".contains($0) })
            .map { $0.replacingOccurrences(of: "%", with: "") }
        let values = parts.compactMap { Double($0) }.filter { $0 > 0 }
        guard !values.isEmpty, values.count == parts.count, values.count <= 12 else { return nil }

        let total = values.reduce(0, +)
        return values.map { CGFloat($0 / total) }
    }

    static func current(defaults: UserDefaults = .standard) -> ZoneGrid {
        let columns = defaults.string(forKey: SettingsKey.zoneColumns) ?? defaultPreset.columns
        let rows = defaults.string(forKey: SettingsKey.zoneRows) ?? defaultPreset.rows
        return ZoneGrid(columns: columns, rows: rows)
            ?? ZoneGrid(columns: defaultPreset.columns, rows: defaultPreset.rows)
            ?? ZoneGrid(columnFractions: [1], rowFractions: [1])
    }

    /// Fracties die al samen 1 zijn; alleen voor de laatste terugval naar één zone.
    private init(columnFractions: [CGFloat], rowFractions: [CGFloat]) {
        columns = columnFractions
        rows = rowFractions
    }

    /// Zones als fracties, rij voor rij van linksboven naar rechtsonder.
    var unitRects: [CGRect] {
        let columnStarts = Self.starts(of: columns)
        let rowStarts = Self.starts(of: rows)
        return rows.indices.flatMap { row in
            columns.indices.map { column in
                CGRect(x: columnStarts[column], y: rowStarts[row], width: columns[column], height: rows[row])
            }
        }
    }

    /// De zones op een scherm, met marge tussen zones en langs de rand zoals bij de vaste acties.
    func frames(in area: CGRect, gap: CGFloat) -> [CGRect] {
        unitRects.map { ScreenGeometry.frame(for: $0, in: area, gap: gap) }
    }

    /// De zone onder de cursor. Getest zonder marge, zodat er geen dode strook tussen zones zit.
    func zoneIndex(at point: CGPoint, in area: CGRect) -> Int? {
        frames(in: area, gap: 0).firstIndex { ScreenGeometry.containsInclusive($0, point) }
    }

    private static func starts(of fractions: [CGFloat]) -> [CGFloat] {
        fractions.indices.map { index in fractions[..<index].reduce(0, +) }
    }
}
