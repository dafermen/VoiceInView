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
        XCTAssertFalse(settings.saveAudio)
        XCTAssertFalse(settings.continueInBackground)
        XCTAssertEqual(settings.captionSize, 44)
        XCTAssertEqual(settings.appearance, .system)
        settings.lineSpacing = 12
        settings.boldCaptions = true
        settings.highContrast = true
        settings.saveAudio = true
        settings.continueInBackground = true
        settings.keepAwake = false
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.lineSpacing, 12)
        XCTAssertTrue(reloaded.boldCaptions)
        XCTAssertTrue(reloaded.highContrast)
        XCTAssertTrue(reloaded.saveAudio)
        XCTAssertTrue(reloaded.continueInBackground)
        XCTAssertFalse(reloaded.keepAwake)
    }

    func testCaptureLanguageAndPaperPersistWithEnglishDefault() {
        let name = UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.captureLanguage, .english)
        XCTAssertEqual(settings.readerPaper, .system)
        XCTAssertFalse(settings.ruledPaper)
        settings.captureLanguage = .spanish; settings.readerPaper = .purple; settings.ruledPaper = true
        let restored = AppSettings(defaults: defaults)
        XCTAssertEqual(restored.captureLanguage, .spanish)
        XCTAssertEqual(restored.transcriptionLanguage, "es-ES")
        XCTAssertEqual(restored.readerPaper, .purple); XCTAssertTrue(restored.ruledPaper)
        defaults.set("unknown", forKey: "captureLanguage"); defaults.set("unknown", forKey: "readerPaper")
        XCTAssertEqual(AppSettings(defaults: defaults).captureLanguage, .english)
        XCTAssertEqual(AppSettings(defaults: defaults).readerPaper, .system)
    }

    func testUnknownOrLowCapacityIsNotReportedReady() {
        XCTAssertFalse(StorageReadiness(availableBytes: nil).ready)
        XCTAssertFalse(StorageReadiness(availableBytes: 1).ready)
        XCTAssertTrue(StorageReadiness(availableBytes: StorageReadiness.minimumBytes).ready)
    }
}
