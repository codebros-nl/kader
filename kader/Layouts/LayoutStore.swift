import Foundation
import Observation
import os

/// Bewaart layouts als JSON in Application Support.
@MainActor
@Observable
final class LayoutStore {
    private(set) var layouts: [Layout] = []

    @ObservationIgnored
    private let fileURL: URL
    @ObservationIgnored
    private let logger = Logger(subsystem: "nl.codebros.kader", category: "LayoutStore")

    static let defaultFileURL = URL.applicationSupportDirectory
        .appending(path: "nl.codebros.kader", directoryHint: .isDirectory)
        .appending(path: "layouts.json")

    init(fileURL: URL = LayoutStore.defaultFileURL) {
        self.fileURL = fileURL
        load()
    }

    func add(_ layout: Layout) {
        layouts.append(layout)
        save()
    }

    func rename(_ id: Layout.ID, to name: String) {
        guard let index = layouts.firstIndex(where: { $0.id == id }) else { return }
        layouts[index].name = name
        save()
    }

    func remove(_ id: Layout.ID) {
        layouts.removeAll { $0.id == id }
        save()
    }

    /// Per schermopstelling kan maar één layout automatisch worden toegepast.
    func setAppliesAutomatically(_ enabled: Bool, for id: Layout.ID) {
        guard let index = layouts.firstIndex(where: { $0.id == id }) else { return }
        if enabled {
            let setup = layouts[index].screenSetup
            for other in layouts.indices where layouts[other].screenSetup == setup {
                layouts[other].appliesAutomatically = false
            }
        }
        layouts[index].appliesAutomatically = enabled
        save()
    }

    func automaticLayout(for setup: ScreenSetup) -> Layout? {
        layouts.first { $0.appliesAutomatically && $0.screenSetup == setup }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            layouts = try JSONDecoder().decode([Layout].self, from: Data(contentsOf: fileURL))
        } catch {
            logger.error("Layouts laden mislukt: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(layouts).write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Layouts opslaan mislukt: \(error.localizedDescription, privacy: .public)")
        }
    }
}
