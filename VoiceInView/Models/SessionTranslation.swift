import Foundation
import SwiftData

/// Una traducción es una copia derivada: nunca sustituye reconocimiento ni correcciones inglesas.
/// El snapshot exacto permite detectar cambios de origen sin depender de hashes o fechas.
struct TranslationSnapshot: Codable, Equatable, Sendable {
    let source: [ReviewParagraph]
    let generated: [ReviewParagraph]
    var edits: [String: String] = [:]

    var spanish: [ReviewParagraph] {
        TranscriptReview.paragraphs(originals: generated, corrections: edits)
    }
    func isCurrent(_ paragraphs: [ReviewParagraph]) -> Bool { source == paragraphs }
    func paragraphs(mode: TranscriptLanguage) -> [ReviewParagraph] {
        switch mode {
        case .english: return source
        case .spanish: return spanish
        case .both:
            return zip(source, spanish).map {
                ReviewParagraph(id: $0.id, text: $0.text + "\n" + $1.text)
            }
        }
    }
    func validate() throws {
        guard !source.isEmpty, Set(source.map(\.id)).count == source.count,
              source.map(\.id) == generated.map(\.id),
              edits.keys.allSatisfy({ key in source.contains { $0.id.uuidString == key } }),
              zip(source, generated).allSatisfy({
                  $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                  !$1.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }) else { throw TranslationFailure.incomplete }
    }
}

enum TranscriptLanguage: String, CaseIterable, Identifiable {
    case english = "English", spanish = "Español", both = "Both"
    var id: Self { self }
    var fileSuffix: String { self == .english ? "en" : self == .spanish ? "es" : "en-es" }
}

enum TranslationFailure: LocalizedError {
    case incomplete, sourceChanged, unsupported
    var errorDescription: String? {
        switch self {
        case .incomplete: return "The translation is incomplete. Please try again. Your saved text is unchanged."
        case .sourceChanged: return "The English transcript changed. Reopen Translation and translate again."
        case .unsupported: return "Translation requires iOS 18 or later and a compatible app build. Saved translations remain available."
        }
    }
}

@Model
final class SessionTranslation {
    @Attribute(.unique) var sessionID: UUID
    var payload: Data
    init(sessionID: UUID, payload: Data) { self.sessionID = sessionID; self.payload = payload }
    func decoded() throws -> TranslationSnapshot {
        let result = try JSONDecoder().decode(TranslationSnapshot.self, from: payload)
        try result.validate()
        return result
    }
}

enum SessionSchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(6, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [ConferenceSession.self, StoredCaption.self, CaptionBookmark.self, SessionReview.self,
         SessionMedia.self, SessionDraft.self, SessionTranslation.self]
    }
}

/// Conserva las ventanas inglesas. Reparte las palabras españolas proporcionalmente entre ellas;
/// es sincronización aproximada dentro del párrafo, no alineación fonética entre idiomas.
enum TranslatedSubtitles {
    static func cues(snapshot: TranslationSnapshot, timings: [String: CaptionTiming],
                     mode: TranscriptLanguage) -> [SubtitleCue] {
        let original = SubtitleExport.cues(paragraphs: snapshot.source, timings: timings)
        guard mode != .english else { return original }
        let spanish = Dictionary(uniqueKeysWithValues: snapshot.spanish.map { ($0.id, $0.text) })
        let grouped = Dictionary(grouping: original, by: \.paragraphID)
        var result: [SubtitleCue] = []
        for paragraph in snapshot.source {
            let cues = grouped[paragraph.id] ?? []
            let words = (spanish[paragraph.id] ?? "").split(whereSeparator: \.isWhitespace)
            let total = cues.reduce(0) { $0 + $1.text.split(whereSeparator: \.isWhitespace).count }
            guard total > 0 else { continue }
            var offset = 0
            for cue in cues {
                let start = offset * words.count / total
                offset += cue.text.split(whereSeparator: \.isWhitespace).count
                let end = offset * words.count / total
                let translated = words[start..<end].joined(separator: " ")
                let text = mode == .both ? cue.text + (translated.isEmpty ? "" : "\n" + translated) : translated
                guard !text.isEmpty else { continue }
                result.append(SubtitleCue(id: cue.id, paragraphID: cue.paragraphID,
                    start: cue.start, end: cue.end, text: text))
            }
        }
        return result.sorted { $0.start < $1.start }
    }
}
