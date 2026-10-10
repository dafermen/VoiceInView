import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

@MainActor
struct SessionHistoryView: View {
    let coordinator: SessionCoordinator
    @Query(sort: \ConferenceSession.createdAt, order: .reverse) private var sessions: [ConferenceSession]
    @Query private var reviews: [SessionReview]
    @Query private var drafts: [SessionDraft]
    @State private var query = ""
    @State private var deleting: ConferenceSession?
    @State private var failure: String?

    private var filtered: [ConferenceSession] {
        guard !query.isEmpty else { return sessions }
        return sessions.filter { session in
            if session.title.localizedCaseInsensitiveContains(query) { return true }
            let changes = (try? reviews.first(where: { $0.sessionID == session.id })?.decodedCorrections()) ?? [:]
            let originals = session.orderedCaptions.map { ReviewParagraph(id: $0.id, text: $0.text) }
            return TranscriptReview.text(TranscriptReview.paragraphs(originals: originals, corrections: changes))
                .localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView("No sessions", systemImage: "text.bubble",
                                       description: Text("Saved sessions will appear here."))
            }
            let draftIDs = Set(drafts.map(\.sessionID))
            if filtered.contains(where: { draftIDs.contains($0.id) }) {
                Section("Recovery drafts") {
                    Text("Saved automatically for recovery. Choose Save to keep a session or Discard to delete its text and audio.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(filtered.filter { draftIDs.contains($0.id) }) { session in
                        sessionLink(session)
                        HStack {
                            Button("Save Session", systemImage: "square.and.arrow.down") { saveDraft(session) }
                                .accessibilityIdentifier("saveDraft-" + session.id.uuidString)
                            Spacer()
                            Button("Discard", systemImage: "trash", role: .destructive) { deleting = session }
                                .accessibilityIdentifier("discardDraft-" + session.id.uuidString)
                        }
                        .buttonStyle(.borderless)
                        .disabled(coordinator.currentSession?.id == session.id && coordinator.caption.state != .ended)
                    }
                }
            }
            Section("Saved sessions") {
                ForEach(filtered.filter { !draftIDs.contains($0.id) }) { session in sessionLink(session) }
            }
        }
        .searchable(text: $query, prompt: "Titles or finished transcripts")
        .navigationTitle("Sessions")
        .confirmationDialog("Delete this session permanently?", isPresented: Binding(
            get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let deleting {
                        if coordinator.currentSession?.id == deleting.id {
                            Task { await coordinator.discardCurrent() }
                        } else {
                            do { try coordinator.repository.delete(deleting) }
                            catch { failure = "The session could not be deleted." }
                        }
                    }
                    deleting = nil
                }
            }
        .alert("Storage problem", isPresented: Binding(
            get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK") { failure = nil }
            } message: { Text(failure ?? "") }
    }

    private func saveDraft(_ session: ConferenceSession) {
        if coordinator.currentSession?.id == session.id {
            _ = coordinator.saveCurrent(ended: true)
        } else {
            do { try coordinator.repository.publish(session) }
            catch { failure = "The draft could not be saved. Please retry." }
        }
    }

    private func sessionLink(_ session: ConferenceSession) -> some View {
        NavigationLink {
            SessionDetailView(session: session, repository: coordinator.repository,
                canEdit: coordinator.currentSession?.id != session.id || coordinator.caption.state == .ended,
                canPlay: !coordinator.caption.state.active && !coordinator.caption.state.busy &&
                    (coordinator.currentSession?.id != session.id || coordinator.caption.state == .ended))
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
                .disabled(coordinator.currentSession?.id == session.id && coordinator.caption.state != .ended)
        }
    }

}

@MainActor
struct SessionDetailView: View {
    @Bindable var session: ConferenceSession
    let repository: TranscriptRepository
    let canEdit: Bool
    let canPlay: Bool
    @State private var showingMedia = false
    @State private var playbackParagraphID: UUID?
    @State private var playableParagraphIDs: Set<UUID> = []
    @Query private var reviews: [SessionReview]
    @Query private var bookmarks: [CaptionBookmark]
    @State private var showingBookmarks = false
    @State private var showingEditor = false
    @State private var showingShare = false
    @State private var renaming = false
    @State private var title = ""
    @State private var failure: String?
    @State private var position: UUID?
    @State private var restored = false
    @State private var savePositionTask: Task<Void, Never>?

    init(session: ConferenceSession, repository: TranscriptRepository, canEdit: Bool, canPlay: Bool = true) {
        self.session = session
        self.repository = repository
        self.canEdit = canEdit
        self.canPlay = canPlay
        let identifier = session.id
        _reviews = Query(filter: #Predicate<SessionReview> { $0.sessionID == identifier })
        _bookmarks = Query(filter: #Predicate<CaptionBookmark> { $0.sessionID == identifier }, sort: \.createdAt)
    }

    private var originals: [ReviewParagraph] { session.orderedCaptions.map { ReviewParagraph(id: $0.id, text: $0.text) } }
    private var corrections: [String: String]? {
        do { return try reviews.first?.decodedCorrections() ?? [:] } catch { return nil }
    }
    private var paragraphs: [ReviewParagraph] {
        TranscriptReview.paragraphs(originals: originals, corrections: corrections ?? [:])
    }

    private func refreshPlayableParagraphs() {
        playableParagraphIDs = []
        guard canPlay, let url = try? repository.audioURL(for: session.id),
              FileManager.default.fileExists(atPath: url.path),
              let media = try? repository.media(for: session.id),
              let timings = try? media.decodedTimings() else { return }
        playableParagraphIDs = Set(SubtitleExport.cues(paragraphs: paragraphs, timings: timings).map(\.paragraphID))
    }

    @ViewBuilder private func paragraphView(_ paragraph: ReviewParagraph, index: Int) -> some View {
        if canPlay && playableParagraphIDs.contains(paragraph.id) && !paragraph.text.isEmpty {
            Button {
                playbackParagraphID = paragraph.id
                showingMedia = true
            } label: {
                Text(paragraph.text).font(.title2).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Listen from this paragraph")
            .accessibilityIdentifier("listenParagraph-\(index)")
        } else {
            Text(paragraph.text.isEmpty ? "Empty paragraph" : paragraph.text)
                .font(.title2).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("reviewParagraph-\(index)")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.createdAt, style: .date)
                    Text("\(SessionClock.format(session.duration)) · \(session.language)")
                    if !canEdit { Text("Stop this session in Captions before editing.") }
                    else if session.endedAt == nil { Text("Saved final captions from an unfinished session.") }
                    if !(corrections ?? [:]).isEmpty { Label("Edited transcript", systemImage: "pencil").font(.caption) }
                }.font(.subheadline).foregroundStyle(.secondary)
                Button("Audio & subtitles", systemImage: "waveform") { playbackParagraphID = nil; showingMedia = true }
                    .disabled(!canPlay || corrections == nil).accessibilityIdentifier("sessionMediaButton")
                if !canPlay { Text("Stop listening before opening audio and subtitles.").font(.caption) }
                if corrections == nil {
                    ContentUnavailableView("Corrections unavailable", systemImage: "exclamationmark.triangle",
                        description: Text("Reopen this session. Your original captions have not been changed."))
                } else {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(Array(paragraphs.enumerated()), id: \.element.id) { index, paragraph in
                            paragraphView(paragraph, index: index).id(paragraph.id)
                        }
                    }.scrollTargetLayout()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical)
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollPosition(id: $position, anchor: .top)
        .accessibilityIdentifier("sessionReader")
        .navigationTitle(session.title).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(session.title) { title = session.title; renaming = true }
                    .font(.headline).lineLimit(1).accessibilityLabel("Rename session")
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit transcript", systemImage: "pencil") { showingEditor = true }
                    .disabled(!canEdit || corrections == nil || originals.isEmpty)
                    .accessibilityIdentifier("editTranscriptButton")
                Button("Bookmarks", systemImage: "bookmark") { showingBookmarks = true }
                Button("Review & share", systemImage: "square.and.arrow.up") { showingShare = true }
                    .disabled(corrections == nil).accessibilityIdentifier("reviewShareButton")
            }
        }
        .task(id: showingMedia) { refreshPlayableParagraphs() }
        .sheet(isPresented: $showingMedia) {
            SessionMediaView(session: session, repository: repository, paragraphs: paragraphs,
                             hasCorrections: !(corrections ?? [:]).isEmpty, initialParagraphID: playbackParagraphID)
        }
        .sheet(isPresented: $showingEditor) {
            TranscriptEditorView(originals: originals, reviewed: paragraphs) { edited in
                guard canEdit else { throw ReviewFailure.sessionChanged }
                try repository.saveCorrections(edited, for: session)
            }
        }
        .sheet(isPresented: $showingShare) {
            TranscriptShareView(session: session, repository: repository, canEdit: canEdit, bookmarks: bookmarks)
        }
        .sheet(isPresented: $showingBookmarks) {
            BookmarkListView(sessionID: session.id, repository: repository,
                jumpableIDs: Set(originals.map(\.id)), onSelect: { position = $0 })
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
        .task {
            guard !restored else { return }
            do { position = try repository.review(for: session.id)?.lastReadCaptionID }
            catch { failure = "Could not restore your reading position." }
            restored = true
        }
        .onChange(of: position) { _, _ in
            guard restored else { return }
            savePositionTask?.cancel()
            savePositionTask = Task { @MainActor in
                do { try await Task.sleep(for: .milliseconds(700)) } catch { return }
                persistPosition()
            }
        }
        .onDisappear {
            savePositionTask?.cancel()
            persistPosition()
        }
    }

    private func persistPosition() {
        guard restored, let position else { return }
        do { try repository.saveReadingPosition(position, for: session) }
        catch { failure = "Could not save your reading position. Your transcript is unchanged." }
    }
}

@MainActor
struct BookmarkListView: View {
    let repository: TranscriptRepository
    let jumpableIDs: Set<UUID>
    let onSelect: ((UUID) -> Void)?
    @Query private var bookmarks: [CaptionBookmark]
    @Query private var reviews: [SessionReview]
    @Environment(\.dismiss) private var dismiss
    @State private var failure = false

    init(sessionID: UUID?, repository: TranscriptRepository, jumpableIDs: Set<UUID> = [], onSelect: ((UUID) -> Void)? = nil) {
        self.repository = repository
        self.jumpableIDs = jumpableIDs
        self.onSelect = onSelect
        let identifier = sessionID ?? UUID()
        _bookmarks = Query(filter: #Predicate<CaptionBookmark> { $0.sessionID == identifier }, sort: \.createdAt)
        _reviews = Query(filter: #Predicate<SessionReview> { $0.sessionID == identifier })
    }

    private var corrections: [String: String]? {
        do { return try reviews.first?.decodedCorrections() ?? [:] } catch { return nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if corrections == nil {
                    Text("Saved corrections could not be loaded. Reopen this session.")
                } else if bookmarks.isEmpty {
                    ContentUnavailableView("No bookmarks yet", systemImage: "bookmark",
                        description: Text("Touch and hold a finished paragraph in Captions to save a phrase for later."))
                }
                if let corrections {
                    ForEach(bookmarks) { bookmark in
                        Group {
                            if let onSelect, jumpableIDs.contains(bookmark.segmentID) {
                                Button {
                                    dismiss()
                                    onSelect(bookmark.segmentID)
                                } label: {
                                    HStack {
                                        Text(corrections[bookmark.segmentID.uuidString] ?? bookmark.text)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                    }
                                }
                                .accessibilityHint("Go to this paragraph")
                            } else {
                                Text(corrections[bookmark.segmentID.uuidString] ?? bookmark.text).textSelection(.enabled)
                            }
                        }
                        .font(.title3)
                        .swipeActions {
                            Button("Remove", role: .destructive) {
                                do { try repository.removeBookmark(bookmark) }
                                catch { failure = true }
                            }
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
