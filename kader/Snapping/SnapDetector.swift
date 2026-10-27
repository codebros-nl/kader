import AppKit
import ApplicationServices

/// Herkent het slepen van een venster naar een schermrand of hoek, toont een preview
/// en snapt het venster bij loslaten.
@MainActor
final class SnapDetector {
    private enum State {
        case idle
        /// Muisknop ingedrukt; nog onbekend of er een venster wordt gesleept.
        case pressed(location: CGPoint)
        /// Er wordt gesleept boven een venster; wachten tot blijkt of het venster meebeweegt.
        case candidate(window: AXUIElement, frame: CGRect, checks: Int)
        /// Het venster wordt verplaatst.
        case dragging(window: AXUIElement, originalFrame: CGRect, snap: SnapArea.Snap?)
        /// Geen vensterverplaatsing (tekst selecteren, formaat wijzigen): negeren tot loslaten.
        case ignored
    }

    /// Na zoveel sleep-events zonder vensterbeweging is het geen vensterverplaatsing.
    private static let maxCandidateChecks = 10

    private let windowManager: WindowManager
    private let isEnabled: () -> Bool
    private let allowsWindow: (AXUIElement) -> Bool
    private let preview = SnapPreview()
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
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            let type = event.type
            MainActor.assumeIsolated {
                self?.handle(type)
            }
        }
    }

    private func handle(_ type: NSEvent.EventType) {
        switch type {
        case .leftMouseDown:
            preview.hide()
            state = isEnabled() ? .pressed(location: windowManager.cursorLocation()) : .idle
        case .leftMouseDragged:
            dragged(to: windowManager.cursorLocation())
        case .leftMouseUp:
            released()
        default:
            break
        }
    }

    private func dragged(to location: CGPoint) {
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
                state = .dragging(window: window, originalFrame: frame, snap: nil)
                updateSnap(at: location)
            } else if checks + 1 >= Self.maxCandidateChecks {
                state = .ignored
            } else {
                state = .candidate(window: window, frame: frame, checks: checks + 1)
            }

        case .dragging:
            updateSnap(at: location)

        case .idle, .ignored:
            break
        }
    }

    private func updateSnap(at location: CGPoint) {
        guard case let .dragging(window, originalFrame, currentSnap) = state else { return }

        let snap = SnapArea.snap(at: location, in: windowManager.currentScreens()) {
            SnapBehavior.current(for: $0)
        }
        guard snap != currentSnap else { return }
        state = .dragging(window: window, originalFrame: originalFrame, snap: snap)

        if let snap, let frame = ScreenGeometry.targetFrame(
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

    private func released() {
        if case let .dragging(window, originalFrame, snap?) = state {
            windowManager.perform(snap.action, on: window, screen: snap.screen, originalFrame: originalFrame)
        }
        preview.hide()
        state = .idle
    }
}
