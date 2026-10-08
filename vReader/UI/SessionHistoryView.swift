import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct SessionHistoryView: View {
    let coordinator: SessionCoordinator
    @Query(sort: \ConferenceSession.createdAt, order: .reverse) private var sessions: [ConferenceSession]
    @State private var query = ""
    @State private var deleting: ConferenceSession?
    @State private var failure: String?

    private var filtered: [ConferenceSession] {
        guard !query.isEmpty else { return sessions }
        return sessions.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.transcript.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView("No sessions", systemImage: "text.bubble",
                                       description: Text("Saved sessions will appear here."))
            }
            ForEach(filtered) { session in
                NavigationLink {
                    SessionDetailView(session: session, repository: coordinator.repository)
                } label: {
                    VStack(alignment: .leading) {
                        Text(session.title).font(.headline)
                        Text(session.createdAt, style: .date).font(.subheadline)
                        Text(session.endedAt == nil ? "Unfinished or interrupted session" :
                             SessionClock.format(session.duration)).font(.caption)
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) { deleting = session }
                        .disabled(coordinator.currentSession?.id == session.id)
                }
            }
        }
        .searchable(text: $query, prompt: "Titles or finished transcripts")
        .navigationTitle("Sessions")
        .confirmationDialog("Delete this session permanently?", isPresented: Binding(
            get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let deleting {
                        do { try coordinator.repository.delete(deleting) }
                        catch { failure = "The session could not be deleted." }
                    }
                    deleting = nil
                }
            }
        .alert("Storage problem", isPresented: Binding(
            get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK") { failure = nil }
            } message: { Text(failure ?? "") }
    }
}

struct SessionDetailView: View {
    @Bindable var session: ConferenceSession
    let repository: TranscriptRepository
    @State private var exporting = false
    @State private var renaming = false
    @State private var title = ""
    @State private var failure: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text(session.createdAt, style: .date)
                Text("\(SessionClock.format(session.duration)) · \(session.language)")
                if session.endedAt == nil { Text("Recovered final captions; the session did not finish normally.") }
                ForEach(session.orderedCaptions) { caption in
                    Text(caption.text).font(.title2).textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle(session.title)
        .toolbar {
            Button("Rename") { title = session.title; renaming = true }
            Menu("Export") {
                Button("Export Text File") { exporting = true }
                Button("Copy Transcript") { UIPasteboard.general.string = exportText }
                ShareLink(item: exportText) { Label("Share Transcript", systemImage: "square.and.arrow.up") }
            }
        }
        .fileExporter(isPresented: $exporting, document: TextTranscriptDocument(text: exportText),
                      contentType: .plainText, defaultFilename: TranscriptExport.filename(title: session.title)) { result in
            if case .failure = result { failure = "The text file could not be exported." }
        }
        .alert("Rename session", isPresented: $renaming) {
            TextField("Title", text: $title)
            Button("Save") {
                do { try repository.rename(session, title: title) }
                catch { failure = "The session could not be renamed." }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Storage problem", isPresented: Binding(
            get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK") { failure = nil }
            } message: { Text(failure ?? "") }
    }

    private var exportText: String {
        TranscriptExport.render(title: session.title, date: session.startedAt, duration: session.duration,
                                language: session.language, transcript: session.fullTranscript,
                                unfinished: session.endedAt == nil)
    }
}
