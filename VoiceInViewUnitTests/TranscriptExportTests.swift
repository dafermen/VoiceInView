import XCTest
@testable import VoiceInView

final class TranscriptExportTests: XCTestCase {
    func testExportContainsMetadataAndUnicode() {
        let text = TranscriptExport.render(title: "Training", date: Date(timeIntervalSince1970: 0),
            duration: 3661, language: "en-US", transcript: "Résumé — hello", unfinished: true)
        XCTAssertTrue(text.contains("Training"))
        XCTAssertTrue(text.contains("01:01:01"))
        XCTAssertTrue(text.contains("en-US"))
        XCTAssertTrue(text.contains("Unfinished"))
        XCTAssertTrue(text.contains("Résumé — hello"))
    }

    func testFilenameCannotContainPathSeparators() {
        let name = TranscriptExport.filename(title: "a/b\\c:meeting")
        XCTAssertFalse(name.contains("/"))
        XCTAssertFalse(name.contains("\\"))
        XCTAssertEqual(TranscriptExport.filename(title: "   "), "VoiceInView-transcript")
    }
}
