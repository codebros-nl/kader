import CoreGraphics
import Foundation

/// Een opgeslagen indeling van vensters voor één schermopstelling.
nonisolated struct Layout: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var screenSetup: ScreenSetup
    var windows: [WindowPlacement]
    /// Automatisch toepassen zodra deze schermopstelling actief wordt.
    var appliesAutomatically = false
}

/// Plek van één venster binnen een layout. Frames in Accessibility-coördinaten.
nonisolated struct WindowPlacement: Codable, Hashable, Sendable {
    var bundleIdentifier: String
    var title: String
    var frame: CGRect
}

/// Herkenbare schermopstelling: de schermframes, gesorteerd van links naar rechts.
/// Twee opstellingen zijn gelijk als dezelfde schermen op dezelfde plek staan.
nonisolated struct ScreenSetup: Codable, Hashable, Sendable {
    var screenFrames: [CGRect]

    init(screenFrames: [CGRect]) {
        self.screenFrames = screenFrames.sorted { ($0.minX, $0.minY) < ($1.minX, $1.minY) }
    }

    init(screens: [ScreenGeometry.Screen]) {
        self.init(screenFrames: screens.map(\.frame))
    }

    /// Bijvoorbeeld "1440×900 + 1920×1080".
    var summary: String {
        screenFrames
            .map { "\(Int($0.width))×\(Int($0.height))" }
            .joined(separator: " + ")
    }
}
