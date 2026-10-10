import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

@MainActor
struct CaptureOptionsView: View {
    @Bindable var model: CaptionViewModel
    var body: some View {
        Section {
            Toggle("Save audio with transcript", isOn: $model.saveAudio)
                .accessibilityIdentifier("saveAudioToggle")
            Toggle("Continue in background", isOn: $model.continueInBackground)
                .accessibilityIdentifier("backgroundAudioToggle")
        } header: { Text("This session") } footer: {
            Text("Choose before starting. Audio stays on this iPhone and also saves the transcript. Recordings may use hundreds of MB per hour. Background listening keeps the microphone active when switching apps or locking the screen. Both options reset for a new session. Other apps' audio must be audible through the speaker; headphones and internal app audio are not captured.")
        }
        .disabled(!model.canChooseCaptureOptions)
    }
}

@MainActor
@Observable
final class SessionPlayer {
    private var player: AVAudioPlayer?
    private var timer: Task<Void, Never>?
    private var interruption: NSObjectProtocol?
    private(set) var playing = false
    private(set) var time = 0.0
    private(set) var duration = 0.0
    var failure: String?

    func load(_ url: URL) {
        stop()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            duration = player?.duration ?? 0
            player?.prepareToPlay()
            interruption = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.pause() }
            }
        } catch { failure = "This recording could not be opened. The transcript is still available." }
    }
    func toggle() {
        if playing { pause(); return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            if time >= duration { seek(0) }
            guard player?.play() == true else { throw RecordingFailure.unavailable }
            playing = true
            timer = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                    guard let self, let player = self.player else { return }
                    self.time = player.currentTime
                    if !player.isPlaying { self.time = self.duration; self.pause(); return }
                }
            }
        } catch { failure = "Audio playback could not start. Please try again." }
    }
    func seek(_ value: Double) {
        time = min(max(value, 0), duration)
        player?.currentTime = time
    }
    func pause() {
        timer?.cancel(); timer = nil
        player?.pause(); playing = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    func stop() {
        if let interruption { NotificationCenter.default.removeObserver(interruption) }
        interruption = nil
        pause(); player = nil; time = 0; duration = 0
    }
}

@MainActor
struct SessionMediaView: View {
    let session: ConferenceSession
    let repository: TranscriptRepository
    let paragraphs: [ReviewParagraph]
    let hasCorrections: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var player = SessionPlayer()
    @State private var audioURL: URL?
    @State private var cues: [SubtitleCue] = []
    @State private var captions = true
    @State private var deleting = false
    @State private var busy = false
    @State private var failure: String?
    @State private var export: MediaShare?
    @State private var folder: URL?
    @State private var exportTask: Task<Void, Never>?
    @State private var fullScreen = false
    @State private var editing = false
    @State private var reviewed: [ReviewParagraph] = []
    @State private var edited = false
    @Environment(\.scenePhase) private var phase
    private var currentCue: SubtitleCue? { cues.first { $0.start <= player.time && player.time < $0.end } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if audioURL != nil {
                    if captions {
                        Text(currentCue?.text ?? (player.playing ? "…" : "Play to read synchronized captions"))
                            .font(.title2.weight(.medium)).multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, maxHeight: fullScreen ? .infinity : 160)
                            .padding().background(.black, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white).accessibilityIdentifier("playbackCaption")
                    }
                    Slider(value: Binding(get: { player.time }, set: { player.seek($0) }),
                           in: 0...max(player.duration, 0.001))
                        .accessibilityLabel("Playback position")
                        .accessibilityValue(SessionClock.format(player.time))
                    HStack {
                        Text(SessionClock.format(player.time)).monospacedDigit()
                        Spacer()
                        Text(SessionClock.format(player.duration)).monospacedDigit()
                    }.font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 28) {
                        Button("Back 10 seconds", systemImage: "gobackward.10") { player.seek(player.time - 10) }
                        Button(player.playing ? "Pause" : "Play", systemImage: player.playing ? "pause.fill" : "play.fill") { player.toggle() }
                            .accessibilityIdentifier("recordingPlayButton")
                        Button("Forward 10 seconds", systemImage: "goforward.10") { player.seek(player.time + 10) }
                        Button("Subtitles", systemImage: captions ? "captions.bubble.fill" : "captions.bubble") { captions.toggle() }
                            .accessibilityValue(captions ? "On" : "Off")
                    }.labelStyle(.iconOnly).font(.title2).buttonStyle(PlaybackButtonStyle())
                        .frame(minHeight: 44)
                }
                if !fullScreen {
                    List {
                        if audioURL == nil { Text("No audio saved for this session. Enable Save audio before starting your next session.") }
                        Section {
                            Button("Edit transcript", systemImage: "pencil") { player.pause(); editing = true }
                                .accessibilityIdentifier("editMediaTranscriptButton")
                        }
                        Section("Export") {
                            if audioURL != nil {
                                Button("Share audio (M4A)", systemImage: "waveform") { prepareExport(kind: .audio) }
                                Button("Share audio + text + subtitles", systemImage: "square.and.arrow.up") { prepareExport(kind: .bundle) }
                            }
                            Button("Subtitles (SRT)") { prepareExport(kind: .srt) }.disabled(cues.isEmpty)
                            Button("Subtitles (WebVTT)") { prepareExport(kind: .vtt) }.disabled(cues.isEmpty)
                            if cues.isEmpty { Text("No synchronized captions are available. Older sessions keep their text but do not contain audio timing.").font(.caption) }
                            if hasCorrections || edited { Text("Corrections are included. Timing within edited paragraphs is estimated; preview before sharing.").font(.caption) }
                            Text("Pauses are removed from saved audio and subtitles. These files follow this session's recording, not the timeline of an external video.").font(.caption)
                        }.disabled(busy)
                        if audioURL != nil {
                            Section {
                                Button("Delete audio, keep text", role: .destructive) { player.pause(); deleting = true }
                            }.disabled(busy)
                        }
                        if busy { HStack { ProgressView(); Text("Preparing files…") } }
                    }.listStyle(.insetGrouped)
                }
            }
            .padding(.horizontal)
            .navigationTitle("Audio & subtitles").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    if audioURL != nil {
                        Button(fullScreen ? "Exit full screen" : "Full screen", systemImage: fullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
                            captions = true; fullScreen.toggle()
                        }
                    }
                }
            }
            .sheet(isPresented: $editing) {
                TranscriptEditorView(originals: session.orderedCaptions.map { ReviewParagraph(id: $0.id, text: $0.text) },
                                     reviewed: reviewed) { updated in
                    try repository.saveCorrections(updated, for: session)
                    reviewed = updated
                    edited = true
                    try rebuildCues()
                }
            }
            .task { reviewed = paragraphs; load() }
            .onDisappear { player.stop(); exportTask?.cancel(); cleanup() }
            .onChange(of: phase) { _, phase in if phase != .active { player.pause() } }
            .confirmationDialog("Delete the recording permanently? Your text and subtitles will stay.", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete audio", role: .destructive) {
                    player.stop()
                    do { try repository.deleteAudio(for: session.id); audioURL = nil; try rebuildCues() }
                    catch { failure = "Could not delete the recording. Please try again." }
                }
            }
            .sheet(item: $export, onDismiss: { cleanup() }) { item in MediaActivityView(urls: item.urls) }
            .alert("Audio & subtitles", isPresented: Binding(get: { failure != nil || player.failure != nil }, set: { if !$0 { failure = nil; player.failure = nil } })) {
                Button("OK") { failure = nil; player.failure = nil }
            } message: { Text(failure ?? player.failure ?? "") }
        }
    }

    private func load() {
        do {
            if let url = try repository.audioURL(for: session.id), FileManager.default.fileExists(atPath: url.path) {
                audioURL = url; player.load(url)
            }
            try rebuildCues()
        } catch { failure = "Could not open session media. Your transcript is unchanged." }
    }

    private func rebuildCues() throws {
        let times = try repository.media(for: session.id)?.decodedTimings() ?? [:]
        let generated = SubtitleExport.cues(paragraphs: reviewed, timings: times)
        // A failed recording may retain only a prefix. Never display captions past that prefix.
        if audioURL != nil, player.duration > 0 {
            cues = generated.compactMap { cue in
                guard cue.start < player.duration else { return nil }
                return SubtitleCue(id: cue.id, paragraphID: cue.paragraphID, start: cue.start,
                    end: min(cue.end, player.duration), text: cue.text)
            }
        } else { cues = generated }
    }

    private func cleanup() {
        if let folder { try? FileManager.default.removeItem(at: folder) }
        folder = nil
    }

    private enum ExportKind { case audio, bundle, srt, vtt }
    private func prepareExport(kind: ExportKind) {
        guard !busy else { return }
        player.pause(); cleanup(); busy = true
        exportTask = Task { @MainActor in
            defer { busy = false }
            do {
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("VoiceInView-Media-" + UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
                folder = directory
                var urls: [URL] = []
                if kind == .audio || kind == .bundle {
                    guard let audioURL else { throw RecordingFailure.unavailable }
                    let url = directory.appendingPathComponent("Recording.m4a")
                    try await RecordingExport.m4a(from: audioURL, to: url)
                    urls.append(url)
                }
                try Task.checkCancellation()
                if kind == .bundle {
                    let url = directory.appendingPathComponent("Transcript.txt")
                    try TranscriptReview.text(reviewed).write(to: url, atomically: true, encoding: .utf8)
                    urls.append(url)
                }
                let formats: [SubtitleFormat] = kind == .srt ? [.srt] : kind == .vtt ? [.vtt] : kind == .bundle && !cues.isEmpty ? [.srt, .vtt] : []
                for format in formats {
                    let url = directory.appendingPathComponent("Subtitles." + format.rawValue)
                    try SubtitleExport.render(cues, format: format).write(to: url, atomically: true, encoding: .utf8)
                    urls.append(url)
                }
                for url in urls {
                    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path)
                }
                export = MediaShare(urls: urls)
            } catch is CancellationError { cleanup() }
            catch { cleanup(); failure = "Files could not be prepared. Check storage and try again. The saved recording is unchanged." }
        }
    }
}

struct MediaShare: Identifiable { let id = UUID(); let urls: [URL] }
struct MediaActivityView: UIViewControllerRepresentable {
    let urls: [URL]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: urls, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum RecordingExport {
    static func m4a(from source: URL, to destination: URL) async throws {
        guard let exporter = AVAssetExportSession(asset: AVURLAsset(url: source), presetName: AVAssetExportPresetAppleM4A) else {
            throw RecordingFailure.unavailable
        }
        exporter.outputURL = destination
        exporter.outputFileType = .m4a
        await withTaskCancellationHandler {
            await exporter.export()
        } onCancel: { exporter.cancelExport() }
        try Task.checkCancellation()
        guard exporter.status == .completed else { throw exporter.error ?? RecordingFailure.unavailable }
    }
}

private struct PlaybackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
