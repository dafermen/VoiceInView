import Foundation
import Observation

enum CaptionState: Equatable {
    case idle, preparing, listening, stopping, paused, ended
    case problem(String)
    var busy: Bool { self == .preparing || self == .stopping }
    var active: Bool { self == .listening || self == .preparing }
}

@MainActor
@Observable
final class CaptionViewModel {
    private(set) var state: CaptionState = .idle
    private(set) var readiness: SpeechReadiness = .checking
    private(set) var transcript = TranscriptAssembler()
    private(set) var startedAt: Date?
    private(set) var elapsed: TimeInterval = 0
    private(set) var permissionDenied = false
    var onFinalized: ((FinalizedChange) -> Void)?
    var onEnded: (() -> Void)?
    var onWillStart: (() throws -> Void)?
    var onCheckpoint: ((TimeInterval) -> Void)?
    @ObservationIgnored private let microphone: any AudioCapturing
    @ObservationIgnored private let speech: any SpeechTranscribing
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var consumer: Task<Void, Never>?
    @ObservationIgnored private var foreground = true
    @ObservationIgnored private var activeSince: Date?

    init(microphone: any AudioCapturing, speech: any SpeechTranscribing) {
        self.microphone = microphone
        self.speech = speech
    }

    convenience init() {
        let audio = AudioCaptureService()
        self.init(microphone: audio, speech: AppleSpeechTranscriber(audio: audio))
    }

    func checkReadiness() async { readiness = await speech.readiness() }

    func installAssets() async {
        guard !state.active, !state.busy, readiness != .downloading else { return }
        readiness = .downloading
        do { try await speech.installAssets(); await checkReadiness() }
        catch { readiness = .problem(error.localizedDescription) }
    }

    func start() async {
        guard foreground, !state.active, !state.busy, state != .ended else { return }
        let identifier = UUID()
        generation = identifier
        state = .preparing
        readiness = await speech.readiness()
        guard generation == identifier, foreground else { return }
        guard readiness == .ready else { state = .problem(readiness.description); return }
        if microphone.permission == .undetermined {
            _ = await microphone.requestPermission()
        }
        guard generation == identifier, foreground, !Task.isCancelled else { return }
        guard microphone.permission == .granted else {
            permissionDenied = true
            state = .problem(CaptureFailure.permissionDenied.message)
            return
        }
        permissionDenied = false
        do {
            if startedAt == nil { try onWillStart?() }
            let updates = try await speech.start()
            guard generation == identifier, foreground else { await speech.cancel(); return }
            if startedAt == nil { startedAt = Date() }
            activeSince = Date()
            state = .listening
            consumer = Task { @MainActor [weak self] in
                do {
                    for try await update in updates {
                        guard let self, self.generation == identifier, !Task.isCancelled else { return }
                        let change = self.transcript.apply(update)
                        if !change.upserted.isEmpty || !change.removedIDs.isEmpty {
                            self.onFinalized?(change)
                        }
                    }
                    guard let self, self.generation == identifier, self.state == .listening else { return }
                    await self.abort(message: "Speech recognition ended unexpectedly. Tap Resume to continue.")
                } catch {
                    guard let self, self.generation == identifier else { return }
                    await self.abort(message: error.localizedDescription)
                }
            }
        } catch {
            guard generation == identifier else { return }
            state = .problem(error.localizedDescription)
        }
    }

    func stop() async {
        guard state.active || state == .paused || isProblem else { return }
        if state == .listening {
            state = .stopping
            settleDuration()
            do { try await speech.finish() } catch { state = .problem(error.localizedDescription) }
            await consumer?.value
        } else {
            generation = UUID()
            await speech.cancel()
        }
        generation = UUID()
        consumer?.cancel()
        consumer = nil
        transcript.discardPartial()
        if !isProblem { state = .ended }
        onEnded?()
    }

    func pause() async {
        guard state == .listening else { return }
        state = .stopping
        settleDuration()
        do {
            try await speech.finish()
            await consumer?.value
            generation = UUID()
            transcript.discardPartial()
            state = .paused
        } catch {
            await abort(message: error.localizedDescription)
        }
    }

    func background() async {
        foreground = false
        if state.active {
            await abort(message: "Listening stopped in the background. Tap Resume to continue.")
        }
    }

    func foregrounded() { foreground = true }

    func reset() async {
        await speech.cancel()
        generation = UUID()
        consumer?.cancel()
        consumer = nil
        transcript = TranscriptAssembler()
        startedAt = nil
        elapsed = 0
        activeSince = nil
        state = .idle
    }

    func currentDuration(at now: Date) -> TimeInterval {
        elapsed + (activeSince.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }

    private var isProblem: Bool { if case .problem = state { true } else { false } }

    private func settleDuration() {
        if let activeSince { elapsed += max(0, Date().timeIntervalSince(activeSince)) }
        activeSince = nil
        onCheckpoint?(elapsed)
    }

    private func abort(message: String) async {
        generation = UUID()
        settleDuration()
        consumer?.cancel()
        consumer = nil
        await speech.cancel()
        transcript.discardPartial()
        state = .problem(message)
    }
}
