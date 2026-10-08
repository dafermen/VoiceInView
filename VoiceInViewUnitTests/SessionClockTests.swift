import XCTest
@testable import VoiceInView

final class SessionClockTests: XCTestCase {
    func testInvalidAndLongDurationsDoNotOverflow() {
        XCTAssertEqual(SessionClock.format(.nan), "00:00:00")
        XCTAssertEqual(SessionClock.format(-1), "00:00:00")
        XCTAssertEqual(SessionClock.format(7200), "02:00:00")
        XCTAssertFalse(SessionClock.format(Double.greatestFiniteMagnitude).isEmpty)
        XCTAssertEqual(SessionClock.seconds(.milliseconds(1500)), 1.5, accuracy: 0.0001)
    }
}
