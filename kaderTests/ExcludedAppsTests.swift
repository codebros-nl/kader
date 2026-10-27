import Foundation
import Testing
@testable import kader

@MainActor
struct ExcludedAppsTests {
    /// Eigen suite per test, zodat de echte voorkeuren onaangeroerd blijven.
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "nl.codebros.kader.tests.\(UUID().uuidString)"))
    }

    @Test func startsEmpty() {
        let excluded = ExcludedApps(defaults: defaults)
        #expect(excluded.bundleIdentifiers.isEmpty)
        #expect(!excluded.contains("com.apple.Safari"))
        #expect(!excluded.contains(nil))
    }

    @Test func addAndRemove() {
        let excluded = ExcludedApps(defaults: defaults)
        excluded.setExcluded(true, bundleIdentifier: "com.apple.Safari")
        #expect(excluded.contains("com.apple.Safari"))

        excluded.setExcluded(false, bundleIdentifier: "com.apple.Safari")
        #expect(!excluded.contains("com.apple.Safari"))
    }

    @Test func persistsAcrossInstances() {
        ExcludedApps(defaults: defaults).setExcluded(true, bundleIdentifier: "com.figma.Desktop")
        #expect(ExcludedApps(defaults: defaults).contains("com.figma.Desktop"))
    }

    @Test func notifiesOnChange() {
        let excluded = ExcludedApps(defaults: defaults)
        var changes = 0
        excluded.onChange = { changes += 1 }

        excluded.setExcluded(true, bundleIdentifier: "com.apple.Safari")
        excluded.setExcluded(false, bundleIdentifier: "com.apple.Safari")
        #expect(changes == 2)
    }
}
