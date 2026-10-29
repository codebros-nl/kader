import Foundation
import Testing

/// Controleert de String Catalog: elke tekst heeft een Nederlandse vertaling en er staan geen
/// ongebruikte teksten in. Nieuwe teksten komen in de catalogus via een build in Xcode of
/// `scripts/sync-strings.sh`.
struct LocalizationTests {
    private struct Catalog: Decodable {
        var strings: [String: Entry]
    }

    private struct Entry: Decodable {
        var shouldTranslate: Bool?
        var extractionState: String?
        var localizations: [String: Localization]?
    }

    private struct Localization: Decodable {
        var stringUnit: StringUnit?
    }

    private struct StringUnit: Decodable {
        var state: String
    }

    private static let catalogURL = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "kader/Localizable.xcstrings")

    private func loadCatalog() throws -> Catalog {
        try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: Self.catalogURL))
    }

    @Test func everyStringHasDutchTranslation() throws {
        let missing = try loadCatalog().strings
            .filter { $0.value.shouldTranslate != false }
            .filter { $0.value.localizations?["nl"]?.stringUnit?.state != "translated" }
            .map(\.key)
            .sorted()
        #expect(missing.isEmpty, "Geen Nederlandse vertaling voor: \(missing)")
    }

    @Test func noStaleStrings() throws {
        let stale = try loadCatalog().strings
            .filter { $0.value.extractionState == "stale" }
            .map(\.key)
            .sorted()
        #expect(stale.isEmpty, "Niet meer gebruikt in de code: \(stale)")
    }
}
