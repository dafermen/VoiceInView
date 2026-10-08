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
    private(set) var preparationPending = false
    private(set) var notice: String?
    var onFinalized: ((FinalizedChange) -> Void)?
    var onEnded: (() -> Void)?
    var onWillStart: (() throws -> Void)?
    var onRunStarted: (() -> Void)?
    var onCheckpoint: ((TimeInterval) -> Void)?
    @ObservationIgnored private let microphone: any AudioCapturing
    @ObservationIgnored private let speech: any SpeechTranscribing
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var consumer: Task<Void, Never>?
    @ObservationIgnored private var foreground = true
    @ObservationIgnored private var activeSince: ContinuousClock.Instant?

    init(microphone: any AudioCapturing, speech: any SpeechTranscribing) {
        self.microphone = microphone
        self.speech = speech
    }

    convenience init() {
        let audio = AudioCaptureService()
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.init(microphone: audio, speech: AppleSpeechTranscriber(audio: audio))
            return
        }
#endif
        self.init(microphone: audio, speech: LegacySpeechTranscriber(audio: audio))
    }

    func requestSpeechPermission() async {
        guard !state.active, !state.busy, !preparationPending else { return }
        preparationPending = true
        defer { preparationPending = false }
        await speech.requestAuthorization()
        await checkReadiness()
    }

    func checkReadiness() async { readiness = await speech.readiness() }

    func installAssets() async {
        guard !state.active, !state.busy, readiness != .downloading else { return }
        readiness = .downloading
        do { try await speech.installAssets(); await checkReadiness() }
        catch { readiness = .problem(error.localizedDescription) }
    }

    func start() async {
        guard foreground, !state.active, !state.busy, !preparationPending, state != .ended else { return }
        preparationPending = true
        defer { preparationPending = false }
        let identifier = UUID()
        generation = identifier
        notice = nil
        state = .preparing
        readiness = await speech.readiness()
        guard generation == identifier, foreground else { return }
        guard !Task.isCancelled else { await abort(message: "Start cancelled."); return }
        guard readiness == .ready else { state = .problem(readiness.description); return }
        if microphone.permission == .undetermined {
            _ = await microphone.requestPermission()
        }
        guard generation == identifier, foreground else { return }
        guard !Task.isCancelled else { await abort(message: "Start cancelled."); return }
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
            activeSince = .now
            state = .listening
            onRunStarted?()
            consumer = Task { @MainActor [weak self] in
                do {
                    for try await update in updates {
                        guard let self, self.generation == identifier, !Task.isCancelled else { return }
                        let change = self.transcript.apply(update)
                        if self.transcript.partial.count > 64 { throw TranscriptionFailure.overflow }
                        if !change.upserted.isEmpty || !change.removedIDs.isEmpty {
                            self.onFinalized?(change)
                        }
                    }
                    guard let self, self.generation == identifier, self.state == .listening else { return }
                    await self.abort(message: "Speech recognition ended unexpectedly. Tap Resume to continue.")
                } catch {
                    guard let self, self.generation == identifier else { return }
                    if self.state == .stopping {
                        self.notice = error.localizedDescription
                        return
                    }
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
            do { try await speech.finish() }
            catch { notice = error.localizedDescription }
            await consumer?.value
        } else {
            state = .stopping
            generation = UUID()
            await speech.cancel()
        }
        generation = UUID()
        consumer?.cancel()
        consumer = nil
        transcript.discardPartial()
        state = .ended
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

    /// Called synchronously by scene changes so a queued cleanup cannot restart or prolong capture.
    func prepareForBackground() -> UUID? {
        foreground = false
        guard state.active else { return nil }
        generation = UUID()
        do { try microphone.stop() } catch { notice = CaptureFailure.sessionFailure.message }
        settleDuration()
        consumer?.cancel()
        consumer = nil
        transcript.discardPartial()
        state = .problem("Listening stopped in the background. Tap Resume to continue. Unfinished captions may be lost.")
        return generation
    }

    func cleanupBackground(_ identifier: UUID) async {
        guard generation == identifier else { return }
        await speech.cancel()
    }

    func background() async {
        if let identifier = prepareForBackground() { await cleanupBackground(identifier) }
    }

    func foregrounded() { foreground = true }

    func reset() async {
        generation = UUID()
        state = .stopping
        consumer?.cancel()
        consumer = nil
        await speech.cancel()
        transcript = TranscriptAssembler()
        startedAt = nil
        elapsed = 0
        activeSince = nil
        notice = nil
        state = .idle
    }

    func currentDuration(at now: Date) -> TimeInterval {
        elapsed + (activeSince.map { SessionClock.seconds($0.duration(to: .now)) } ?? 0)
    }

    private var isProblem: Bool { if case .problem = state { true } else { false } }

    private func settleDuration() {
        if let activeSince { elapsed += SessionClock.seconds(activeSince.duration(to: .now)) }
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
