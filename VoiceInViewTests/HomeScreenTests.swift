import XCTest

final class HomeScreenTests: XCTestCase {
    @MainActor
    func testSavedAudioPlaybackSubtitleExportAndIndependentDeletion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-review", "--ui-test-media"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Sessions"].waitForExistence(timeout: 20))
        app.tabBars.buttons["Sessions"].tap()
        app.staticTexts["Review sample"].tap()
        app.buttons["sessionMediaButton"].tap()
        XCTAssertTrue(app.navigationBars["Audio & subtitles"].waitForExistence(timeout: 5))
        let play = app.buttons["recordingPlayButton"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()
        let caption = app.staticTexts["playbackCaption"]
        XCTAssertTrue(caption.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "Acmee", "Paragraph"), evaluatedWith: caption)
        waitForExpectations(timeout: 8)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Media-Playback-Portrait"; attachment.lifetime = .keepAlways; add(attachment)
        app.buttons["Full screen"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["Exit full screen"].waitForExistence(timeout: 5))
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Media-Playback-Landscape"; landscape.lifetime = .keepAlways; add(landscape)
        app.buttons["Exit full screen"].tap()
        XCUIDevice.shared.orientation = .portrait
        app.buttons["editMediaTranscriptButton"].tap()
        XCTAssertTrue(app.buttons["editParagraph-1"].waitForExistence(timeout: 5))
        app.buttons["editParagraph-1"].tap()
        let editor = app.textViews["paragraphEditor"]
        editor.tap()
        editor.typeText(" Audio review correction.")
        app.buttons["Apply"].tap()
        app.buttons["saveTranscriptEdits"].tap()
        XCTAssertTrue(app.navigationBars["Audio & subtitles"].waitForExistence(timeout: 5))
        app.buttons["Subtitles (SRT)"].tap()
        let save = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Save to Files")).firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        // Dismiss the native activity controller explicitly, without sending files.
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        let delete = app.buttons["Delete audio, keep text"]
        for _ in 0..<5 { if delete.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(delete.isHittable)
        delete.tap()
        app.buttons["Delete audio"].tap()
        XCTAssertFalse(play.exists)
        XCTAssertTrue(app.buttons["Subtitles (SRT)"].isEnabled)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["reviewParagraph-0"].exists)
    }

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
        XCTAssertTrue(incoming.waitForExistence(timeout: 20))
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

    @MainActor
    private func openReviewSample(_ app: XCUIApplication) {
        XCTAssertTrue(app.tabBars.buttons["Sessions"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Sessions"].tap()
        app.staticTexts["Review sample"].tap()
        XCTAssertTrue(app.buttons["editTranscriptButton"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditingReplacementAndPreviewShareTheCorrectedText() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-review"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        openReviewSample(app)
        app.buttons["editTranscriptButton"].tap()
        app.buttons["editParagraph-1"].tap()
        let editor = app.textViews["paragraphEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(" Reviewed note.")
        app.buttons["Apply"].tap()
        XCTAssertTrue(app.buttons["editParagraph-1"].label.contains("Reviewed note."))
        app.buttons["undoTranscriptEdit"].tap()
        XCTAssertFalse(app.buttons["editParagraph-1"].label.contains("Reviewed note."))
        app.buttons["Redo"].tap()
        XCTAssertTrue(app.buttons["editParagraph-1"].label.contains("Reviewed note."))
        let editCapture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        editCapture.name = "Review-Editor"
        editCapture.lifetime = .keepAlways
        add(editCapture)
        app.buttons["findReplaceButton"].tap()
        app.textFields["findText"].tap()
        app.textFields["findText"].typeText("Acmee")
        app.textFields["replacementText"].tap()
        app.textFields["replacementText"].typeText("Acme")
        app.buttons["Preview matches"].tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.firstMatch)
        waitForExpectations(timeout: 5)
        let findCapture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        findCapture.name = "Review-Find-replace"
        findCapture.lifetime = .keepAlways
        add(findCapture)
        app.buttons["Replace all"].tap()
        app.buttons["Replace 2 matches"].tap()
        app.buttons["Done"].tap()
        app.buttons["saveTranscriptEdits"].tap()
        XCTAssertTrue(app.staticTexts["reviewParagraph-0"].label.contains("Acme makes"))
        XCTAssertTrue(app.staticTexts["reviewParagraph-0"].label.contains("Acmees stays unchanged"))
        app.buttons["reviewShareButton"].tap()
        let preview = app.staticTexts["exportPreviewText"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        XCTAssertTrue(preview.label.contains("Reviewed note."))
        app.segmentedControls["exportContentPicker"].buttons["Bookmarks"].tap()
        XCTAssertTrue(preview.label.contains("Acme makes"))
        XCTAssertFalse(preview.label.contains("Paragraph 2."))
        let details = app.switches["Session details"]
        details.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "value == '0'"), evaluatedWith: details)
        waitForExpectations(timeout: 5)
        expectation(for: NSPredicate(format: "NOT label CONTAINS %@", "Language:"), evaluatedWith: preview)
        waitForExpectations(timeout: 5)
        app.buttons["Copy"].tap()
        XCTAssertTrue(app.buttons["Copied"].exists)
        app.segmentedControls.buttons["PDF"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["pdfPreview"].waitForExistence(timeout: 15))
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "Review-PDF-preview"
        capture.lifetime = .keepAlways
        add(capture)
        app.buttons["Share"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Save to Files")).firstMatch.waitForExistence(timeout: 8))
        let shareCapture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shareCapture.name = "Review-Native-share"
        shareCapture.lifetime = .keepAlways
        add(shareCapture)
    }

    @MainActor
    func testDiscardRestoreOriginalAndResumeReadingFromBookmark() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-review", "--ui-test-reviewed"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        openReviewSample(app)
        app.buttons["editTranscriptButton"].tap()
        app.buttons["restoreOriginalDraft"].tap()
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Restore original", "restoreOriginalDraft")).firstMatch.tap()
        app.buttons["Cancel"].tap()
        app.buttons["Discard changes"].tap()
        XCTAssertEqual(app.staticTexts["reviewParagraph-0"].label, "Acme corrected draft.")
        app.buttons["editTranscriptButton"].tap()
        app.buttons["restoreOriginalDraft"].tap()
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Restore original", "restoreOriginalDraft")).firstMatch.tap()
        app.buttons["saveTranscriptEdits"].tap()
        XCTAssertTrue(app.staticTexts["reviewParagraph-0"].label.contains("Acmee makes"))
        app.buttons["Bookmarks"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Paragraph 80.")).firstMatch.tap()
        let last = app.staticTexts["reviewParagraph-79"]
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: last)
        waitForExpectations(timeout: 10)
        app.navigationBars.buttons["Sessions"].tap()
        app.staticTexts["Review sample"].tap()
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: last)
        waitForExpectations(timeout: 10)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "Review-Restored-position"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor
    func testNewSessionIsACircleAndReclaimsReaderSpace() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-reader"]
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        let reader = app.scrollViews["captionScrollView"]
        XCTAssertTrue(reader.waitForExistence(timeout: 15))
        app.buttons["primaryCaptionAction"].tap()
        expectation(for: NSPredicate(format: "label == 'Pause'"), evaluatedWith: app.buttons["primaryCaptionAction"])
        waitForExpectations(timeout: 10)
        let incoming = reader.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "New captions keep arriving while you read.")).firstMatch
        XCTAssertTrue(incoming.waitForExistence(timeout: 20))
        let listeningHeight = reader.frame.height
        app.buttons["Stop"].tap()
        let action = app.buttons["primaryCaptionAction"]
        expectation(for: NSPredicate(format: "label == 'New Session'"), evaluatedWith: action)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(action.frame.width, 44, accuracy: 1)
        XCTAssertEqual(action.frame.height, 44, accuracy: 1)
        XCTAssertGreaterThan(reader.frame.height, listeningHeight + 40)
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.buttons["Stop"])
        waitForExpectations(timeout: 5)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "Review-New-session-circle"
        capture.lifetime = .keepAlways
        add(capture)
        app.buttons["fullScreenButton"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: action)
        waitForExpectations(timeout: 8)
        action.tap()
        app.buttons["Cancel"].tap()
        XCTAssertEqual(action.label, "New Session")
        action.tap()
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "New Session", "primaryCaptionAction")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["captionPlaceholder"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOngoingSessionRequiresStoppingBeforeEditing() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-reader"]
        app.launch()
        XCTAssertTrue(app.buttons["primaryCaptionAction"].waitForExistence(timeout: 15))
        app.buttons["primaryCaptionAction"].tap()
        app.buttons["sessionActionsButton"].tap()
        app.buttons["Save Session"].tap()
        app.tabBars.buttons["Sessions"].tap()
        app.staticTexts["Conference"].tap()
        XCTAssertFalse(app.buttons["editTranscriptButton"].isEnabled)
        app.buttons["reviewShareButton"].tap()
        XCTAssertFalse(app.buttons["editFromPreview"].isEnabled)
        app.buttons["Done"].tap()
        app.tabBars.buttons["Captions"].tap()
        app.buttons["Stop"].tap()
    }

}
