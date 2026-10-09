import XCTest
import SwiftData
@testable import VoiceInView

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
            .appendingPathComponent("VoiceInViewTests-\(UUID().uuidString)", isDirectory: true)
        // SwiftData can retain SQLite handles beyond an autoreleasepool on iOS 17.
        // Leave this unique temporary store for OS cleanup instead of unlinking an open database.
        let identifier: UUID = try autoreleasepool {
            let repository = try TranscriptRepository(directory: directory)
            let session = try repository.create(title: "Persisted")
            try repository.apply(.init(removedIDs: [], upserted: [
                CaptionSegment(runID: UUID(), start: 0, end: 1, text: "Recovered")
            ]), to: session)
            return session.id
        }
        try autoreleasepool {
            let reopened = try TranscriptRepository(directory: directory)
            let sessions = try reopened.container.mainContext.fetch(FetchDescriptor<ConferenceSession>())
            let session = try XCTUnwrap(sessions.first { $0.id == identifier })
            XCTAssertEqual(session.fullTranscript, "Recovered")
            XCTAssertNil(session.endedAt)
        }
    }
    func testV1StoreMigratesWithoutLosingSessionsAndBookmarksPersist() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Migration-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let identifier = try autoreleasepool { () throws -> UUID in
            let schema = Schema(versionedSchema: SessionSchemaV1.self)
            let config = ModelConfiguration("Sessions", schema: schema,
                url: directory.appendingPathComponent("Sessions.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let session = ConferenceSession(title: "Before update")
            let caption = StoredCaption(segment: CaptionSegment(runID: UUID(), start: 0, end: 1, text: "Keep my words"), order: 0)
            container.mainContext.insert(session)
            container.mainContext.insert(caption)
            session.captions.append(caption)
            try container.mainContext.save()
            return session.id
        }
        try autoreleasepool {
            let repository = try TranscriptRepository(directory: directory)
            let session = try XCTUnwrap(repository.container.mainContext.fetch(FetchDescriptor<ConferenceSession>()).first)
            XCTAssertEqual(session.id, identifier)
            XCTAssertEqual(session.fullTranscript, "Keep my words")
            let stored = try XCTUnwrap(session.captions.first)
            let segment = CaptionSegment(id: stored.id, runID: stored.runID, start: stored.start, end: stored.end, text: stored.text)
            try repository.toggleBookmark(segment, in: session)
            let revision = CaptionSegment(id: stored.id, runID: stored.runID, start: 0, end: 2, text: "Revised words")
            try repository.apply(.init(removedIDs: [], upserted: [revision]), to: session)
            XCTAssertEqual(try repository.bookmarks(for: identifier).first?.text, "Keep my words")
        }
        try autoreleasepool {
            let repository = try TranscriptRepository(directory: directory)
            let session = try XCTUnwrap(repository.container.mainContext.fetch(FetchDescriptor<ConferenceSession>()).first)
            XCTAssertEqual(session.fullTranscript, "Revised words")
            XCTAssertEqual(try repository.bookmarks(for: identifier).count, 1)
            try repository.delete(session)
            XCTAssertTrue(try repository.bookmarks(for: identifier).isEmpty)
        }
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
