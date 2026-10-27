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
        startPolling()
    }

    /// Toont de systeemprompt van macOS die naar Systeeminstellingen verwijst.
    func request() {
        // String-literal i.p.v. kAXTrustedCheckOptionPrompt voorkomt Swift 6 concurrency-fouten.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        isGranted = AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Leest de toestemming opnieuw uit, bijvoorbeeld vlak voor een actie.
    @discardableResult
    func refresh() -> Bool {
        let granted = AXIsProcessTrusted()
        if granted != isGranted {
            isGranted = granted
        }
        return granted
    }

    /// macOS stuurt geen notificatie bij het verlenen of intrekken van toestemming, dus we pollen:
    /// elke seconde zolang die ontbreekt, daarna elke vijf seconden om intrekken op te merken.
    private func startPolling() {
        guard pollTask == nil else { return }

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                let interval: Duration = self?.isGranted == true ? .seconds(5) : .seconds(1)
                try? await Task.sleep(for: interval)
                guard let self else { return }
                refresh()
            }
        }
    }
}
