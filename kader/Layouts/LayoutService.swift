import AppKit
import Observation
import os

/// Legt de huidige indeling van alle vensters vast als layout en zet een layout terug.
/// Past een layout automatisch toe als de schermopstelling verandert.
@MainActor
@Observable
final class LayoutService {
    let store: LayoutStore
    private(set) var currentSetup: ScreenSetup

    @ObservationIgnored private let windowManager: WindowManager
    @ObservationIgnored private let excludedApps: ExcludedApps
    @ObservationIgnored private let permission: AccessibilityPermission
    @ObservationIgnored private let logger = Logger(subsystem: "nl.codebros.kader", category: "LayoutService")
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
    @ObservationIgnored private var pendingAutoApply: Task<Void, Never>?

    /// Na het aansluiten van een monitor schuift macOS zelf nog vensters rond; daarna pas toepassen.
    private static let autoApplyDelay: Duration = .seconds(2)

    init(
        store: LayoutStore,
        windowManager: WindowManager,
        excludedApps: ExcludedApps,
        permission: AccessibilityPermission
    ) {
        self.store = store
        self.windowManager = windowManager
        self.excludedApps = excludedApps
        self.permission = permission
        currentSetup = ScreenSetup(screens: windowManager.currentScreens())
    }

    func startAutoApply() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.screensDidChange()
            }
        }
    }

    // MARK: - Vastleggen

    /// Slaat de huidige indeling op als nieuwe layout voor de huidige schermopstelling.
    func saveCurrentLayout() {
        guard permission.isGranted else {
            permission.request()
            return
        }
        let layout = Layout(
            name: "Layout \(store.layouts.count + 1)",
            screenSetup: currentSetup,
            windows: captureWindows()
        )
        store.add(layout)
        logger.info("Layout opgeslagen met \(layout.windows.count) vensters")
    }

    private func captureWindows() -> [WindowPlacement] {
        layoutApps().flatMap { app, bundleIdentifier in
            windowManager.standardWindows(ofProcess: app.processIdentifier).compactMap { window in
                windowManager.frame(of: window).map {
                    WindowPlacement(bundleIdentifier: bundleIdentifier, title: windowManager.title(of: window), frame: $0)
                }
            }
        }
    }

    // MARK: - Toepassen

    func canApply(_ layout: Layout) -> Bool {
        layout.screenSetup == currentSetup
    }

    func apply(_ layout: Layout) {
        guard permission.isGranted else {
            permission.request()
            return
        }

        let placementsByApp = Dictionary(grouping: layout.windows, by: \.bundleIdentifier)
        var moved = 0

        // Alleen apps die nu draaien; Kader start geen apps.
        for (app, bundleIdentifier) in layoutApps() {
            guard let placements = placementsByApp[bundleIdentifier] else { continue }

            let windows = windowManager.standardWindows(ofProcess: app.processIdentifier)
                .map { (window: $0, title: windowManager.title(of: $0)) }
            for (window, frame) in LayoutMatcher.match(placements, to: windows) {
                windowManager.setFrame(frame, of: window)
                moved += 1
            }
        }
        logger.info("Layout \(layout.name, privacy: .public) toegepast op \(moved) vensters")
    }

    // MARK: - Schermopstelling

    private func screensDidChange() {
        currentSetup = ScreenSetup(screens: windowManager.currentScreens())

        pendingAutoApply?.cancel()
        guard let layout = store.automaticLayout(for: currentSetup) else { return }

        pendingAutoApply = Task { [weak self] in
            try? await Task.sleep(for: Self.autoApplyDelay)
            guard !Task.isCancelled, let self, canApply(layout) else { return }
            apply(layout)
        }
    }

    /// Gewone apps met een bundle-ID, behalve Kader zelf en genegeerde apps.
    private func layoutApps() -> [(app: NSRunningApplication, bundleIdentifier: String)] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard
                app.activationPolicy == .regular,
                !app.isHidden,
                app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                let bundleIdentifier = app.bundleIdentifier,
                !excludedApps.contains(bundleIdentifier)
            else {
                return nil
            }
            return (app, bundleIdentifier)
        }
    }
}
