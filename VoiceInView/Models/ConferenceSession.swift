import Foundation
import SwiftData

@Model
final class ConferenceSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var startedAt: Date
    var endedAt: Date?
    var duration: Double
    var language: String
    var transcript: String
    @Relationship(deleteRule: .cascade, inverse: \StoredCaption.session)
    var captions: [StoredCaption] = []

    init(title: String, startedAt: Date = Date()) {
        id = UUID()
        self.title = title
        createdAt = Date()
        self.startedAt = startedAt
        duration = 0
        language = "en-US"
        transcript = ""
    }

    var orderedCaptions: [StoredCaption] {
        captions.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.start < $1.start
        }
    }
    var fullTranscript: String { orderedCaptions.map(\.text).joined(separator: "\n") }
}

@Model
final class StoredCaption {
    @Attribute(.unique) var id: UUID
    var runID: UUID
    var start: Double
    var end: Double
    var text: String
    var order: Int
    var session: ConferenceSession?

    init(segment: CaptionSegment, order: Int) {
        id = segment.id
        runID = segment.runID
        start = segment.start
        end = segment.end
        text = segment.text
        self.order = order
    }
}

enum SessionSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [ConferenceSession.self, StoredCaption.self] }
}

/// Snapshots are independent of speech revisions, so a selected quote stays intact.
@Model
final class CaptionBookmark {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var segmentID: UUID
    var text: String
    var createdAt: Date

    init(sessionID: UUID, segment: CaptionSegment) {
        id = UUID()
        self.sessionID = sessionID
        segmentID = segment.id
        text = segment.text
        createdAt = Date()
    }
}

enum SessionSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [ConferenceSession.self, StoredCaption.self, CaptionBookmark.self]
    }
}

enum SessionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SessionSchemaV1.self, SessionSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: SessionSchemaV1.self, toVersion: SessionSchemaV2.self)]
    }
}
