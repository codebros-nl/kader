import AppKit
import KeyboardShortcuts

extension WindowAction {
    /// Naam waaronder KeyboardShortcuts de sneltoets voor deze actie opslaat in `UserDefaults`.
    var shortcutName: KeyboardShortcuts.Name {
        Self.shortcutNames[self, default: KeyboardShortcuts.Name(rawValue)]
    }

    /// Eén keer aangemaakt, omdat elke `Name` bij het aanmaken zijn beginwaarde registreert.
    private static let shortcutNames = Dictionary(
        uniqueKeysWithValues: allCases.map { ($0, KeyboardShortcuts.Name($0.rawValue, initial: $0.initialShortcut)) }
    )

    /// Beginwaarden zoals Magnet: Ctrl+Option+toets, met Command erbij voor ander scherm.
    private var initialShortcut: KeyboardShortcuts.Shortcut {
        let modifiers: NSEvent.ModifierFlags = [.control, .option]

        switch self {
        case .leftHalf: return .init(.leftArrow, modifiers: modifiers)
        case .rightHalf: return .init(.rightArrow, modifiers: modifiers)
        case .topHalf: return .init(.upArrow, modifiers: modifiers)
        case .bottomHalf: return .init(.downArrow, modifiers: modifiers)
        case .topLeft: return .init(.u, modifiers: modifiers)
        case .topRight: return .init(.i, modifiers: modifiers)
        case .bottomLeft: return .init(.j, modifiers: modifiers)
        case .bottomRight: return .init(.k, modifiers: modifiers)
        case .firstThird: return .init(.d, modifiers: modifiers)
        case .centerThird: return .init(.f, modifiers: modifiers)
        case .lastThird: return .init(.g, modifiers: modifiers)
        case .firstTwoThirds: return .init(.e, modifiers: modifiers)
        case .lastTwoThirds: return .init(.t, modifiers: modifiers)
        case .maximize: return .init(.return, modifiers: modifiers)
        case .center: return .init(.c, modifiers: modifiers)
        case .restore: return .init(.delete, modifiers: modifiers)
        case .nextScreen: return .init(.rightArrow, modifiers: modifiers.union(.command))
        case .previousScreen: return .init(.leftArrow, modifiers: modifiers.union(.command))
        }
    }
}
