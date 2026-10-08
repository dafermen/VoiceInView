import XCTest
import SwiftData
@testable import vReader

@MainActor
final class TranscriptRepositoryTests: XCTestCase {
    func testOutOfOrderFinalResultsAreStoredInAudioOrder() throws {
        let repository = try TranscriptRepository(inMemory: true)
        let session = try repository.create(title: "Ordering")
        let run = UUID()
        try repository.apply(.init(removedIDs: [], upserted: [
            CaptionSegment(runID: run, start: 2, end: 3, text: "Second")
        ]), to: session)
        try repository.apply(.init(removedIDs: [], upserted: [
            CaptionSegment(runID: run, start: 0, end: 1, text: "First")
        ]), to: session)
        XCTAssertEqual(session.fullTranscript, "First\nSecond")
    }

    func testFinalCaptionsSurviveStoreReopen() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("vReaderTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let identifier: UUID = try autoreleasepool {
            let repository = try TranscriptRepository(directory: directory)
            let session = try repository.create(title: "Persisted")
            try repository.apply(.init(removedIDs: [], upserted: [
                CaptionSegment(runID: UUID(), start: 0, end: 1, text: "Recovered")
            ]), to: session)
            return session.id
        }
        let reopened = try TranscriptRepository(directory: directory)
        let sessions = try reopened.container.mainContext.fetch(FetchDescriptor<ConferenceSession>())
        let session = try XCTUnwrap(sessions.first { $0.id == identifier })
        XCTAssertEqual(session.fullTranscript, "Recovered")
        XCTAssertNil(session.endedAt)
    }
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
