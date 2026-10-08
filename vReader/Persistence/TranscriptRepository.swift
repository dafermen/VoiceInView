import Foundation
import SwiftData

@MainActor
final class TranscriptRepository {
    let container: ModelContainer
    private let context: ModelContext
    private var currentCaptions: [UUID: StoredCaption] = [:]
    private var nextOrder = 0
    let storageURL: URL?

    init(inMemory: Bool = false, directory: URL? = nil) throws {
        let schema = Schema(versionedSchema: SessionSchemaV1.self)
        let configuration: ModelConfiguration
        if inMemory {
            storageURL = nil
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true,
                                               cloudKitDatabase: .none)
        } else {
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
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = container.mainContext
        context.autosaveEnabled = false
    }

    func create(title: String) throws -> ConferenceSession {
        let session = ConferenceSession(title: title)
        context.insert(session)
        do { try context.save() } catch { context.rollback(); throw error }
        currentCaptions = [:]
        nextOrder = 0
        return session
    }

    func apply(_ change: FinalizedChange, to session: ConferenceSession) throws {
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
                let caption = StoredCaption(segment: segment, order: nextOrder)
                nextOrder += 1
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
        do { try context.save() } catch { context.rollback(); throw error }
    }

    func delete(_ session: ConferenceSession) throws {
        context.delete(session)
        do { try context.save() } catch { context.rollback(); throw error }
    }

    func save() throws { try context.save() }
}
