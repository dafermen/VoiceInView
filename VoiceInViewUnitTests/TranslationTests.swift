import XCTest
import SwiftData
@testable import VoiceInView

@MainActor
final class TranslationTests: XCTestCase {

    func testIncrementalTranslationRetainsOnlyUnchangedEdits() throws {
        let a = ReviewParagraph(id: UUID(), text: "First")
        let b = ReviewParagraph(id: UUID(), text: "Second")
        let c = ReviewParagraph(id: UUID(), text: "Third")
        let previous = TranslationSnapshot(source: [a, b], generated: [
            .init(id: a.id, text: "Primero"), .init(id: b.id, text: "Segundo")],
            edits: [a.id.uuidString: "Primera corrección", b.id.uuidString: "Vieja corrección"])
        let changed = ReviewParagraph(id: b.id, text: "New second")
        let plan = IncrementalTranslation(source: [c, a, changed], previous: previous)
        XCTAssertEqual(plan.pending, [c, changed])
        let result = try plan.merging([.init(id: c.id, text: "Tercero"), .init(id: b.id, text: "Nuevo segundo")])
        XCTAssertEqual(result.spanish.map(\.text), ["Tercero", "Primera corrección", "Nuevo segundo"])
        XCTAssertEqual(result.edits.count, 1)
        XCTAssertThrowsError(try plan.merging([]))
        XCTAssertThrowsError(try plan.merging([.init(id: c.id, text: "")] ))
        let removed = try IncrementalTranslation(source: [a], previous: previous).merging([])
        XCTAssertEqual(removed.spanish.first?.text, "Primera corrección")
        XCTAssertEqual(removed.edits.count, 1)
    }

    func testVocabularyValidatesLimitsAndLiteralBoundaries() {
        let terms = PersonalVocabulary.terms("OpenAI\nmeeting = reunión\nMEETING = otro\n = invalid\nempty = \nC++ = Cplusplus")
        XCTAssertEqual(terms.count, 3)
        XCTAssertEqual(terms[0].target, "OpenAI")
        let parts = PersonalVocabulary.parts("OpenAI meeting, meetings and C++!", terms: terms)
        XCTAssertEqual(parts.filter(\.literal).map(\.text), ["OpenAI", "reunión", "Cplusplus"])
        XCTAssertEqual(parts.map(\.text).joined(), "OpenAI reunión, meetings and Cplusplus!")
        XCTAssertEqual(PersonalVocabulary.terms((0..<105).map { "Term\($0)" }.joined(separator: "\n")).count, 100)
        XCTAssertTrue(PersonalVocabulary.terms(String(repeating: "a", count: 81)).isEmpty)
    }

    func testVocabularyPreservesSpacingAndDoesNotSendTermsToTranslator() async throws {
        var sent: [String] = []
        let result = try await PersonalVocabulary.translate("  Hello OpenAI!  ", terms: PersonalVocabulary.terms("OpenAI")) {
            sent.append($0); return "Hola"
        }
        XCTAssertEqual(sent, ["Hello"])
        XCTAssertEqual(result, "  Hola OpenAI!  ")
        let suite = "vocabulary-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("meeting = reunión", forKey: PersonalVocabulary.key)
        XCTAssertEqual(PersonalVocabulary.saved(defaults: defaults).first?.target, "reunión")
    }

    func testLiveTranslationRejectsLateChangedResultsAndBoundsQueue() throws {
        let a = ReviewParagraph(id: UUID(), text: "Original")
        var buffer = LiveTranslationBuffer()
        buffer.synchronize([a])
        let changed = ReviewParagraph(id: a.id, text: "Changed")
        buffer.synchronize([changed])
        try buffer.accept([.init(id: a.id, text: "Anterior")], for: [a])
        XCTAssertTrue(buffer.translated.isEmpty)
        try buffer.accept([.init(id: a.id, text: "Cambiado")], for: [changed])
        XCTAssertEqual(buffer.translated[a.id], "Cambiado")
        buffer.synchronize([changed])
        XCTAssertTrue(buffer.pending.isEmpty)
        let many = (0..<100).map { ReviewParagraph(id: UUID(), text: "\($0)") }
        buffer.synchronize(many)
        XCTAssertEqual(buffer.source.count, 40)
        XCTAssertEqual(buffer.pending.count, 4)
        XCTAssertTrue(buffer.translated.isEmpty)
        XCTAssertThrowsError(try buffer.accept([], for: buffer.pending))
        buffer.synchronize([])
        XCTAssertTrue(buffer.source.isEmpty)
    }

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
