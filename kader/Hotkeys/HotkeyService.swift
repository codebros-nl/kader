import Carbon.HIToolbox
import os

/// Viertekenige signatuur 'KADR' waarmee Kader zijn eigen hotkey-events herkent.
nonisolated private let hotkeySignature: OSType = 0x4B41_4452

/// Registreert globale sneltoetsen via de Carbon hotkey-API en koppelt ze aan een `WindowAction`.
/// Werkt zonder Accessibility-toestemming; die is alleen nodig om het venster daarna te verplaatsen.
@MainActor
final class HotkeyService {
    private let logger = Logger(subsystem: "nl.codebros.kader", category: "HotkeyService")
    private let onAction: (WindowAction) -> Void

    private var handlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var actionsByID: [UInt32: WindowAction] = [:]

    init(onAction: @escaping (WindowAction) -> Void) {
        self.onAction = onAction
    }

    func register(_ hotkeys: [Hotkey]) {
        unregisterAll()
        installHandlerIfNeeded()

        for (index, hotkey) in hotkeys.enumerated() {
            let id = UInt32(index + 1)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                hotkey.keyCode,
                Hotkey.carbonModifiers,
                EventHotKeyID(signature: hotkeySignature, id: id),
                GetApplicationEventTarget(),
                0,
                &ref
            )
            guard status == noErr, let ref else {
                // Meestal bezet door een andere app (bijvoorbeeld Magnet).
                logger.error("Sneltoets voor \(hotkey.action.rawValue, privacy: .public) niet geregistreerd (status \(status))")
                continue
            }
            hotKeyRefs.append(ref)
            actionsByID[id] = hotkey.action
        }
    }

    func unregisterAll() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        actionsByID.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        // De service leeft net zo lang als de app, dus een unretained pointer is veilig.
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(GetApplicationEventTarget(), hotkeyEventHandler, 1, &eventType, userData, &handlerRef)
        if status != noErr {
            logger.error("Event handler voor sneltoetsen niet geïnstalleerd (status \(status))")
        }
    }

    fileprivate func handle(id: UInt32) {
        guard let action = actionsByID[id] else { return }
        onAction(action)
    }
}

/// C-callback voor Carbon. De application event target levert events af op de main thread.
nonisolated private func hotkeyEventHandler(
    _ callRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, hotKeyID.signature == hotkeySignature else {
        return OSStatus(eventNotHandledErr)
    }

    let id = hotKeyID.id
    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
    MainActor.assumeIsolated {
        service.handle(id: id)
    }
    return noErr
}
