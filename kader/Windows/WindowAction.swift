import Foundation

/// Alle acties die Kader op een venster kan uitvoeren, los van hoe ze worden aangeroepen.
nonisolated enum WindowAction: String, CaseIterable, Identifiable, Sendable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case firstThird
    case centerThird
    case lastThird
    case firstTwoThirds
    case lastTwoThirds
    case maximize
    case center
    case nextScreen
    case previousScreen
    case restore
    case stashLeft
    case stashRight
    case unstashAll

    /// Indeling in groepen voor het menu en de instellingen.
    static let groups: [[WindowAction]] = [
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.firstThird, .centerThird, .lastThird, .firstTwoThirds, .lastTwoThirds],
        [.maximize, .center, .restore],
        [.nextScreen, .previousScreen],
        [.stashLeft, .stashRight, .unstashAll],
    ]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leftHalf: String(localized: "Left Half")
        case .rightHalf: String(localized: "Right Half")
        case .topHalf: String(localized: "Top Half")
        case .bottomHalf: String(localized: "Bottom Half")
        case .topLeft: String(localized: "Top Left")
        case .topRight: String(localized: "Top Right")
        case .bottomLeft: String(localized: "Bottom Left")
        case .bottomRight: String(localized: "Bottom Right")
        case .firstThird: String(localized: "First Third")
        case .centerThird: String(localized: "Center Third")
        case .lastThird: String(localized: "Last Third")
        case .firstTwoThirds: String(localized: "First Two Thirds")
        case .lastTwoThirds: String(localized: "Last Two Thirds")
        case .maximize: String(localized: "Maximize")
        case .center: String(localized: "Center")
        case .nextScreen: String(localized: "Next Display")
        case .previousScreen: String(localized: "Previous Display")
        case .restore: String(localized: "Restore")
        case .stashLeft: String(localized: "Stash Left")
        case .stashRight: String(localized: "Stash Right")
        case .unstashAll: String(localized: "Unstash All Windows")
        }
    }

    /// Aantal stappen bij herhaald drukken: helften lopen door ½ → ⅓ → ⅔.
    var cycleLength: Int {
        switch self {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf: 3
        default: 1
        }
    }
}
