import SwiftUI
import SwiftData
import UIKit

@MainActor
struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator: SessionCoordinator?
    @State private var storageFailure = false

    var body: some View {
        Group {
            if let coordinator {
                TabView {
                    NavigationStack {
                        LiveCaptionView(coordinator: coordinator)
                    }
                    .tabItem { Label("Captions", systemImage: "captions.bubble") }
                    NavigationStack { SessionHistoryView(coordinator: coordinator) }
                        .tabItem { Label("Sessions", systemImage: "clock") }
                    NavigationStack { SettingsView(settings: coordinator.settings, coordinator: coordinator) }
                        .tabItem { Label("Settings", systemImage: "gear") }
                }
                .modelContainer(coordinator.repository.container)
                .preferredColorScheme(coordinator.settings.colorScheme)
                .alert("Storage problem", isPresented: Binding(
                    get: { coordinator.storageMessage != nil },
                    set: { if !$0 { coordinator.storageMessage = nil } })) {
                        Button("OK") { coordinator.storageMessage = nil }
                    } message: { Text(coordinator.storageMessage ?? "") }
            } else if storageFailure {
                ContentUnavailableView {
                    Label("Local storage unavailable", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your saved data has not been deleted. Free storage and try again.")
                } actions: {
                    Button("Retry") { openStorage() }
                }
            } else {
                ProgressView("Opening local sessions")
            }
        }
        .task { if coordinator == nil { openStorage() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                UIApplication.shared.isIdleTimerDisabled = false
                if let coordinator, let identifier = coordinator.caption.prepareForBackground() {
                    Task { await coordinator.caption.cleanupBackground(identifier) }
                }
            } else if phase == .active {
                coordinator?.caption.foregrounded()
            }
        }
    }

    private func openStorage() {
        do {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-test-reader") {
                let defaults = UserDefaults(suiteName: "VoiceInView.ReaderUITests")!
                defaults.removePersistentDomain(forName: "VoiceInView.ReaderUITests")
                let settings = AppSettings(defaults: defaults)
                settings.autoSave = false
                coordinator = SessionCoordinator(repository: try TranscriptRepository(inMemory: true),
                    caption: CaptionViewModel(microphone: ReaderPreviewMicrophone(), speech: ReaderPreviewSpeech()),
                    settings: settings)
                storageFailure = false
                return
            }
            #endif
            coordinator = SessionCoordinator(repository: try TranscriptRepository())
            storageFailure = false
        } catch { storageFailure = true }
    }
}

@MainActor
private struct LiveCaptionView: View {
    let coordinator: SessionCoordinator
    @Query private var bookmarks: [CaptionBookmark]
    @State private var showingBookmarks = false

    var body: some View {
        CaptionScreen(model: coordinator.caption, settings: coordinator.settings,
                      newSession: { await coordinator.newSession() },
                      saveSession: { coordinator.saveCurrent(ended: coordinator.caption.state == .ended) },
                      bookmarkSegment: { coordinator.toggleBookmark($0) },
                      showBookmarks: { showingBookmarks = true },
                      bookmarkedIDs: Set(bookmarks.filter { $0.sessionID == coordinator.currentSession?.id }.map(\.segmentID)))
            .sheet(isPresented: $showingBookmarks) {
                BookmarkListView(sessionID: coordinator.currentSession?.id, repository: coordinator.repository)
            }
    }
}

#if DEBUG
/// Deterministic input for UI regression tests; never compiled into TestFlight builds.
@MainActor
private final class ReaderPreviewMicrophone: AudioCapturing {
    let permission: MicrophonePermission = .granted
    var onFailure: (@MainActor @Sendable (CaptureFailure) -> Void)?
    func requestPermission() async -> Bool { true }
    func start() throws -> AsyncStream<Float> { AsyncStream { $0.finish() } }
    func stop() throws {}
}

@MainActor
private final class ReaderPreviewSpeech: SpeechTranscribing {
    private var continuation: AsyncThrowingStream<TranscriptionUpdate, Error>.Continuation?
    private var producer: Task<Void, Never>?
    private var nextParagraph = 1
    func readiness() async -> SpeechReadiness { .ready }
    func installAssets() async throws {}
    func start() async throws -> AsyncThrowingStream<TranscriptionUpdate, Error> {
        let run = UUID()
        let stream = AsyncThrowingStream<TranscriptionUpdate, Error> { continuation = $0 }
        if nextParagraph == 1 {
            for index in 1...320 {
                continuation?.yield(.init(runID: run, start: Double(index), end: Double(index + 1),
                    text: "Paragraph \(index). Clear captions make every conversation easier to follow.", isFinal: true))
            }
            nextParagraph = 321
        }
        producer = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(2)) } catch { return }
                guard let self else { return }
                let index = self.nextParagraph
                self.continuation?.yield(.init(runID: run, start: Double(index), end: Double(index + 1),
                    text: "Paragraph \(index). New captions keep arriving while you read.", isFinal: true))
                self.nextParagraph += 1
            }
        }
        return stream
    }
    func finish() async throws { producer?.cancel(); continuation?.finish() }
    func cancel() async { producer?.cancel(); continuation?.finish() }
}
#endif
