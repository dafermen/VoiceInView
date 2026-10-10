import SwiftUI
import SwiftData
import UIKit
import AVFoundation

/// Raíz de presentación. Abre el almacén antes de crear la sesión y propaga el ciclo de vida.
/// Un error de apertura se muestra al usuario: no se borra la base ni se simula éxito en memoria.
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
            if ProcessInfo.processInfo.arguments.contains("--ui-test-review") {
                let repository = try TranscriptRepository(inMemory: true)
                let sample = try repository.create(title: "Review sample")
                let run = UUID()
                var segments: [CaptionSegment] = []
                for index in 1...80 {
                    let text: String = index == 1
                        ? "Acmee makes captions useful. Acmee keeps words clear. Acmees stays unchanged."
                        : "Paragraph \(index). Reading, reviewing and sharing should be simple. Keep the original words safe while correcting a transcript."
                    segments.append(CaptionSegment(runID: run, start: Double(index), end: Double(index + 1), text: text))
                }
                try repository.apply(.init(removedIDs: [], upserted: segments), to: sample)
                try repository.checkpoint(sample, duration: 600, ended: true)
                try repository.toggleBookmark(segments[0], in: sample)
                try repository.toggleBookmark(segments[79], in: sample)
                if ProcessInfo.processInfo.arguments.contains("--ui-test-reviewed") {
                    var paragraphs = segments.map { ReviewParagraph(id: $0.id, text: $0.text) }
                    paragraphs[0].text = "Acme corrected draft."
                    try repository.saveCorrections(paragraphs, for: sample)
                }
                if ProcessInfo.processInfo.arguments.contains("--ui-test-media") {
                    let timed = segments.map { segment in
                        CaptionSegment(id: segment.id, runID: segment.runID, start: segment.start,
                            end: segment.end, text: segment.text, sessionTime: true)
                    }
                    try repository.apply(.init(removedIDs: [], upserted: timed), to: sample)
                    let url = try repository.prepareRecording(for: sample)
                    let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
                    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16000)!
                    buffer.frameLength = 16000
                    buffer.floatChannelData![0].initialize(repeating: 0, count: 16000)
                    let recorder = SessionAudioRecorder(url: url)
                    for _ in 0..<85 { recorder.append(CapturedAudio(buffer: buffer)) {} }
                    try recorder.finish()
                }
                coordinator = SessionCoordinator(repository: repository)
                storageFailure = false
                return
            }
            if ProcessInfo.processInfo.arguments.contains("--ui-test-reader") {
                let defaults = UserDefaults(suiteName: "VoiceInView.ReaderUITests")!
                defaults.removePersistentDomain(forName: "VoiceInView.ReaderUITests")
                let settings = AppSettings(defaults: defaults)
                settings.saveAudio = false
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
                      saveSession: { _ = coordinator.saveCurrent(ended: true) },
                      saveAndNewSession: {
                          if coordinator.saveCurrent(ended: true) { await coordinator.newSession() }
                      },
                      discardSession: { await coordinator.discardCurrent() },
                      needsSessionDecision: coordinator.needsSessionDecision,
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
            // Long reader tests need a scrollable history; session-flow tests need only a few phrases.
            let count = ProcessInfo.processInfo.arguments.contains("--ui-test-session-flow") ? 8 : 320
            for index in 1...count {
                continuation?.yield(.init(runID: run, start: Double(index), end: Double(index + 1),
                    text: "Paragraph \(index). Clear captions make every conversation easier to follow.", isFinal: true))
            }
            nextParagraph = count + 1
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
