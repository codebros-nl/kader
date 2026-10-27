import KeyboardShortcuts
import Testing
@testable import kader

@MainActor
struct ShortcutTests {
    @Test func everyActionHasAnInitialShortcut() {
        for action in WindowAction.allCases {
            #expect(action.shortcutName.initialShortcut != nil, "Geen beginwaarde voor \(action.rawValue)")
        }
    }

    @Test func initialShortcutsAreUnique() {
        let shortcuts = WindowAction.allCases.compactMap(\.shortcutName.initialShortcut)
        #expect(Set(shortcuts).count == shortcuts.count)
    }

    @Test func everyActionAppearsInExactlyOneGroup() {
        let grouped = WindowAction.groups.flatMap { $0 }
        #expect(grouped.count == WindowAction.allCases.count)
        #expect(Set(grouped) == Set(WindowAction.allCases))
    }
}
