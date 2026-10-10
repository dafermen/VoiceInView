import Foundation
import SwiftData

struct TimedWord: Codable, Equatable, Sendable {
    let text: String
    let start: Double
    let end: Double
}

struct CaptionTiming: Codable, Sendable {
    let start: Double
    let end: Double
    let words: [TimedWord]
}

/// Additive migration: the original transcript, bookmarks and corrections are unchanged.
@Model
final class SessionMedia {
    @Attribute(.unique) var sessionID: UUID
    var audioName: String?
    var timings: Data
    init(sessionID: UUID, audioName: String? = nil) {
        self.sessionID = sessionID
        self.audioName = audioName
        timings = Data("{}".utf8)
    }
    func decodedTimings() throws -> [String: CaptionTiming] {
        try JSONDecoder().decode([String: CaptionTiming].self, from: timings)
    }
}

enum SessionSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(4, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [ConferenceSession.self, StoredCaption.self, CaptionBookmark.self, SessionReview.self, SessionMedia.self]
    }
}
