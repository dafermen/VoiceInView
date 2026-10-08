import XCTest

final class HomeScreenTests: XCTestCase {
    @MainActor
    func testLaunchDoesNotRequestMicrophoneAndShowsCaptureControls() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["vReader"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Microphone capture"].exists)
        XCTAssertTrue(app.buttons["Start Listening"].exists)
        XCTAssertFalse(app.buttons["Stop"].isEnabled)
        XCTAssertTrue(app.staticTexts["The meter shows input volume. Live captions are not implemented yet."].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }
}
