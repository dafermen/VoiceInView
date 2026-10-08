import XCTest
import SwiftData
@testable import vReader

@MainActor
final class TranscriptRepositoryTests: XCTestCase {
    func testIdempotentUpsertRenameAndCascadeDelete() throws {
        let repository = try TranscriptRepository(inMemory: true)
        let session = try repository.create(title: "Training")
        let segment = CaptionSegment(runID: UUID(), start: 0, end: 1, text: "Hello")
        let change = FinalizedChange(removedIDs: [], upserted: [segment])
        try repository.apply(change, to: session)
        try repository.apply(change, to: session)
        XCTAssertEqual(session.captions.count, 1)
        try repository.rename(session, title: "  Meeting  ")
        XCTAssertEqual(session.title, "Meeting")
        try repository.checkpoint(session, duration: 10, ended: true)
        XCTAssertEqual(session.transcript, "Hello")
        XCTAssertNotNil(session.endedAt)
        try repository.delete(session)
        XCTAssertEqual(try repository.container.mainContext.fetchCount(FetchDescriptor<StoredCaption>()), 0)
    }
}
