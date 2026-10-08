import XCTest
@testable import vReader

@MainActor
final class CaptionViewModelTests: XCTestCase {
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
