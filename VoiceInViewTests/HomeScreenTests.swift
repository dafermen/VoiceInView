import XCTest

final class HomeScreenTests: XCTestCase {
    @MainActor
    func testLaunchShowsCaptionsWithoutRequestingMicrophone() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["VoiceInView"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["captionPlaceholder"].exists)
        XCTAssertTrue(app.buttons["Start Listening"].exists)
        XCTAssertFalse(app.buttons["Stop"].isEnabled)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertFalse(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch.exists)
    }

    @MainActor
    func testReadinessAndPrivacyAreAccessibleFromSettings() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        app.staticTexts["Offline Readiness"].tap()
        XCTAssertTrue(app.navigationBars["Offline Readiness"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Test Offline Mode"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let privacy = app.staticTexts["Privacy Policy"]
        for _ in 0..<4 {
            if privacy.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(privacy.isHittable)
        privacy.tap()
        XCTAssertTrue(app.navigationBars["Privacy"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMicrophoneDiagnosticRemainsAvailable() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        app.staticTexts["Microphone Check"].tap()
        XCTAssertTrue(app.staticTexts["Microphone capture"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start Listening"].exists)
        XCTAssertFalse(app.buttons["Stop"].isEnabled)
    }
}
