import XCTest
@testable import VoiceInView

@MainActor
final class AppSettingsTests: XCTestCase {
    func testPreferencesPersistAndInvalidValuesUseSafeDefaults() {
        let name = "VoiceInViewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(200, forKey: "captionSize")
        defaults.set("invalid", forKey: "appearance")
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.captionSize, 44)
        XCTAssertEqual(settings.appearance, .system)
        settings.lineSpacing = 12
        settings.boldCaptions = true
        settings.highContrast = true
        settings.autoSave = false
        settings.keepAwake = false
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.lineSpacing, 12)
        XCTAssertTrue(reloaded.boldCaptions)
        XCTAssertTrue(reloaded.highContrast)
        XCTAssertFalse(reloaded.autoSave)
        XCTAssertFalse(reloaded.keepAwake)
    }

    func testUnknownOrLowCapacityIsNotReportedReady() {
        XCTAssertFalse(StorageReadiness(availableBytes: nil).ready)
        XCTAssertFalse(StorageReadiness(availableBytes: 1).ready)
        XCTAssertTrue(StorageReadiness(availableBytes: StorageReadiness.minimumBytes).ready)
    }
}
