import SwiftUI
import AVFoundation
#if canImport(Translation)
import Translation
#endif

/// La vista mantiene una sola tarea por intento. Cerrar o cancelar desmonta el runner;
/// el UUID del intento impide que una respuesta tardía guarde datos tras la cancelación.
@MainActor
struct SessionTranslationView: View {
    let session: ConferenceSession
    let repository: TranscriptRepository
    @Environment(\.dismiss) private var dismiss
    @State private var source: [ReviewParagraph] = []
    @State private var snapshot: TranslationSnapshot?
    @State private var mode: TranscriptLanguage = .spanish
    @State private var job: TranslationJob?
    @State private var progress = 0
    @State private var preparing = false
    @State private var exportTask: Task<Void, Never>?
    @State private var loaded = false
    @State private var audioDuration: Double?
    @State private var failure: String?
    @State private var editing = false
    @State private var media = false
    @State private var replacing = false
    @State private var exportMenu = false
    @State private var share: MediaShare?
    @State private var folder: URL?
    @State private var timings: [String: CaptionTiming] = [:]

    private var current: Bool { loaded && snapshot?.isCurrent(source) == true }
    private var displayed: [ReviewParagraph] {
        mode == .english ? source : current ? snapshot?.paragraphs(mode: mode) ?? [] : []
    }
    private var cues: [SubtitleCue] {
        guard let snapshot, current else { return [] }
        let generated = TranslatedSubtitles.cues(snapshot: snapshot, timings: timings, mode: mode)
        guard let audioDuration else { return generated }
        return generated.compactMap { cue in
            guard cue.start < audioDuration else { return nil }
            return SubtitleCue(id: cue.id, paragraphID: cue.paragraphID, start: cue.start,
                end: min(cue.end, audioDuration), text: cue.text)
        }
    }
    private var canTranslate: Bool {
        #if canImport(Translation)
        if #available(iOS 18.0, *) { return true }
        #endif
        return false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Reading language", selection: $mode) {
                    ForEach(TranscriptLanguage.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).padding().accessibilityIdentifier("translationLanguagePicker")
                status.padding(.horizontal)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(Array(displayed.enumerated()), id: \.element.id) { index, paragraph in
                            Text(paragraph.text).font(.title2).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("translatedParagraph-\(index)")
                        }
                    }.padding()
                }
                Divider()
                controls.padding(.horizontal).frame(minHeight: 54)
            }
            .navigationTitle("Translation").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { job = nil; dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if current {
                        Button("Edit Spanish", systemImage: "pencil") { editing = true }
                            .disabled(job != nil || preparing).accessibilityIdentifier("editSpanishButton")
                    }
                }
            }
            .background {
                if let job {
                    TranslationRunner(job: job, progress: { if self.job?.id == job.id { progress = $0 } }) { result in
                        guard self.job?.id == job.id else { return }
                        self.job = nil
                        do {
                            let generated = try result.get()
                            let updated = TranslationSnapshot(source: job.source, generated: generated)
                            try repository.saveTranslation(updated, for: session)
                            snapshot = updated; mode = .spanish
                        } catch is CancellationError { }
                        catch { failure = error.localizedDescription }
                    }.id(job.id)
                }
            }
            .task { load() }
            .sheet(isPresented: $editing) {
                if let snapshot {
                    TranscriptEditorView(originals: snapshot.generated, reviewed: snapshot.spanish,
                                         translation: true) { edited in
                        var updated = snapshot
                        guard edited.map(\.id) == snapshot.generated.map(\.id) else { throw TranslationFailure.incomplete }
                        updated.edits = Dictionary(uniqueKeysWithValues: zip(snapshot.generated, edited).compactMap {
                            $0.text == $1.text ? nil : ($0.id.uuidString, $1.text)
                        })
                        try repository.saveTranslation(updated, for: session)
                        self.snapshot = updated
                    }
                }
            }
            .sheet(isPresented: $media) {
                SessionMediaView(session: session, repository: repository, paragraphs: displayed,
                    hasCorrections: true, translatedCues: cues, translationLanguage: mode.rawValue)
            }
            .sheet(item: $share, onDismiss: cleanup) { item in MediaActivityView(urls: item.urls) }
            .confirmationDialog("Share \(mode.rawValue)", isPresented: $exportMenu, titleVisibility: .visible) {
                Button("Copy text") { UIPasteboard.general.string = TranscriptReview.text(displayed) }
                Button("Text (TXT)") { export(kind: "txt") }
                Button("PDF") { export(kind: "pdf") }
                if !cues.isEmpty {
                    Button("Subtitles (SRT)") { export(kind: "srt") }
                    Button("Subtitles (WebVTT)") { export(kind: "vtt") }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Translate again? This replaces the saved Spanish translation and its edits.",
                                isPresented: $replacing, titleVisibility: .visible) {
                Button("Replace translation", role: .destructive) { start() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Translation", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK") { failure = nil }
            } message: { Text(failure ?? "") }
            .onDisappear { job = nil; exportTask?.cancel(); if share == nil { cleanup() } }
        }
    }

    @ViewBuilder private var status: some View {
        if preparing { ProgressView("Preparing file…") }
        if let job {
            HStack {
                ProgressView(value: Double(progress), total: Double(max(1, job.source.count)))
                Text("\(progress)/\(job.source.count)").font(.caption).monospacedDigit()
                Button("Cancel") { self.job = nil }
            }
            Text("Preparing languages or translating…").font(.caption).foregroundStyle(.secondary)
        } else if snapshot != nil && !current {
            Text("The English text changed. Translate again to update Spanish before reading or sharing it.")
                .font(.callout).foregroundStyle(.secondary).accessibilityIdentifier("translationOutdated")
        } else if !current {
            Text("Translate your saved English transcript into Spanish. English and the original audio are kept.")
                .font(.callout).foregroundStyle(.secondary)
        }
        if !canTranslate {
            Text("Creating translations requires iOS 18 or later and a compatible app build. Saved translations can still be read, edited and exported.")
                .font(.caption).foregroundStyle(.secondary)
        } else if !current && job == nil {
            Text("Apple may ask to download English and Spanish first. Downloaded languages allow on-device translation without internet.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack {
            Button(current ? "Translate again" : "Translate to Spanish", systemImage: "character.bubble") {
                if snapshot != nil { replacing = true } else { start() }
            }.disabled(!canTranslate || !loaded || source.allSatisfy { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } || job != nil || preparing)
                .accessibilityIdentifier("translateSpanishButton")
            Spacer()
            if current {
                Button("Audio & subtitles", systemImage: "captions.bubble") { media = true }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    .disabled(job != nil || preparing).accessibilityIdentifier("translatedMediaButton")
            }
            Button("Share", systemImage: "square.and.arrow.up") { exportMenu = true }
                .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                .disabled(!loaded || displayed.isEmpty || job != nil || preparing)
                .accessibilityIdentifier("shareTranslationButton")

        }.font(.subheadline)
    }

    private func start() {
        guard canTranslate, job == nil else { return }
        progress = 0
        job = TranslationJob(source: source)
    }
    private func load() {
        do {
            source = try repository.reviewedParagraphs(for: session)
            snapshot = try repository.translation(for: session.id)?.decoded()
            timings = try repository.media(for: session.id)?.decodedTimings() ?? [:]
            if let url = try repository.audioURL(for: session.id), FileManager.default.fileExists(atPath: url.path) {
                let audio = try AVAudioFile(forReading: url)
                audioDuration = Double(audio.length) / audio.processingFormat.sampleRate
            }
            loaded = true
        } catch { failure = "Could not load the saved text or translation. Reopen this session before trying again." }
    }
    private func cleanup() {
        if let folder { try? FileManager.default.removeItem(at: folder) }
        folder = nil
    }
    private func export(kind: String) {
        guard !preparing else { return }
        preparing = true
        // Congelar el contenido antes del await evita mezclar idiomas si cambia el selector.
        let text = kind == "srt" || kind == "vtt"
            ? SubtitleExport.render(cues, format: kind == "srt" ? .srt : .vtt)
            : TranscriptReview.text(displayed)
        let filename = TranscriptExport.filename(title: session.title) + "-" + mode.fileSuffix + "." + kind
        exportTask = Task { @MainActor in
            defer { preparing = false }
            do {
                cleanup()
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("VoiceInView-Translation-" + UUID().uuidString)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
                folder = directory
                let data: Data
                if kind == "pdf" {
                    let rendering = Task.detached(priority: .userInitiated) {
                        try TranscriptPDF.render(text: text, emphasizeTitle: false)
                    }
                    data = try await withTaskCancellationHandler(operation: { try await rendering.value },
                        onCancel: { rendering.cancel() })
                } else { data = Data(text.utf8) }
                try Task.checkCancellation()
                let url = directory.appendingPathComponent(filename)
                try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                share = MediaShare(urls: [url])
            } catch is CancellationError { cleanup() }
            catch { cleanup(); failure = "Could not prepare this file. Your saved translation is unchanged." }
        }
    }

}

private struct TranslationJob: Identifiable {
    let id = UUID()
    let source: [ReviewParagraph]
}

@MainActor
private struct TranslationRunner: View {
    let job: TranslationJob
    let progress: (Int) -> Void
    let finish: (Result<[ReviewParagraph], Error>) -> Void
    var body: some View {
        #if canImport(Translation)
        if #available(iOS 18.0, *) {
            AppleTranslationRunner(job: job, progress: progress, finish: finish)
        } else { Color.clear.task { finish(.failure(TranslationFailure.unsupported)) } }
        #else
        Color.clear.task { finish(.failure(TranslationFailure.unsupported)) }
        #endif
    }
}

#if canImport(Translation)
@available(iOS 18.0, *)
@MainActor
private struct AppleTranslationRunner: View {
    let job: TranslationJob
    let progress: (Int) -> Void
    let finish: (Result<[ReviewParagraph], Error>) -> Void
    var body: some View {
        Color.clear.translationTask(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "es")) { @MainActor translator in
            do {
                try await translator.prepareTranslation()
                var translated: [ReviewParagraph] = []
                // Procesar párrafos completos conserva contexto y permite cancelar entre solicitudes.
                for paragraph in job.source {
                    try Task.checkCancellation()
                    let text: String
                    if paragraph.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { text = "" }
                    else { text = try await translator.translate(paragraph.text).targetText }
                    translated.append(ReviewParagraph(id: paragraph.id, text: text))
                    progress(translated.count)
                }
                try Task.checkCancellation()
                finish(.success(translated))
            } catch { finish(.failure(error)) }
        }
    }
}
#endif
