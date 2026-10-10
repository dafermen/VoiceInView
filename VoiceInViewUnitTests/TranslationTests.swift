import XCTest
import SwiftData
@testable import VoiceInView

@MainActor
final class TranslationTests: XCTestCase {
    private func sample(_ repository: TranscriptRepository) throws -> (ConferenceSession, TranslationSnapshot) {
        let session = try repository.create(title: "Conference")
        let segment = CaptionSegment(runID: UUID(), start: 1, end: 8,
            text: "Hello world. We are learning together.", sessionTime: true)
        try repository.apply(.init(removedIDs: [], upserted: [segment]), to: session)
        try repository.checkpoint(session, duration: 8, ended: true)
        let source = try repository.reviewedParagraphs(for: session)
        return (session, TranslationSnapshot(source: source,
            generated: [ReviewParagraph(id: segment.id, text: "Hola mundo. Estamos aprendiendo juntos.")]))
    }

    func testTranslationPersistsIndependentlyAndDeleteRemovesIt() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = try autoreleasepool { () throws -> UUID in
            let repository = try TranscriptRepository(directory: directory)
            let (session, snapshot) = try sample(repository)
            try repository.saveTranslation(snapshot, for: session)
            var edited = snapshot
            edited.edits[snapshot.source[0].id.uuidString] = "Hola, mundo. Aprendemos juntos."
            try repository.saveTranslation(edited, for: session)
            XCTAssertEqual(session.fullTranscript, snapshot.source[0].text)
            XCTAssertNil(try repository.review(for: session.id))
            return session.id
        }
        let reopened = try TranscriptRepository(directory: directory)
        let snapshot = try XCTUnwrap(reopened.translation(for: id)?.decoded())
        XCTAssertEqual(snapshot.spanish[0].text, "Hola, mundo. Aprendemos juntos.")
        XCTAssertEqual(snapshot.generated[0].text, "Hola mundo. Estamos aprendiendo juntos.")
        let session = try XCTUnwrap(reopened.container.mainContext.fetch(FetchDescriptor<ConferenceSession>()).first)
        try reopened.delete(session)
        XCTAssertNil(try reopened.translation(for: id))
    }

    func testChangedEnglishRejectsStaleTranslationAndKeepsPrevious() throws {
        let repository = try TranscriptRepository(inMemory: true)
        let (session, snapshot) = try sample(repository)
        try repository.saveTranslation(snapshot, for: session)
        var corrected = snapshot.source
        corrected[0].text = "New English meaning."
        try repository.saveCorrections(corrected, for: session)
        XCTAssertFalse(snapshot.isCurrent(try repository.reviewedParagraphs(for: session)))
        XCTAssertThrowsError(try repository.saveTranslation(snapshot, for: session))
        XCTAssertEqual(try repository.translation(for: session.id)?.decoded(), snapshot)
    }

    func testIncompleteOrMismatchedResultsNeverReplaceSavedTranslation() throws {
        let repository = try TranscriptRepository(inMemory: true)
        let (session, snapshot) = try sample(repository)
        try repository.saveTranslation(snapshot, for: session)
        let incomplete = TranslationSnapshot(source: snapshot.source, generated: [])
        XCTAssertThrowsError(try repository.saveTranslation(incomplete, for: session))
        let wrongID = TranslationSnapshot(source: snapshot.source,
            generated: [ReviewParagraph(id: UUID(), text: "Hola")])
        XCTAssertThrowsError(try repository.saveTranslation(wrongID, for: session))
        let blank = TranslationSnapshot(source: snapshot.source,
            generated: [ReviewParagraph(id: snapshot.source[0].id, text: "  ")])
        XCTAssertThrowsError(try repository.saveTranslation(blank, for: session))
        XCTAssertEqual(try repository.translation(for: session.id)?.decoded(), snapshot)
    }

    func testSpanishAndBilingualSubtitlesPreserveTimesAndAllWords() throws {
        let id = UUID()
        let source = [ReviewParagraph(id: id, text: "Hello world later today")]
        let target = [ReviewParagraph(id: id, text: "Hola mundo más tarde hoy & <amigos>")]
        let snapshot = TranslationSnapshot(source: source, generated: target)
        let timing = [id.uuidString: CaptionTiming(start: 1, end: 9, words: [
            TimedWord(text: "Hello world", start: 1, end: 2),
            TimedWord(text: "later today", start: 7, end: 9)])]
        let original = TranslatedSubtitles.cues(snapshot: snapshot, timings: timing, mode: .english)
        let spanish = TranslatedSubtitles.cues(snapshot: snapshot, timings: timing, mode: .spanish)
        XCTAssertEqual(original.map(\.start), spanish.map(\.start))
        XCTAssertEqual(original.map(\.end), spanish.map(\.end))
        XCTAssertEqual(spanish.map(\.text).joined(separator: " "), target[0].text)
        let both = TranslatedSubtitles.cues(snapshot: snapshot, timings: timing, mode: .both)
        XCTAssertTrue(both[0].text.hasPrefix(original[0].text + "\n"))
        let srt = SubtitleExport.render(spanish, format: .srt)
        XCTAssertTrue(srt.contains("00:00:07,000 --> 00:00:09,000"))
        XCTAssertTrue(srt.contains("&amp; &lt;amigos&gt;"))
        XCTAssertTrue(SubtitleExport.render(both, format: .vtt).hasPrefix("WEBVTT"))
        XCTAssertTrue(TranslatedSubtitles.cues(snapshot: snapshot, timings: [:], mode: .spanish).isEmpty)
        XCTAssertEqual(snapshot.paragraphs(mode: .both)[0].text, source[0].text + "\n" + target[0].text)
    }

    func testEmptyParagraphAndShortTranslationDoNotLoseText() throws {
        let ids = [UUID(), UUID()]
        let source = [ReviewParagraph(id: ids[0], text: ""), ReviewParagraph(id: ids[1], text: "One two three")]
        let snapshot = TranslationSnapshot(source: source,
            generated: [ReviewParagraph(id: ids[0], text: ""), ReviewParagraph(id: ids[1], text: "Sí")])
        try snapshot.validate()
        let timing = [ids[1].uuidString: CaptionTiming(start: 0, end: 12, words: [
            TimedWord(text: "One", start: 0, end: 1), TimedWord(text: "two", start: 5, end: 6),
            TimedWord(text: "three", start: 10, end: 12)])]
        XCTAssertEqual(TranslatedSubtitles.cues(snapshot: snapshot, timings: timing, mode: .spanish).map(\.text), ["Sí"])
    }

    func testV5MigrationKeepsSavedSessionsDraftsCorrectionsAndMedia() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = try autoreleasepool { () throws -> UUID in
            let schema = Schema(versionedSchema: SessionSchemaV5.self)
            let configuration = ModelConfiguration("Sessions", schema: schema,
                url: directory.appendingPathComponent("Sessions.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let session = ConferenceSession(title: "Before translation")
            container.mainContext.insert(session)
            container.mainContext.insert(SessionDraft(sessionID: session.id))
            let review = SessionReview(sessionID: session.id)
            review.corrections = Data("{}".utf8)
            container.mainContext.insert(review)
            container.mainContext.insert(SessionMedia(sessionID: session.id))
            try container.mainContext.save()
            return session.id
        }
        let migrated = try TranscriptRepository(directory: directory)
        let sessions = try migrated.container.mainContext.fetch(FetchDescriptor<ConferenceSession>())
        XCTAssertEqual(sessions.first?.title, "Before translation")
        XCTAssertNotNil(try migrated.draft(for: id))
        XCTAssertNotNil(try migrated.review(for: id))
        XCTAssertNotNil(try migrated.media(for: id))
        XCTAssertNil(try migrated.translation(for: id))
    }
}
