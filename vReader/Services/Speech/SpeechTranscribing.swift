import Foundation

enum SpeechReadiness: Equatable, Sendable {
    case checking, unsupportedDevice, unsupportedLanguage, missingAssets, downloading, ready
    case problem(String)

    var description: String {
        switch self {
        case .checking: "Checking English speech model"
        case .unsupportedDevice: "This iPhone does not support the on-device speech engine."
        case .unsupportedLanguage: "English (United States) is unavailable on this device."
        case .missingAssets: "Install the English model before using offline captions."
        case .downloading: "Installing the English speech model"
        case .ready: "English model installed"
        case .problem(let message): message
        }
    }
}

enum TranscriptionFailure: LocalizedError, Sendable {
    case notReady, format, overflow, failed, interrupted(String), finalizationTimeout
    var errorDescription: String? {
        switch self {
        case .notReady: "Offline transcription is not ready. Check the English model."
        case .format: "The microphone audio could not be converted for recognition."
        case .overflow: "Audio processing could not keep up. Listening stopped to prevent an incomplete transcript."
        case .failed: "Speech analysis failed. Saved final captions remain available."
        case .interrupted(let message): message
        case .finalizationTimeout: "Speech finalization took too long. The latest unfinished sentence may be incomplete."
        }
    }
}

@MainActor
protocol SpeechTranscribing: AnyObject {
    func readiness() async -> SpeechReadiness
    func installAssets() async throws
    func start() async throws -> AsyncThrowingStream<TranscriptionUpdate, Error>
    func finish() async throws
    func cancel() async
}
