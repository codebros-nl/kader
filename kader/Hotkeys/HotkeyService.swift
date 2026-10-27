import KeyboardShortcuts

/// Koppelt de globale sneltoetsen uit KeyboardShortcuts aan een `WindowAction`.
/// Werkt zonder Accessibility-toestemming; die is alleen nodig om het venster daarna te verplaatsen.
@MainActor
final class HotkeyService {
    private let onAction: (WindowAction) -> Void

    init(onAction: @escaping (WindowAction) -> Void) {
        self.onAction = onAction
    }

    /// Eén keer aanroepen bij het opstarten. Wijzigingen in de instellingen worden
    /// door KeyboardShortcuts zelf opnieuw geregistreerd.
    func registerAll() {
        for action in WindowAction.allCases {
            KeyboardShortcuts.onKeyDown(for: action.shortcutName) { [weak self] in
                self?.onAction(action)
            }
        }
    }
}
