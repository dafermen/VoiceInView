import Foundation
import SwiftData

@MainActor
final class TranscriptRepository {
    let container: ModelContainer
    private let context: ModelContext
    private var cacheSessionID: UUID?
    private var currentCaptions: [UUID: StoredCaption] = [:]
    private var nextOrder = 0
    private var runOrder: [UUID: Int] = [:]
    let storageURL: URL?

    init(inMemory: Bool = false, directory: URL? = nil) throws {
        let schema = Schema(versionedSchema: SessionSchemaV3.self)
        let configuration: ModelConfiguration
        if inMemory {
            storageURL = nil
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true,
                                               cloudKitDatabase: .none)
        } else {
            // Keep the original storage directory so existing sessions survive the app rename.
            var folder = try directory ?? FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true).appendingPathComponent("vReader", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try folder.setResourceValues(values)
            let file = folder.appendingPathComponent("Sessions.store")
            storageURL = file
            configuration = ModelConfiguration("Sessions", schema: schema, url: file, cloudKitDatabase: .none)
        }
        container = try ModelContainer(for: schema, migrationPlan: SessionMigrationPlan.self, configurations: [configuration])
        context = container.mainContext
        context.autosaveEnabled = false
    }

    func create(title: String) throws -> ConferenceSession {
        let session = ConferenceSession(title: title)
        context.insert(session)
        do { try context.save() } catch { context.rollback(); cacheSessionID = nil; throw error }
        currentCaptions = [:]
        nextOrder = 0
        runOrder = [:]
        cacheSessionID = session.id
        return session
    }

    func apply(_ change: FinalizedChange, to session: ConferenceSession) throws {
        if cacheSessionID != session.id {
            currentCaptions = Dictionary(uniqueKeysWithValues: session.captions.map { ($0.id, $0) })
            runOrder = [:]
            for caption in session.captions { runOrder[caption.runID] = caption.order }
            nextOrder = (session.captions.map { $0.order }.max() ?? -1) + 1
            cacheSessionID = session.id
        }
        for id in change.removedIDs {
            if let caption = currentCaptions.removeValue(forKey: id) {
                session.captions.removeAll { $0.id == id }
                context.delete(caption)
            }
        }
        for segment in change.upserted {
            if let existing = currentCaptions[segment.id] {
                existing.text = segment.text
                existing.start = segment.start
                existing.end = segment.end
            } else {
                let rank: Int
                if let existingRank = runOrder[segment.runID] {
                    rank = existingRank
                } else {
                    rank = nextOrder
                    nextOrder += 1
                    runOrder[segment.runID] = rank
                }
                let caption = StoredCaption(segment: segment, order: rank)
                context.insert(caption)
                session.captions.append(caption)
                currentCaptions[caption.id] = caption
            }
        }
        try context.save()
    }

    func checkpoint(_ session: ConferenceSession, duration: TimeInterval, ended: Bool) throws {
        session.duration = duration
        if ended {
            session.endedAt = Date()
            session.transcript = session.fullTranscript
        }
        try context.save()
    }

    func rename(_ session: ConferenceSession, title: String) throws {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        session.title = clean
        do { try context.save() } catch { context.rollback(); cacheSessionID = nil; throw error }
    }

    func delete(_ session: ConferenceSession) throws {
        let identifier = session.id
        let savedBookmarks = try bookmarks(for: identifier)
        let savedReview = try review(for: identifier)
        // Explicit deletion also covers iOS 17 stores where cascade propagation
        // can leave registered caption objects behind in the context.
        for caption in session.captions { context.delete(caption) }
        for bookmark in savedBookmarks { context.delete(bookmark) }
        if let savedReview { context.delete(savedReview) }
        context.delete(session)
        do { try context.save() } catch { context.rollback(); cacheSessionID = nil; throw error }
        if cacheSessionID == identifier {
            cacheSessionID = nil
            currentCaptions = [:]
            runOrder = [:]
            nextOrder = 0
        }
    }

    func bookmarks(for sessionID: UUID) throws -> [CaptionBookmark] {
        try context.fetch(FetchDescriptor<CaptionBookmark>(
            predicate: #Predicate { $0.sessionID == sessionID },
            sortBy: [SortDescriptor(\.createdAt)]))
    }

    func toggleBookmark(_ segment: CaptionSegment, in session: ConferenceSession) throws {
        if let existing = try bookmarks(for: session.id).first(where: { $0.segmentID == segment.id }) {
            context.delete(existing)
        } else {
            context.insert(CaptionBookmark(sessionID: session.id, segment: segment))
        }
        do { try context.save() } catch { context.rollback(); cacheSessionID = nil; throw error }
    }

    func removeBookmark(_ bookmark: CaptionBookmark) throws {
        context.delete(bookmark)
        do { try context.save() } catch { context.rollback(); cacheSessionID = nil; throw error }
    }

    func review(for sessionID: UUID) throws -> SessionReview? {
        var request = FetchDescriptor<SessionReview>(predicate: #Predicate { $0.sessionID == sessionID })
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func saveCorrections(_ paragraphs: [ReviewParagraph], for session: ConferenceSession) throws {
        let originals = session.orderedCaptions.map { ReviewParagraph(id: $0.id, text: $0.text) }
        guard paragraphs.map(\.id) == originals.map(\.id) else { throw ReviewFailure.sessionChanged }
        let changes = Dictionary(uniqueKeysWithValues: zip(originals, paragraphs).compactMap { original, edited in
            original.text == edited.text ? nil : (original.id.uuidString, edited.text)
        })
        let encoded = try JSONEncoder().encode(changes)
        let record = try review(for: session.id) ?? SessionReview(sessionID: session.id)
        context.insert(record)
        record.corrections = encoded
        record.updatedAt = changes.isEmpty ? nil : Date()
        do { try context.save() } catch { context.rollback(); cacheSessionID = nil; throw error }
    }

    func saveReadingPosition(_ captionID: UUID, for session: ConferenceSession) throws {
        guard session.captions.contains(where: { $0.id == captionID }) else { return }
        let record = try review(for: session.id) ?? SessionReview(sessionID: session.id)
        guard record.lastReadCaptionID != captionID else { return }
        context.insert(record)
        record.lastReadCaptionID = captionID
        do { try context.save() } catch { context.rollback(); cacheSessionID = nil; throw error }
    }

    func save() throws { try context.save() }
}
