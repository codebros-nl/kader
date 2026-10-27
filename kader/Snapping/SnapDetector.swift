import AppKit
import ApplicationServices

/// Herkent het slepen van een venster naar een schermrand of hoek, toont een preview
/// en snapt het venster bij loslaten. Met Shift ingedrukt worden de eigen zones getoond.
@MainActor
final class SnapDetector {
    /// Waar het venster terechtkomt als het nu wordt losgelaten.
    private enum Target: Equatable {
        case edge(SnapArea.Snap)
        case zone(index: Int, frame: CGRect)
    }

    private enum State {
        case idle
        /// Muisknop ingedrukt; nog onbekend of er een venster wordt gesleept.
        case pressed(location: CGPoint)
        /// Er wordt gesleept boven een venster; wachten tot blijkt of het venster meebeweegt.
        case candidate(window: AXUIElement, frame: CGRect, checks: Int)
        /// Het venster wordt verplaatst.
        case dragging(window: AXUIElement, originalFrame: CGRect, target: Target?)
        /// Geen vensterverplaatsing (tekst selecteren, formaat wijzigen): negeren tot loslaten.
        case ignored
    }

    /// Na zoveel sleep-events zonder vensterbeweging is het geen vensterverplaatsing.
    private static let maxCandidateChecks = 10

    private let windowManager: WindowManager
    private let isEnabled: () -> Bool
    private let allowsWindow: (AXUIElement) -> Bool
    private let preview = SnapPreview()
    private let zoneOverlay = ZoneOverlay()
    private var state = State.idle
    private var monitor: Any?

    /// - Parameters:
    ///   - isEnabled: Wordt bij elke muisklik opnieuw gelezen, zodat de instelling direct werkt.
    ///   - allowsWindow: Of een venster mag snappen, bijvoorbeeld niet als de app wordt genegeerd.
    init(
        windowManager: WindowManager,
        isEnabled: @escaping () -> Bool,
        allowsWindow: @escaping (AXUIElement) -> Bool
    ) {
        self.windowManager = windowManager
        self.isEnabled = isEnabled
        self.allowsWindow = allowsWindow
    }

    func start() {
        guard monitor == nil else { return }

        // Een globale monitor ziet alleen events van andere apps, precies wat hier nodig is.
        // flagsChanged zorgt dat Shift indrukken of loslaten direct werkt, ook zonder de muis te bewegen.
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .flagsChanged]
        ) { [weak self] event in
            let type = event.type
            let isShiftDown = event.modifierFlags.contains(.shift)
            MainActor.assumeIsolated {
                self?.handle(type, isShiftDown: isShiftDown)
            }
        }
    }

    private func handle(_ type: NSEvent.EventType, isShiftDown: Bool) {
        switch type {
        case .leftMouseDown:
            hideOverlays()
            state = isEnabled() ? .pressed(location: windowManager.cursorLocation()) : .idle
        case .leftMouseDragged:
            dragged(to: windowManager.cursorLocation(), isShiftDown: isShiftDown)
        case .flagsChanged:
            if case .dragging = state {
                updateTarget(at: windowManager.cursorLocation(), isShiftDown: isShiftDown)
            }
        case .leftMouseUp:
            released()
        default:
            break
        }
    }

    private func dragged(to location: CGPoint, isShiftDown: Bool) {
        switch state {
        case .pressed(let start):
            // Pas bij de eerste sleepbeweging het venster opzoeken, niet bij elke gewone klik.
            guard
                let window = windowManager.window(at: start),
                allowsWindow(window),
                let frame = windowManager.frame(of: window)
            else {
                state = .ignored
                return
            }
            state = .candidate(window: window, frame: frame, checks: 0)

        case let .candidate(window, frame, checks):
            guard let current = windowManager.frame(of: window), current.size == frame.size else {
                // Andere grootte betekent formaat wijzigen, geen verplaatsen.
                state = .ignored
                return
            }
            if current.origin != frame.origin {
                state = .dragging(window: window, originalFrame: frame, target: nil)
                updateTarget(at: location, isShiftDown: isShiftDown)
            } else if checks + 1 >= Self.maxCandidateChecks {
                state = .ignored
            } else {
                state = .candidate(window: window, frame: frame, checks: checks + 1)
            }

        case .dragging:
            updateTarget(at: location, isShiftDown: isShiftDown)

        case .idle, .ignored:
            break
        }
    }

    private func updateTarget(at location: CGPoint, isShiftDown: Bool) {
        guard case let .dragging(window, originalFrame, currentTarget) = state else { return }
        let screens = windowManager.currentScreens()

        if isShiftDown && UserDefaults.standard.bool(forKey: SettingsKey.zonesEnabled) {
            updateZoneTarget(at: location, in: screens, window: window, originalFrame: originalFrame, current: currentTarget)
            return
        }
        zoneOverlay.hide()

        let target = SnapArea.snap(at: location, in: screens) { SnapBehavior.current(for: $0) }.map(Target.edge)
        guard target != currentTarget else { return }
        state = .dragging(window: window, originalFrame: originalFrame, target: target)

        if case .edge(let snap) = target, let frame = ScreenGeometry.targetFrame(
            for: snap.action,
            currentFrame: originalFrame,
            visibleFrame: snap.screen.visibleFrame,
            gap: windowManager.windowGap
        ) {
            preview.show(frame)
        } else {
            preview.hide()
        }
    }

    private func updateZoneTarget(
        at location: CGPoint,
        in screens: [ScreenGeometry.Screen],
        window: AXUIElement,
        originalFrame: CGRect,
        current: Target?
    ) {
        preview.hide()
        guard let screen = ScreenGeometry.screen(containing: location, in: screens) else {
            zoneOverlay.hide()
            return
        }

        let area = screen.visibleFrame
        let grid = ZoneGrid.current()
        let frames = grid.frames(in: area, gap: windowManager.windowGap)
        let index = grid.zoneIndex(at: location, in: area)
        let target = index.map { Target.zone(index: $0, frame: frames[$0]) }

        // Ook bij dezelfde zone opnieuw tekenen: de overlay kan net verschenen zijn na Shift indrukken.
        zoneOverlay.show(zones: frames, in: area, highlighted: index)
        if target != current {
            state = .dragging(window: window, originalFrame: originalFrame, target: target)
        }
    }

    private func released() {
        if case let .dragging(window, originalFrame, target?) = state {
            switch target {
            case .edge(let snap):
                windowManager.perform(snap.action, on: window, screen: snap.screen, originalFrame: originalFrame)
            case .zone(_, let frame):
                windowManager.place(window, at: frame, originalFrame: originalFrame)
            }
        }
        hideOverlays()
        state = .idle
    }

    private func hideOverlays() {
        preview.hide()
        zoneOverlay.hide()
    }
}
