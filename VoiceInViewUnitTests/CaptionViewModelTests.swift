import XCTest
import SwiftData
@testable import VoiceInView

@MainActor
final class CaptionViewModelTests: XCTestCase {
    func testDraftRequiresExplicitSaveAndPreferencesSurviveNewSession() async throws {
        let name = "FlowTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = AppSettings(defaults: defaults)
        settings.continueInBackground = true
        let repository = try TranscriptRepository(inMemory: true)
        let model = CaptionViewModel(microphone: CaptionMicrophone(), speech: MockSpeech())
        let coordinator = SessionCoordinator(repository: repository, caption: model, settings: settings)
        await model.start()
        let session = try XCTUnwrap(coordinator.currentSession)
        XCTAssertNotNil(try repository.draft(for: session.id))
        await model.stop()
        XCTAssertTrue(coordinator.needsSessionDecision)
        await coordinator.newSession()
        XCTAssertEqual(model.state, .ended, "A pending draft cannot be silently replaced")
        XCTAssertEqual(session.fullTranscript, "Final sentence.")
        settings.saveAudio = true // next session only
        XCTAssertFalse(model.saveAudio)
        XCTAssertTrue(coordinator.saveCurrent(ended: true))
        XCTAssertNil(try repository.draft(for: session.id))
        await coordinator.newSession()
        XCTAssertEqual(model.state, .idle)
        XCTAssertTrue(model.saveAudio)
        XCTAssertTrue(model.continueInBackground)
        XCTAssertEqual(try repository.container.mainContext.fetchCount(FetchDescriptor<ConferenceSession>()), 1)
    }

    func testDiscardRemovesDraftAndKeepsPreviouslySavedSession() async throws {
        let repository = try TranscriptRepository(inMemory: true)
        let previous = try repository.create(title: "Keep me")
        let settingsName = "DiscardTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: settingsName)!
        defer { defaults.removePersistentDomain(forName: settingsName) }
        let model = CaptionViewModel(microphone: CaptionMicrophone(), speech: MockSpeech())
        let coordinator = SessionCoordinator(repository: repository, caption: model, settings: AppSettings(defaults: defaults))
        await model.start()
        await model.stop()
        let id = try XCTUnwrap(coordinator.currentSession?.id)
        await coordinator.discardCurrent()
        XCTAssertNil(coordinator.storageMessage)
        XCTAssertEqual(model.state, .idle)
        XCTAssertFalse(coordinator.needsSessionDecision)
        XCTAssertNil(try repository.draft(for: id))
        let sessions = try repository.container.mainContext.fetch(FetchDescriptor<ConferenceSession>())
        XCTAssertEqual(sessions.map(\.id), [previous.id])
    }

    func testBackgroundListeningRequiresOptInAndNewSessionResetsChoices() async {
        let speech = MockSpeech()
        let model = CaptionViewModel(microphone: CaptionMicrophone(), speech: speech)
        XCTAssertFalse(model.saveAudio)
        XCTAssertFalse(model.continueInBackground)
        await model.start()
        await model.background()
        XCTAssertNotEqual(model.state, .listening)
        await model.reset()
        model.foregrounded()
        model.continueInBackground = true
        await model.start()
        await model.background()
        XCTAssertEqual(model.state, .listening)
        await model.stop()
        await model.reset()
        XCTAssertFalse(model.continueInBackground)
        XCTAssertFalse(model.saveAudio)
    }

    func testMissingModelNeverStartsCaptureOrInstallsImplicitly() async {
        let speech = MockSpeech()
        speech.status = .missingAssets
        let model = CaptionViewModel(microphone: CaptionMicrophone(), speech: speech)
        await model.start()
        XCTAssertEqual(speech.starts, 0)
        XCTAssertEqual(speech.installations, 0)
        XCTAssertEqual(model.readiness, .missingAssets)
    }

    func testStopKeepsFinalResultDeliveredDuringFinalization() async {
        let speech = MockSpeech()
        let model = CaptionViewModel(microphone: CaptionMicrophone(), speech: speech)
        await model.start()
        await model.stop()
        XCTAssertEqual(model.state, .ended)
        XCTAssertEqual(model.transcript.text, "Final sentence.")
    }

    func testPauseResumeUsesIndependentRunsAndRetainsText() async {
        let speech = MockSpeech()
        let model = CaptionViewModel(microphone: CaptionMicrophone(), speech: speech)
        await model.start()
        await model.pause()
        XCTAssertEqual(model.state, .paused)
        await model.start()
        await model.stop()
        XCTAssertEqual(model.transcript.finalized.count, 2)
    }

    func testBackgroundDuringPreparationInvalidatesLateStart() async {
        let speech = MockSpeech()
        speech.delayStart = true
        let model = CaptionViewModel(microphone: CaptionMicrophone(), speech: speech)
        let starting = Task { await model.start() }
        while speech.pendingStart == nil { await Task.yield() }
        await model.background()
        speech.resolveStart()
        await starting.value
        XCTAssertNotEqual(model.state, .listening)
        model.foregrounded()
        XCTAssertNotEqual(model.state, .listening)
        XCTAssertGreaterThan(speech.cancellations, 0)
    }
}

@MainActor
private final class CaptionMicrophone: AudioCapturing {
    var permission: MicrophonePermission = .granted
    var onFailure: (@MainActor @Sendable (CaptureFailure) -> Void)?
    func requestPermission() async -> Bool { true }
    func start() throws -> AsyncStream<Float> { AsyncStream { $0.finish() } }
    func stop() throws {}
}

@MainActor
private final class MockSpeech: SpeechTranscribing {
    var status: SpeechReadiness = .ready
    var starts = 0
    var installations = 0
    var cancellations = 0
    var delayStart = false
    var pendingStart: CheckedContinuation<Void, Never>?
    private var output: AsyncThrowingStream<TranscriptionUpdate, Error>.Continuation?
    private var runID = UUID()

    func readiness() async -> SpeechReadiness { status }
    func installAssets() async throws { installations += 1; status = .ready }
    func start() async throws -> AsyncThrowingStream<TranscriptionUpdate, Error> {
        starts += 1
        if delayStart { await withCheckedContinuation { pendingStart = $0 } }
        runID = UUID()
        let stream = AsyncThrowingStream<TranscriptionUpdate, Error>.makeStream()
        output = stream.continuation
        return stream.stream
    }
    func resolveStart() { pendingStart?.resume(); pendingStart = nil }
    func finish() async throws {
        output?.yield(.init(runID: runID, start: 0, end: 1, text: "Final sentence.", isFinal: true))
        output?.finish()
    }
    func cancel() async { cancellations += 1; output?.finish() }
}
