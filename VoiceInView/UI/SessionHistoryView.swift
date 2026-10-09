import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

@MainActor
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

@MainActor
struct SessionDetailView: View {
    @Bindable var session: ConferenceSession
    let repository: TranscriptRepository
    @State private var showingBookmarks = false
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
        .sheet(isPresented: $showingBookmarks) {
            BookmarkListView(sessionID: session.id, repository: repository)
        }
        .toolbar {
            Button("Bookmarks", systemImage: "bookmark") { showingBookmarks = true }
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

@MainActor
struct BookmarkListView: View {
    let repository: TranscriptRepository
    @Query private var bookmarks: [CaptionBookmark]
    @Environment(\.dismiss) private var dismiss
    @State private var failure = false

    init(sessionID: UUID?, repository: TranscriptRepository) {
        self.repository = repository
        let identifier = sessionID ?? UUID()
        _bookmarks = Query(filter: #Predicate<CaptionBookmark> { $0.sessionID == identifier },
                           sort: \.createdAt)
    }

    var body: some View {
        NavigationStack {
            List {
                if bookmarks.isEmpty {
                    ContentUnavailableView("No bookmarks yet", systemImage: "bookmark",
                        description: Text("Touch and hold a finished paragraph in Captions to save a phrase for later."))
                }
                ForEach(bookmarks) { bookmark in
                    Text(bookmark.text).font(.title3).textSelection(.enabled)
                        .swipeActions {
                            Button("Remove", role: .destructive) {
                                do { try repository.removeBookmark(bookmark) }
                                catch { failure = true }
                            }
                        }
                }
            }
            .navigationTitle("Bookmarks").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Could not remove bookmark", isPresented: $failure) { Button("OK") {} }
        }
    }
}
