import Carbon.HIToolbox
import SwiftUI

/// Een vaste globale sneltoets voor een vensteractie. Standaardindeling zoals Magnet: Ctrl+Option+toets.
struct Hotkey {
    let action: WindowAction
    /// Virtuele toetscode voor de Carbon hotkey-API.
    let keyCode: UInt32
    /// Dezelfde toets voor weergave in het menu.
    let keyEquivalent: KeyEquivalent

    static let carbonModifiers = UInt32(controlKey | optionKey)
    static let menuModifiers: SwiftUI.EventModifiers = [.control, .option]

    static let defaults: [Hotkey] = [
        Hotkey(action: .leftHalf, keyCode: UInt32(kVK_LeftArrow), keyEquivalent: .leftArrow),
        Hotkey(action: .rightHalf, keyCode: UInt32(kVK_RightArrow), keyEquivalent: .rightArrow),
        Hotkey(action: .topHalf, keyCode: UInt32(kVK_UpArrow), keyEquivalent: .upArrow),
        Hotkey(action: .bottomHalf, keyCode: UInt32(kVK_DownArrow), keyEquivalent: .downArrow),
        Hotkey(action: .topLeft, keyCode: UInt32(kVK_ANSI_U), keyEquivalent: "u"),
        Hotkey(action: .topRight, keyCode: UInt32(kVK_ANSI_I), keyEquivalent: "i"),
        Hotkey(action: .bottomLeft, keyCode: UInt32(kVK_ANSI_J), keyEquivalent: "j"),
        Hotkey(action: .bottomRight, keyCode: UInt32(kVK_ANSI_K), keyEquivalent: "k"),
        Hotkey(action: .maximize, keyCode: UInt32(kVK_Return), keyEquivalent: .return),
        Hotkey(action: .center, keyCode: UInt32(kVK_ANSI_C), keyEquivalent: "c"),
    ]

    static func defaultShortcut(for action: WindowAction) -> KeyboardShortcut? {
        defaults
            .first { $0.action == action }
            .map { KeyboardShortcut($0.keyEquivalent, modifiers: menuModifiers) }
    }
}
