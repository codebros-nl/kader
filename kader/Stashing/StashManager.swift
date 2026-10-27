import AppKit
import ApplicationServices
import os

/// Parkeert vensters tegen de linker- of rechterrand met alleen een smalle strook in beeld.
/// Met de cursor tegen de rand schuift een geparkeerd venster uit; weg met de cursor schuift het terug.
@MainActor
final class StashManager {
    fileprivate struct StashedWindow {
        let window: AXUIElement
        let edge: StashEdge
        var screen: ScreenGeometry.Screen
        /// Frame van vóór het parkeren, voor terugzetten.
        let originalFrame: CGRect
        var stashedFrame: CGRect
        /// Bijgewerkt na uitschuiven naar het frame dat het venster werkelijk kreeg.
        var revealedFrame: CGRect
        var isRevealed = false
    }

    private let windowManager: WindowManager
    private let logger = Logger(subsystem: "nl.codebros.kader", category: "StashManager")
    private var stashed: [StashedWindow] = []
    private var monitor: Any?
    private var screenObserver: NSObjectProtocol?

    init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.cursorMoved()
            }
        }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.restashAll()
            }
        }
    }

    /// Het frame van vóór het parkeren, of nil als het venster niet geparkeerd is.
    /// Layouts gebruiken dit, zodat ze nooit een plek buiten beeld vastleggen.
    func originalFrame(ofStashed window: AXUIElement) -> CGRect? {
        stashed.first { CFEqual($0.window, window) }?.originalFrame
    }

    /// Parkeert het gefocuste venster. Is het al geparkeerd, dan wordt het teruggezet.
    func toggleStash(_ edge: StashEdge) {
        guard let window = windowManager.focusedWindow() else {
            logger.info("Geen gefocust venster om te parkeren")
            return
        }

        if let index = stashed.firstIndex(where: { CFEqual($0.window, window) }) {
            unstash(at: index)
            return
        }

        guard
            let frame = windowManager.frame(of: window),
            let screen = StashGeometry.screen(for: edge, in: windowManager.currentScreens())
        else {
            return
        }

        var entry = StashedWindow(
            window: window,
            edge: edge,
            screen: screen,
            originalFrame: frame,
            stashedFrame: .zero,
            revealedFrame: .zero
        )
        entry.place(on: screen)
        windowManager.setFrame(entry.stashedFrame, of: window)
        stashed.append(entry)
    }

    /// Na een monitorwissel opnieuw parkeren aan de buitenrand van de huidige schermen;
    /// anders blijft een venster op de plek van een losgekoppelde monitor staan.
    private func restashAll() {
        let screens = windowManager.currentScreens()
        for index in stashed.indices.reversed() {
            guard let screen = StashGeometry.screen(for: stashed[index].edge, in: screens) else {
                unstash(at: index)
                continue
            }
            stashed[index].place(on: screen)
            stashed[index].isRevealed = false
            windowManager.setFrame(stashed[index].stashedFrame, of: stashed[index].window)
        }
    }

    /// Zet alle geparkeerde vensters terug op hun oude plek, ook bij het afsluiten van Kader.
    func unstashAll() {
        for index in stashed.indices.reversed() {
            unstash(at: index)
        }
    }

    private func unstash(at index: Int) {
        let entry = stashed.remove(at: index)
        let frame = StashGeometry.unstashFrame(
            original: entry.originalFrame,
            fallback: entry.revealedFrame,
            screens: windowManager.currentScreens()
        )
        windowManager.setFrame(frame, of: entry.window)
    }

    // MARK: - Uitschuiven en terugschuiven

    private func cursorMoved() {
        guard !stashed.isEmpty else { return }
        let cursor = windowManager.cursorLocation()

        if let index = stashed.firstIndex(where: \.isRevealed) {
            if StashGeometry.shouldHide(cursor: cursor, revealedFrame: stashed[index].revealedFrame) {
                hide(at: index)
            }
            return
        }

        // Het laatst geparkeerde venster ligt bovenop, dus achteraan beginnen.
        if let index = stashed.indices.last(where: {
            StashGeometry.shouldReveal(
                cursor: cursor,
                stashedFrame: stashed[$0].stashedFrame,
                edge: stashed[$0].edge,
                on: stashed[$0].screen
            )
        }) {
            reveal(at: index)
        }
    }

    private func reveal(at index: Int) {
        let entry = stashed[index]
        guard windowManager.frame(of: entry.window) != nil else {
            // Venster is gesloten.
            stashed.remove(at: index)
            return
        }
        windowManager.setFrame(entry.revealedFrame, of: entry.window)
        windowManager.raise(entry.window)
        stashed[index].revealedFrame = windowManager.frame(of: entry.window) ?? entry.revealedFrame
        stashed[index].isRevealed = true
    }

    private func hide(at index: Int) {
        let entry = stashed[index]
        guard let current = windowManager.frame(of: entry.window) else {
            stashed.remove(at: index)
            return
        }
        // Zelf verplaatst of van formaat veranderd: dan is het venster niet meer geparkeerd.
        guard current == entry.revealedFrame else {
            stashed.remove(at: index)
            return
        }
        windowManager.setFrame(entry.stashedFrame, of: entry.window)
        stashed[index].isRevealed = false
    }
}

private extension StashManager.StashedWindow {
    /// Berekent de geparkeerde en uitgeschoven plek op een scherm, op basis van het oorspronkelijke formaat.
    mutating func place(on newScreen: ScreenGeometry.Screen) {
        screen = newScreen
        stashedFrame = StashGeometry.stashedFrame(for: originalFrame, edge: edge, on: newScreen)
        revealedFrame = StashGeometry.revealedFrame(for: originalFrame, edge: edge, on: newScreen)
    }
}
