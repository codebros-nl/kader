import AppKit
import ApplicationServices
import Observation

/// Beheert de Accessibility-toestemming die Kader nodig heeft
/// om vensters van andere apps te verplaatsen en te schalen.
@MainActor
@Observable
final class AccessibilityPermission {
    private(set) var isGranted: Bool = AXIsProcessTrusted()

    @ObservationIgnored
    private var pollTask: Task<Void, Never>?

    init() {
        if !isGranted {
            startPolling()
        }
    }

    /// Toont de systeemprompt van macOS die naar Systeeminstellingen verwijst.
    func request() {
        // String-literal i.p.v. kAXTrustedCheckOptionPrompt voorkomt Swift 6 concurrency-fouten.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        isGranted = AXIsProcessTrustedWithOptions(options)

        if !isGranted {
            startPolling()
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// macOS stuurt geen notificatie bij het verlenen van toestemming, dus we pollen elke seconde.
    private func startPolling() {
        guard pollTask == nil else { return }

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if self.refresh() { return }
            }
        }
    }

    @discardableResult
    private func refresh() -> Bool {
        isGranted = AXIsProcessTrusted()
        if isGranted {
            pollTask = nil
        }
        return isGranted
    }
}
