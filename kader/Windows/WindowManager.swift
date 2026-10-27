import AppKit
import ApplicationServices
import os

/// Wrapper rond de Accessibility API: het gefocuste venster van een andere app ophalen,
/// het frame lezen en het frame zetten.
@MainActor
final class WindowManager {
    private let logger = Logger(subsystem: "nl.codebros.kader", category: "WindowManager")
    private var cycle = ActionCycle<AXUIElement>()
    private var history = FrameHistory<AXUIElement>()

    func perform(_ action: WindowAction) {
        guard let window = focusedWindow() else {
            logger.info("Geen gefocust venster gevonden voor \(action.rawValue, privacy: .public)")
            return
        }
        guard let currentFrame = frame(of: window) else {
            logger.info("Frame van het gefocuste venster is niet leesbaar")
            return
        }
        let screens = currentScreens()
        guard let screen = ScreenGeometry.screen(for: currentFrame, in: screens) else {
            logger.error("Geen scherm gevonden")
            return
        }

        var step = 0
        let target: CGRect?
        switch action {
        case .restore:
            target = history.takeRestoreFrame(for: window)
        case .nextScreen, .previousScreen:
            let offset = action == .nextScreen ? 1 : -1
            target = ScreenGeometry.screen(offsetBy: offset, from: screen, in: screens).map {
                ScreenGeometry.frame(currentFrame, movedFrom: screen.visibleFrame, to: $0.visibleFrame)
            }
        default:
            step = cycle.step(for: action, window: window, currentFrame: currentFrame)
            target = ScreenGeometry.targetFrame(
                for: action,
                step: step,
                currentFrame: currentFrame,
                visibleFrame: screen.visibleFrame,
                gap: windowGap
            )
        }

        guard let target else {
            logger.info("Niets te doen voor \(action.rawValue, privacy: .public)")
            return
        }

        if action != .restore {
            history.willMove(window, from: currentFrame)
        }
        setFrame(target, of: window)

        // Het venster kan het doelframe hebben bijgesteld (minimale grootte), dus terug uitlezen.
        let resultingFrame = frame(of: window) ?? target
        if action != .restore {
            history.didMove(window, to: resultingFrame)
        }
        cycle.record(action, step: step, window: window, resultingFrame: resultingFrame)
    }

    private var windowGap: CGFloat {
        max(0, UserDefaults.standard.double(forKey: SettingsKey.windowGap))
    }

    // MARK: - Venster ophalen

    private func focusedWindow() -> AXUIElement? {
        guard
            let app = NSWorkspace.shared.frontmostApplication,
            app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        guard
            let value = copyAttribute(kAXFocusedWindowAttribute, of: appElement),
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    private func currentScreens() -> [ScreenGeometry.Screen] {
        let cocoaScreens = NSScreen.screens.map {
            ScreenGeometry.Screen(frame: $0.frame, visibleFrame: $0.visibleFrame)
        }
        return ScreenGeometry.accessibilityScreens(fromCocoa: cocoaScreens)
    }

    // MARK: - Frame lezen en zetten

    private func frame(of window: AXUIElement) -> CGRect? {
        guard
            let positionValue = axValue(kAXPositionAttribute, of: window),
            let sizeValue = axValue(kAXSizeAttribute, of: window)
        else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard
            AXValueGetValue(positionValue, .cgPoint, &position),
            AXValueGetValue(sizeValue, .cgSize, &size)
        else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    /// Eerst grootte, dan positie, dan nog eens grootte: zo komen ook vensters met een
    /// minimale grootte of een scherm-afhankelijke maximale grootte goed terecht (aanpak van Rectangle).
    private func setFrame(_ frame: CGRect, of window: AXUIElement) {
        setSize(frame.size, of: window)
        setPosition(frame.origin, of: window)
        setSize(frame.size, of: window)
    }

    private func setSize(_ size: CGSize, of window: AXUIElement) {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        setAttribute(kAXSizeAttribute, value: value, of: window)
    }

    private func setPosition(_ position: CGPoint, of window: AXUIElement) {
        var position = position
        guard let value = AXValueCreate(.cgPoint, &position) else { return }
        setAttribute(kAXPositionAttribute, value: value, of: window)
    }

    // MARK: - AX-hulpfuncties

    private func copyAttribute(_ attribute: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success else {
            logger.debug("Lezen van \(attribute, privacy: .public) mislukt: \(error.rawValue)")
            return nil
        }
        return value
    }

    private func axValue(_ attribute: String, of element: AXUIElement) -> AXValue? {
        guard let value = copyAttribute(attribute, of: element), CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }
        return unsafeDowncast(value, to: AXValue.self)
    }

    private func setAttribute(_ attribute: String, value: AXValue, of element: AXUIElement) {
        let error = AXUIElementSetAttributeValue(element, attribute as CFString, value)
        if error != .success {
            logger.debug("Zetten van \(attribute, privacy: .public) mislukt: \(error.rawValue)")
        }
    }
}
