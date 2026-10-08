import XCTest
@testable import vReader

@MainActor
final class AppSettingsTests: XCTestCase {
    func testPreferencesPersistAndInvalidValuesUseSafeDefaults() {
        let name = "vReaderTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(200, forKey: "captionSize")
        defaults.set("invalid", forKey: "appearance")
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.captionSize, 44)
        XCTAssertEqual(settings.appearance, .system)
        settings.autoSave = false
        settings.keepAwake = false
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertFalse(reloaded.autoSave)
        XCTAssertFalse(reloaded.keepAwake)
    }

    func testUnknownOrLowCapacityIsNotReportedReady() {
        XCTAssertFalse(StorageReadiness(availableBytes: nil).ready)
        XCTAssertFalse(StorageReadiness(availableBytes: 1).ready)
        XCTAssertTrue(StorageReadiness(availableBytes: StorageReadiness.minimumBytes).ready)
    }
}
