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
        case .leftHalf: String(localized: "Left Half", comment: "Window action in the menu bar menu and shortcut settings")
        case .rightHalf: String(localized: "Right Half", comment: "Window action in the menu bar menu and shortcut settings")
        case .topHalf: String(localized: "Top Half", comment: "Window action in the menu bar menu and shortcut settings")
        case .bottomHalf: String(localized: "Bottom Half", comment: "Window action in the menu bar menu and shortcut settings")
        case .topLeft: String(localized: "Top Left", comment: "Window action in the menu bar menu and shortcut settings")
        case .topRight: String(localized: "Top Right", comment: "Window action in the menu bar menu and shortcut settings")
        case .bottomLeft: String(localized: "Bottom Left", comment: "Window action in the menu bar menu and shortcut settings")
        case .bottomRight: String(localized: "Bottom Right", comment: "Window action in the menu bar menu and shortcut settings")
        case .firstThird: String(localized: "First Third", comment: "Window action in the menu bar menu and shortcut settings")
        case .centerThird: String(localized: "Center Third", comment: "Window action in the menu bar menu and shortcut settings")
        case .lastThird: String(localized: "Last Third", comment: "Window action in the menu bar menu and shortcut settings")
        case .firstTwoThirds: String(localized: "First Two Thirds", comment: "Window action in the menu bar menu and shortcut settings")
        case .lastTwoThirds: String(localized: "Last Two Thirds", comment: "Window action in the menu bar menu and shortcut settings")
        case .maximize: String(localized: "Maximize", comment: "Window action in the menu bar menu and shortcut settings")
        case .center: String(localized: "Center", comment: "Window action in the menu bar menu and shortcut settings")
        case .nextScreen: String(localized: "Next Display", comment: "Window action in the menu bar menu and shortcut settings")
        case .previousScreen: String(localized: "Previous Display", comment: "Window action in the menu bar menu and shortcut settings")
        case .restore: String(localized: "Restore", comment: "Window action in the menu bar menu and shortcut settings")
        case .stashLeft: String(localized: "Stash Left", comment: "Window action in the menu bar menu and shortcut settings")
        case .stashRight: String(localized: "Stash Right", comment: "Window action in the menu bar menu and shortcut settings")
        case .unstashAll: String(localized: "Unstash All Windows", comment: "Window action in the menu bar menu and shortcut settings")
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
