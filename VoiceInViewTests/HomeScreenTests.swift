import XCTest

final class HomeScreenTests: XCTestCase {
    @MainActor
    func testLaunchShowsCaptionsWithoutRequestingMicrophone() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.scrollViews["captionScrollView"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["captionPlaceholder"].exists)
        XCTAssertTrue(app.buttons["Start Listening"].exists)
        XCTAssertFalse(app.buttons["Stop"].isEnabled)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertFalse(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch.exists)
        if app.buttons["captionStatusDetails"].exists {
            app.buttons["captionStatusDetails"].tap()
            XCTAssertTrue(app.navigationBars["Session information"].waitForExistence(timeout: 5))
            app.buttons["Done"].tap()
            XCTAssertTrue(app.buttons["primaryCaptionAction"].isHittable)
        }
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

    @MainActor
    func testReadingOptionsDoNotOccupyTheReader() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        let reader = app.scrollViews["captionScrollView"]
        XCTAssertTrue(reader.waitForExistence(timeout: 15))
        XCTAssertFalse(app.sliders["Caption size"].exists)
        let originalFrame = reader.frame
        app.buttons["readingOptionsButton"].tap()
        XCTAssertTrue(app.navigationBars["Reading options"].waitForExistence(timeout: 5))
        let slider = app.sliders["Caption size"]
        XCTAssertTrue(slider.exists)
        slider.adjust(toNormalizedSliderPosition: 0.75)
        let selectedSize = slider.value as? String
        app.buttons["Done"].tap()
        XCTAssertTrue(reader.waitForExistence(timeout: 5))
        XCTAssertEqual(reader.frame.height, originalFrame.height, accuracy: 2)
        XCTAssertTrue(app.buttons["primaryCaptionAction"].isHittable)
        app.buttons["readingOptionsButton"].tap()
        XCTAssertEqual(app.sliders["Caption size"].value as? String, selectedSize)
        slider.adjust(toNormalizedSliderPosition: 1.0 / 3.0)
        app.buttons["Done"].tap()
        app.buttons["sessionActionsButton"].tap()
        XCTAssertTrue(app.buttons["New Session"].waitForExistence(timeout: 5))
        // iOS may omit disabled actions from a confirmation dialog.
        let save = app.buttons["Save Session"]
        if save.exists { XCTAssertFalse(save.isEnabled) }
        app.buttons["Session information"].tap()
        XCTAssertTrue(app.navigationBars["Session information"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(reader.waitForExistence(timeout: 5))
    }

    @MainActor
    func testReaderUsesMostOfScreenInBothOrientations() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        let reader = app.scrollViews["captionScrollView"]
        XCTAssertTrue(reader.waitForExistence(timeout: 15))
        for orientation: UIDeviceOrientation in [.portrait, .landscapeLeft, .landscapeRight, .portrait] {
            XCUIDevice.shared.orientation = orientation
            let landscape = orientation == .landscapeLeft || orientation == .landscapeRight
            let expectedShape = NSPredicate { _, _ in
                let frame = app.windows.firstMatch.frame
                return landscape ? frame.width > frame.height : frame.height > frame.width
            }
            expectation(for: expectedShape, evaluatedWith: app)
            waitForExpectations(timeout: 10)
            XCTAssertTrue(app.buttons["primaryCaptionAction"].isHittable)
            XCTAssertTrue(app.buttons["readingOptionsButton"].isHittable)
            XCTAssertTrue(app.buttons["sessionActionsButton"].isHittable)
            XCTAssertTrue(app.staticTexts["captionPlaceholder"].exists)
            XCTAssertGreaterThan(reader.frame.height / app.windows.firstMatch.frame.height, landscape ? 0.45 : 0.55)
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Reader-\(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        app.tabBars.buttons["Sessions"].tap()
        app.tabBars.buttons["Captions"].tap()
        XCTAssertTrue(reader.waitForExistence(timeout: 5))
    }

    @MainActor
    func testFullScreenKeepsListeningAndRestoresTabsAfterRotation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-reader"]
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        let reader = app.scrollViews["captionScrollView"]
        XCTAssertTrue(reader.waitForExistence(timeout: 15))
        app.buttons["primaryCaptionAction"].tap()
        XCTAssertTrue(app.buttons["primaryCaptionAction"].waitForExistence(timeout: 5))
        let originalHeight = reader.frame.height
        app.buttons["fullScreenButton"].tap()
        XCTAssertEqual(app.buttons["primaryCaptionAction"].label, "Pause")
        XCTAssertFalse(app.tabBars.buttons["Settings"].isHittable)
        XCTAssertGreaterThan(reader.frame.height, originalHeight + 40)
        for orientation: UIDeviceOrientation in [.portrait, .landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let landscape = orientation != .portrait
            expectation(for: NSPredicate { _, _ in
                let frame = app.windows.firstMatch.frame
                let rotated = landscape ? frame.width > frame.height : frame.height > frame.width
                return rotated && app.buttons["fullScreenButton"].isHittable
            }, evaluatedWith: app)
            waitForExpectations(timeout: 8)
            XCTAssertTrue(app.buttons["fullScreenButton"].isHittable)
            XCTAssertTrue(app.buttons["primaryCaptionAction"].isHittable)
            expectation(for: NSPredicate { _, _ in
                let count = (reader.value as? String ?? "").components(separatedBy: " ").first ?? ""
                let latest = reader.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Paragraph \(count).")).firstMatch
                return latest.exists && latest.isHittable
            }, evaluatedWith: reader)
            waitForExpectations(timeout: 8)
            let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            capture.name = "Reader-Fullscreen-\(orientation.rawValue)"
            capture.lifetime = .keepAlways
            add(capture)
        }
        app.buttons["primaryCaptionAction"].tap()
        expectation(for: NSPredicate(format: "label == 'Resume'"), evaluatedWith: app.buttons["primaryCaptionAction"])
        waitForExpectations(timeout: 5)
        app.buttons["fullScreenButton"].tap()
        XCTAssertTrue(app.tabBars.buttons["Sessions"].isHittable)
        app.tabBars.buttons["Sessions"].tap()
        app.tabBars.buttons["Captions"].tap()
        XCTAssertEqual(app.buttons["primaryCaptionAction"].label, "Resume")
    }

    @MainActor
    func testRereadingStaysInPlaceAsNewCaptionsArriveAndReturnsToLive() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-reader"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        let reader = app.scrollViews["captionScrollView"]
        XCTAssertTrue(reader.waitForExistence(timeout: 15))
        app.buttons["primaryCaptionAction"].tap()
        // Wait for rendered live text, rather than a transient accessibility
        // scroll value while SwiftUI is laying out the initial 320 paragraphs.
        let incoming = reader.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "New captions keep arriving while you read.")).firstMatch
        XCTAssertTrue(incoming.waitForExistence(timeout: 10))
        reader.swipeDown()
        XCTAssertTrue(app.buttons["backToLiveButton"].waitForExistence(timeout: 5))
        let visible = reader.staticTexts.allElementsBoundByIndex.first {
            $0.label.hasPrefix("Paragraph ") && reader.frame.contains($0.frame)
        }
        let paragraph = try XCTUnwrap(visible)
        let label = paragraph.label
        let oldY = paragraph.frame.minY
        let oldValue = reader.value as? String
        expectation(for: NSPredicate { _, _ in (reader.value as? String) != oldValue }, evaluatedWith: reader)
        waitForExpectations(timeout: 8)
        XCTAssertTrue(paragraph.isHittable)
        XCTAssertEqual(paragraph.frame.minY, oldY, accuracy: 3)
        XCTAssertEqual(app.buttons["primaryCaptionAction"].label, "Pause")
        paragraph.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Save bookmark"].waitForExistence(timeout: 5))
        app.buttons["Save bookmark"].tap()
        app.buttons["sessionActionsButton"].tap()
        app.buttons["Bookmarks"].tap()
        XCTAssertTrue(app.staticTexts[label].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["backToLiveButton"].tap()
        XCTAssertFalse(app.buttons["backToLiveButton"].exists)
        XCTAssertTrue((reader.value as? String)?.contains("Following live captions") == true)
        app.buttons["primaryCaptionAction"].tap()
        expectation(for: NSPredicate(format: "label == 'Resume'"), evaluatedWith: app.buttons["primaryCaptionAction"])
        waitForExpectations(timeout: 5)
        let count = (reader.value as? String ?? "").components(separatedBy: " ").first ?? ""
        let latest = reader.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Paragraph \(count).")).firstMatch
        XCTAssertTrue(latest.isHittable)
        XCTAssertLessThanOrEqual(latest.frame.maxY, reader.frame.maxY + 2)
    }

}
